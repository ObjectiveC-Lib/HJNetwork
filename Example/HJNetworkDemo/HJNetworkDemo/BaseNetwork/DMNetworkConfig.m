//
//  DMNetworkConfig.m
//  HJNetworkDemo
//
//  Created by navy on 2024/9/10.
//

#import "DMNetworkConfig.h"
#import "DMBaseUrlFilter.h"
#import "DMDNSManager.h"

@implementation DMNetworkConfig

+ (instancetype)sharedConfig {
    static id instance = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
#ifdef DEBUG
        self.debugLogEnabled = NO;
#endif
        NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
        NSDictionary *filterArguments = @{ @"appver":appVersion,
                                           @"uid":@"login_uid",
        };
        self.sessionConfiguration.HTTPShouldSetCookies = YES;
        self.baseUrl = [DMBaseUrlFilter baseUrl];
        [self addUrlFilter:[DMBaseUrlFilter filterWithArguments:filterArguments]];
        self.jsonResponseContentTypes = @[@"text/html"];
        self.xmlResponseContentTypes = @[@"text/html"];
        self.securityPolicy.validatesDomainName = YES;
        self.securityPolicy.allowInvalidCertificates = NO;
        self.sessionAuthenticationChallengeHandler = ^id _Nullable(NSURLSession * _Nonnull session,
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
        self.connectionAuthenticationChallengeHandler = ^(NSURLConnection * _Nonnull connection,
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
        self.useDNS = YES;
        self.dnsNodeBlock = ^HJDNSNode * _Nullable(NSString * _Nonnull originalURLString) {
            HJDNSNode *node = [[DMDNSManager sharedManager] resolveURL:[NSURL URLWithString:originalURLString]];
            return node?:nil;
        };
        if (@available(iOS 10.0, *)) {
            self.collectingMetricsBlock = ^(NSURLSession * _Nonnull session,
                                            NSURLSessionTask * _Nonnull task,
                                            NSURLSessionTaskMetrics * _Nonnull metrics) {
                HJNetworkMetrics *metric = [[HJNetworkMetrics alloc] initWithMetrics:metrics session:session task:task];
                if (metric.status_code == 200) {
                    [[DMDNSManager sharedManager] setPositiveUrl:metric.req_url host:metric.req_headers[@"Host"]];
                } else {
                    // NSLog(@"%@", metric);
                    [[DMDNSManager sharedManager] setNegativeUrl:metric.req_url host:metric.req_headers[@"Host"]];
                    // NSLog(@"%@", [DMDNSManager sharedManager]);
                }
            };
        }
    }
    return self;
}

@end
