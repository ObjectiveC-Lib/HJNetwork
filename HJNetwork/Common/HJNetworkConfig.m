//
//  HJNetworkConfig.m
//  HJNetwork
//
//  Created by navy on 2018/7/5.
//  Copyright © 2018 HJNetwork. All rights reserved.
//

#import "HJNetworkConfig.h"
#import <AFNetworking/AFNetworking.h>
#import "HJNetworkMetrics.h"
#import "HJCredentialChallenge.h"

NSString *const HJRequestCacheErrorDomain = @"com.hj.request.caching";

void HJLog(NSString *consolePrefix, NSString *format, ...) {
#ifdef DEBUG
    NSString *prefix = @"[HJNetwork]";
    if (consolePrefix && consolePrefix.length) {
        prefix = consolePrefix;
    }
    NSString *logFormat = [NSString stringWithFormat:@"%@ : %@", prefix, format];
    va_list argptr;
    va_start(argptr, format);
    NSLogv(logFormat, argptr);
    va_end(argptr);
#endif
}

@implementation HJNetworkConfig {
    NSMutableArray<id<HJUrlFilterProtocol>> *_urlFilters;
}

+ (HJNetworkConfig *)sharedConfig {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] initConfig];
    });
    return sharedInstance;
}

- (instancetype)initConfig {
    self = [self init];
    if (self) {
        _baseUrl = nil;
        _cdnUrl = nil;
        _urlFilters = [NSMutableArray array];
    }
    return self;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _debugLogEnabled = NO;
        _securityPolicy = [AFSecurityPolicy defaultPolicy];
        _sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        _sessionAuthenticationChallengeHandler = ^id _Nullable(NSURLSession * _Nonnull session,
                                                               NSURLSessionTask * _Nonnull task,
                                                               NSURLAuthenticationChallenge * _Nonnull challenge,
                                                               void (^ _Nonnull completionHandler)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable)) {
            NSString *host = task.currentRequest.allHTTPHeaderFields[@"host"];;
            if (!host || [HJCredentialChallenge isIPAddress:host]) {
                host = task.currentRequest.URL.host;
            }
            __block NSURLCredential *credential = nil;
            __block NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
            [HJCredentialChallenge challenge:challenge
                                        host:host
                           completionHandler:^(NSURLSessionAuthChallengeDisposition disp, NSURLCredential * _Nullable cred) {
                disposition = disp;
                credential = cred;
            }];
            if (!credential) {
                if (completionHandler) {
                    completionHandler(disposition, credential);
                }
            }
            return credential;
        };
        _connectionAuthenticationChallengeHandler = ^(NSURLConnection * _Nonnull connection,
                                                      NSURLAuthenticationChallenge * _Nonnull challenge) {
            NSString *host = connection.currentRequest.allHTTPHeaderFields[@"host"];;
            if (!host || [HJCredentialChallenge isIPAddress:host]) {
                host = connection.currentRequest.URL.host;
            }
            __block NSURLCredential *credential = nil;
            __block NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
            [HJCredentialChallenge challenge:challenge
                                        host:host
                           completionHandler:^(NSURLSessionAuthChallengeDisposition disp, NSURLCredential * _Nullable cred) {
                disposition = disp;
                credential = cred;
            }];
            
            if ([challenge previousFailureCount] == 0) {
                if (credential) {
                    [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
                } else {
                    [[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
                }
            } else {
                [[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
            }
        };
        if (@available(iOS 10.0, *)) {
            _collectingMetricsBlock = ^(NSURLSession * _Nonnull session,
                                        NSURLSessionTask * _Nonnull task,
                                        NSURLSessionTaskMetrics * _Nonnull metrics) {
                HJNetworkMetrics *metric = [[HJNetworkMetrics alloc] initWithMetrics:metrics session:session task:task];
                if (_debugLogEnabled) HJLog(nil, @"%@", metric);
            };
        }
    }
    return self;
}

- (void)addUrlFilter:(id<HJUrlFilterProtocol>)filter {
    [_urlFilters addObject:filter];
}

- (void)clearUrlFilter {
    [_urlFilters removeAllObjects];
}

- (NSArray<id<HJUrlFilterProtocol>> *)urlFilters {
    return [_urlFilters copy];
}

#pragma mark - NSObject

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p>{ baseURL: %@ } { cdnURL: %@ }",
            NSStringFromClass([self class]), self,
            self.baseUrl,
            self.cdnUrl];
}

@end
