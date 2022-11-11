//
//  HJHTTPSessionManager.m
//  HJNetwork
//
//  Created by navy on 2022/8/9.
//  Copyright © 2022 HJNetwork. All rights reserved.
//

#import "HJHTTPSessionManager.h"

@interface HJHTTPSessionManager ()
@property (nonatomic, strong) HJNetworkConfig *config;
@end

@implementation HJHTTPSessionManager

+ (instancetype)protocolManager {
    return [[[self class] alloc] initWithBaseURL:nil sessionConfiguration:[HJProtocolManager sharedManager].sessionConfiguration];
}

+ (instancetype)manager:(HJNetworkConfig *)config {
    return [[[self class] alloc] initWithBaseURL:config.baseUrl config:config];
}

- (instancetype)initWithBaseURL:(NSURL *)url config:(HJNetworkConfig *)config {
    self = [super initWithBaseURL:url sessionConfiguration:config.sessionConfiguration];
    if (self) {
        self.config = config;
        self.securityPolicy = self.config.securityPolicy;
        [self setAuthenticationChallengeHandler:self.config.sessionAuthenticationChallengeHandler];
        if (@available(iOS 10, *)) {
            [self setTaskDidFinishCollectingMetricsBlock:self.config.collectingMetricsBlock];
        }
    }
    return self;
}

- (NSURLSessionDataTask *)dataTaskWithHTTPMethod:(NSString *)method
                                       URLString:(NSString *)URLString
                                      parameters:(id)parameters
                                         headers:(nullable NSDictionary <NSString *, NSString *> *)headers
                                  uploadProgress:(nullable void (^)(NSProgress *uploadProgress))uploadProgress
                                downloadProgress:(nullable void (^)(NSProgress *downloadProgress))downloadProgress
                                         success:(nullable void (^)(NSURLSessionDataTask *task, id _Nullable responseObject))success
                                         failure:(nullable void (^)(NSURLSessionDataTask * _Nullable task, NSError *error))failure {
    // DNS
    NSString *urlString = URLString;
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
    
    return [super dataTaskWithHTTPMethod:method
                               URLString:urlString
                              parameters:parameters
                                 headers:headers
                          uploadProgress:uploadProgress
                        downloadProgress:downloadProgress
                                 success:success
                                 failure:failure];
}

- (NSURLSessionDataTask *)POST:(NSString *)URLString
                    parameters:(nullable id)parameters
                       headers:(nullable NSDictionary<NSString *,NSString *> *)headers
     constructingBodyWithBlock:(nullable void (^)(id<AFMultipartFormData> _Nonnull))block
                      progress:(nullable void (^)(NSProgress * _Nonnull))uploadProgress
                       success:(nullable void (^)(NSURLSessionDataTask * _Nonnull, id _Nullable))success
                       failure:(void (^)(NSURLSessionDataTask * _Nullable, NSError * _Nonnull))failure {
    // DNS
    NSString *urlString = URLString;
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
    
    return [super POST:urlString
            parameters:parameters
               headers:headers
              progress:uploadProgress
               success:success
               failure:failure];
}

@end
