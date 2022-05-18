//
//  AFSessionManager.m
//  HJNetwork
//
//  Created by navy on 2022/8/9.
//

#import "AFSessionManager.h"

#if __has_include(<HJNetwork/HJNetworkPublic.h>)
#import <HJNetwork/HJNetworkPublic.h>>
#elif __has_include("HJNetworkPublic.h")
#import "HJNetworkPublic.h"
#endif

#if __has_include(<HJNetwork/HJProtocol.h>)
#import <HJNetwork/HJProtocol.h>>
#elif __has_include("HJProtocol.h")
#import "HJProtocol.h"
#endif

static HJNetworkConfig *_config = nil;

@implementation AFSessionManager

+ (instancetype)protocolManager {
    return [[[self class] alloc] initWithBaseURL:nil sessionConfiguration:[HJProtocolManager sharedManager].sessionConfiguration];
}

+ (instancetype)manager {
    _config = [HJNetworkConfig sharedConfig];
    return [[[self class] alloc] initWithBaseURL:nil];
}

- (instancetype)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url sessionConfiguration:_config.sessionConfiguration];
    if (self) {
        self.securityPolicy = _config.securityPolicy;
        [self setAuthenticationChallengeHandler:_config.sessionAuthenticationChallengeHandler];
        if (@available(iOS 10, *)) {
            [self setTaskDidFinishCollectingMetricsBlock:_config.collectingMetricsBlock];
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
    if (self.dnsEnabled) {
        HJDNSNode *node = nil;
        if (_config.dnsNodeBlock) {
            node = _config.dnsNodeBlock(urlString);
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
                       success:(nullable void (^)(NSURLSessionDataTask * _Nonnull, id _Nullable))success failure:(void (^)(NSURLSessionDataTask * _Nullable, NSError * _Nonnull))failure {
    // DNS
    NSString *urlString = URLString;
    if (self.dnsEnabled) {
        HJDNSNode *node = nil;
        if (_config.dnsNodeBlock) {
            node = _config.dnsNodeBlock(urlString);
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
    
    return [super POST:urlString
            parameters:parameters
               headers:headers
              progress:uploadProgress
               success:success
               failure:failure];
}

@end
