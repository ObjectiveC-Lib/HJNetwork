//
//  AppDelegate.m
//  HJNetworkDemo
//
//  Created by navy on 2022/5/19.
//

#import "AppDelegate.h"
#import "DMBaseUrlFilter.h"
#import "HJCredentialChallenge.h"
#import "ViewController.h"
#import "DMSDWebImageOperation.h"
#import <SDWebImage/SDWebImage.h>
#import "DMURLProtocol.h"
#import "DMDNSTest.h"

@interface AppDelegate ()
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(nullable NSDictionary<UIApplicationLaunchOptionsKey,id> *)launchOptions {
    [self setupNetworkConfig];
    [self setupSDWebImageConfig];
    [DMDNSTest setDefaultDNS];
    
    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [self.window setBackgroundColor:[UIColor whiteColor]];
    
    ViewController *vc = [[ViewController alloc] init];
    vc.view.backgroundColor = [UIColor clearColor];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [self.window setRootViewController:nav];
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (void)setupNetworkConfig {
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSDictionary *filterArguments = @{ @"appver":appVersion,
                                       @"uid":@"login_uid",
    };
    
    HJNetworkConfig *config = [HJNetworkConfig sharedConfig];
    config.sessionConfiguration.HTTPShouldSetCookies = YES;
    config.baseUrl = [DMBaseUrlFilter baseUrl];
    [config addUrlFilter:[DMBaseUrlFilter filterWithArguments:filterArguments]];
    config.jsonResponseContentTypes = @[@"text/html"];
    config.xmlResponseContentTypes = @[@"text/html"];
    config.securityPolicy.validatesDomainName = YES;
    config.securityPolicy.allowInvalidCertificates = NO;
    config.sessionAuthenticationChallengeHandler = ^id _Nullable(NSURLSession * _Nonnull session,
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
    config.connectionAuthenticationChallengeHandler = ^(NSURLConnection * _Nonnull connection,
                                                        NSURLAuthenticationChallenge * _Nonnull challenge) {
        NSString *host = connection.currentRequest.allHTTPHeaderFields[@"host"];;
        if (!host || [HJCredentialChallenge isIPAddress:host]) {
            host = connection.currentRequest.URL.host;
        }
        NSURLCredential *credential = [HJCredentialChallenge challenge:challenge host:host];
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
    config.useDNS = YES;
    config.dnsNodeBlock = ^HJDNSNode * _Nullable(NSString * _Nonnull originalURLString) {
        HJDNSNode *node = [[HJDNSResolveManager sharedManager] resolveURL:[NSURL URLWithString:originalURLString]];
        return node?:nil;
    };
    if (@available(iOS 10.0, *)) {
        config.collectingMetricsBlock = ^(NSURLSession * _Nonnull session,
                                          NSURLSessionTask * _Nonnull task,
                                          NSURLSessionTaskMetrics * _Nonnull metrics) {
            HJNetworkMetrics *metric = [[HJNetworkMetrics alloc] initWithMetrics:metrics session:session task:task];
            if (metric.status_code == 200) {
                [[HJDNSResolveManager sharedManager] setPositiveUrl:metric.req_url host:metric.req_headers[@"Host"]];
            } else {
//                                NSLog(@"%@", metric);
                [[HJDNSResolveManager sharedManager] setNegativeUrl:metric.req_url host:metric.req_headers[@"Host"]];
                //                NSLog(@"%@", [HJDNSResolveManager sharedManager]);
            }
        };
    }
    config.debugLogEnabled = NO;
    
    HJProtocolManager *manager = [HJProtocolManager sharedManager];
    manager.sessionConfiguration = [NSURLSessionConfiguration sharedProtocolConfig:[DMURLProtocol class]];
    manager.sessionAuthenticationChallengeHandler = ^id _Nullable(NSURLSession * _Nonnull session,
                                                                  NSURLSessionTask * _Nonnull task,
                                                                  NSURLAuthenticationChallenge * _Nonnull challenge,
                                                                  void (^ _Nonnull completionHandler)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable)) {
        NSString *host = task.currentRequest.allHTTPHeaderFields[@"host"];;
        if (!host || [HJCredentialChallenge isIPAddress:host]) {
            host = task.currentRequest.URL.host;
        }
        NSURLCredential *credential = [HJCredentialChallenge challenge:challenge host:host];
        return credential;
    };
    manager.requestHeaderField = @{ @"Cache-Control":@"no-store" };
    manager.useDNS = config.useDNS;
    manager.dnsNodeBlock = config.dnsNodeBlock;
    if (@available(iOS 10.0, *)) {
        manager.collectingMetricsBlock = config.collectingMetricsBlock;
    }
    manager.debugLogEnabled = config.debugLogEnabled;
    
    //    [HJProtocolManager registerProtocol:[DMURLProtocol class]];
    //    [WKWebView registerCustomScheme:@"http"];
    //    [WKWebView registerCustomScheme:@"https"];
}

- (void)setupSDWebImageConfig {
    SDWebImageDownloaderConfig.defaultDownloaderConfig.sessionConfiguration = [HJProtocolManager sharedManager].sessionConfiguration;
    //    SDWebImageDownloaderConfig.defaultDownloaderConfig.operationClass = [DMImageDownloaderOperation class];
}

@end
