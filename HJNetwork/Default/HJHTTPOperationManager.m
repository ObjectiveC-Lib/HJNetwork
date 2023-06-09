//
//  HJHTTPOperationManager.m
//  HJNetwork
//
//  Created by navy on 2022/8/18.
//  Copyright © 2022 HJNetwork. All rights reserved.
//

#import "HJHTTPOperationManager.h"

@interface HJHTTPOperationManager ()
@property (nonatomic, strong) HJNetworkConfig *config;
@end

@implementation HJHTTPOperationManager

+ (instancetype)manager:(HJNetworkConfig *)config {
    return [[[self class] alloc] initWithBaseURL:[NSURL URLWithString:config.baseUrl] config:config];;
}

- (instancetype)initWithBaseURL:(NSURL *)url config:(HJNetworkConfig *)config {
    self = [super initWithBaseURL:url];
    if (self) {
        self.config = config;
        self.securityPolicy = self.config.securityPolicy;
        self.authenticationChallengeHandler = self.config.connectionAuthenticationChallengeHandler;
        [self setupDefaultConfig];
    }
    return self;
}

- (void)setupDefaultConfig {
    self.requestSerializer.allowsCellularAccess = YES;
    self.requestSerializer.cachePolicy = NSURLRequestUseProtocolCachePolicy;
    self.requestSerializer.HTTPShouldHandleCookies = YES;
    self.requestSerializer.timeoutInterval = 60;
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
            if (node.url != nil && [node.url length] > 0) {
                urlString = node.url;
            }
            if (node.host != nil && [node.host length] > 0) {
                [self.requestSerializer setValue:node.host forHTTPHeaderField:@"host"];
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
            if (node.url != nil && [node.url length] > 0) {
                urlString = node.url;
            }
            if (node.host != nil && [node.host length] > 0) {
                [self.requestSerializer setValue:node.host forHTTPHeaderField:@"host"];
            }
        }
    }
    
    return [super POST:urlString parameters:parameters constructingBodyWithBlock:block success:success failure:failure];
}

@end
