//
//  AFOperationManager.m
//  HJNetwork
//
//  Created by navy on 2022/8/18.
//

#import "AFOperationManager.h"

#if __has_include(<HJNetwork/HJNetworkPublic.h>)
#import <HJNetwork/HJNetworkPublic.h>>
#elif __has_include("HJNetworkPublic.h")
#import "HJNetworkPublic.h"
#endif

static HJNetworkConfig *_config = nil;

@implementation AFOperationManager

+ (instancetype)manager {
    _config = [HJNetworkConfig sharedConfig];
    return [[[self class] alloc] initWithBaseURL:nil];;
}

- (instancetype)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (self) {
        self.securityPolicy = _config.securityPolicy;
        self.authenticationChallengeHandler = _config.connectionAuthenticationChallengeHandler;
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
    
    return [super POST:urlString parameters:parameters constructingBodyWithBlock:block success:success failure:failure];
}

@end
