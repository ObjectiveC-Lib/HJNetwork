//
//  AFOperationManager.m
//  HJNetwork
//
//  Created by navy on 2022/8/18.
//

#import "AFOperationManager.h"

@interface AFOperationManager ()
@property (nonatomic, strong) HJNetworkConfig *config;
@end

@implementation AFOperationManager

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

- (AFHTTPRequestOperation *)HTTPRequestOperationWithHTTPMethod:(NSString *)method
                                                     URLString:(NSString *)URLString
                                                    parameters:(id)parameters
                                                       success:(void (^)(AFHTTPRequestOperation *operation, id __nullable responseObject))success
                                                       failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    NSString *urlString = URLString;
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
    
    return [super HTTPRequestOperationWithHTTPMethod:method
                                           URLString:urlString
                                          parameters:parameters
                                             success:success
                                             failure:failure];
}

- (AFHTTPRequestOperation *)POST:(NSString *)URLString
                      parameters:(id)parameters
       constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block
                         success:(void (^)(AFHTTPRequestOperation *operation, id __nullable responseObject))success
                         failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    NSString *urlString = URLString;
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
    
    return [super POST:urlString parameters:parameters constructingBodyWithBlock:block success:success failure:failure];
}

@end
