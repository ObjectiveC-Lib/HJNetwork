//
//  AFDownloadOperationManager.m
//  HJNetwork
//
//  Created by navy on 2022/6/20.
//

#import "AFDownloadOperationManager.h"

@interface AFDownloadOperationManager ()
@property (nonatomic, strong) HJNetworkConfig *config;
@end

@implementation AFDownloadOperationManager

+ (instancetype)manager:(HJNetworkConfig *)config {
    return [[[self class] alloc] initWithBaseURL:config.baseUrl config:config];;
}

- (instancetype)initWithBaseURL:(NSURL *)url config:(HJNetworkConfig *)config {
    self = [super initWithBaseURL:url];
    if (self) {
        self.config = config;
        self.securityPolicy = self.config.securityPolicy;
        self.authenticationChallengeHandler = self.config.connectionAuthenticationChallengeHandler;
    }
    return self;
}

- (nullable AFDownloadOperation *)Download:(NSString *)URLString
                                parameters:(id)parameters
                            fileIdentifier:(NSString *)fileIdentifier
                                targetPath:(NSString *)targetPath
                              shouldResume:(BOOL)shouldResume
                                   success:(void (^)(AFHTTPRequestOperation *operation, id __nullable responseObject))success
                                   failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    NSString *urlString = [[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString];
    // DNS
    if (self.config.useDNS) {
        HJDNSNode *node = nil;
        if (self.config.dnsNodeBlock) {
            node = self.config.dnsNodeBlock(urlString);
        }
        if (node) {
            if (node.realUrl != nil && [node.realUrl length] > 0) {
                urlString = node.realUrl;
            }
            if (node.realHost != nil && [node.realHost length] > 0) {
                [self.requestSerializer setValue:node.realHost forHTTPHeaderField:@"host"];
            }
        }
    }
    
    NSError *serializationError = nil;
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"GET"
                                                                   URLString:urlString
                                                                  parameters:parameters
                                                                       error:&serializationError];
    if (serializationError) {
        if (failure) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgnu"
            dispatch_async(self.completionQueue ?: dispatch_get_main_queue(), ^{
                failure(nil, serializationError);
            });
#pragma clang diagnostic pop
        }
        
        return nil;
    }
    
    AFDownloadOperation *operation = [[AFDownloadOperation alloc] initWithRequest:request
                                                                   fileIdentifier:fileIdentifier
                                                                       targetPath:targetPath
                                                                     shouldResume:shouldResume];
    operation.responseSerializer = self.responseSerializer;
    operation.shouldUseCredentialStorage = self.shouldUseCredentialStorage;
    operation.credential = self.credential;
    operation.securityPolicy = self.securityPolicy;
    
    [operation setWillSendRequestForAuthenticationChallengeBlock:self.authenticationChallengeHandler];
    [operation setCompletionBlockWithSuccess:success failure:failure];
    operation.completionQueue = self.completionQueue;
    operation.completionGroup = self.completionGroup;
    
    [self.operationQueue addOperation:operation];
    
    return operation;
}

@end
