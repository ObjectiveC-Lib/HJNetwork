//
//  AppDelegate.m
//  HJNetworkDemo
//
//  Created by navy on 2022/5/19.
//

#import "AppDelegate.h"
#import "DMBasicUrlFilter.h"
#import "DMCredentialChallenge.h"
#import "ViewController.h"
#import "DMSDWebImageOperation.h"
#import <SDWebImage/SDWebImage.h>
#import "DMURLProtocol.h"

@interface AppDelegate ()
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(nullable NSDictionary<UIApplicationLaunchOptionsKey,id> *)launchOptions {
    [self setupNetworkConfig];
    [self sdWebImageConfig];
    
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
    config.baseUrl = [DMBasicUrlFilter baseUrl];
    [config addUrlFilter:[DMBasicUrlFilter filterWithArguments:filterArguments]];
    config.jsonResponseContentTypes = @[@"text/html"];
    config.xmlResponseContentTypes = @[@"text/html"];
    config.securityPolicy.validatesDomainName = YES;
    config.securityPolicy.allowInvalidCertificates = NO;
    config.sessionAuthenticationChallengeHandler = ^id _Nullable(NSURLSession * _Nonnull session,
                                                                 NSURLSessionTask * _Nonnull task,
                                                                 NSURLAuthenticationChallenge * _Nonnull challenge,
                                                                 void (^ _Nonnull completionHandler)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable)) {
        NSString *host = task.currentRequest.allHTTPHeaderFields[@"host"];;
        if (!host || [DMCredentialChallenge isIPAddress:host]) {
            host = task.currentRequest.URL.host;
        }
        __block NSURLCredential *credential = nil;
        __block NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
        [DMCredentialChallenge challenge:challenge
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
        if (!host || [DMCredentialChallenge isIPAddress:host]) {
            host = connection.currentRequest.URL.host;
        }
        NSURLCredential *credential = [DMCredentialChallenge challenge:challenge host:host];
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
    config.dnsNodeBlock = ^HJDNSNode * _Nullable(NSString * _Nonnull originalURLString) {
        return nil;
    };
    if (@available(iOS 10.0, *)) {
        config.collectingMetricsBlock = ^(NSURLSession * _Nonnull session,
                                          NSURLSessionTask * _Nonnull task,
                                          NSURLSessionTaskMetrics * _Nonnull metrics) {
            HJNetworkMetrics *metric = [[HJNetworkMetrics alloc] initWithMetrics:metrics session:session task:task];
            if ([HJNetworkConfig sharedConfig].debugLogEnabled) {
                NSLog(@"%@", metric);
            }
        };
    }
    config.debugLogEnabled = YES;
    
    HJProtocolManager *manager = [HJProtocolManager sharedManager];
    manager.sessionConfiguration = [NSURLSessionConfiguration sharedProtocolConfig:[DMURLProtocol class]];
    manager.sessionAuthenticationChallengeHandler = ^id _Nullable(NSURLSession * _Nonnull session,
                                                                  NSURLSessionTask * _Nonnull task,
                                                                  NSURLAuthenticationChallenge * _Nonnull challenge,
                                                                  void (^ _Nonnull completionHandler)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable)) {
        NSString *host = task.currentRequest.allHTTPHeaderFields[@"host"];;
        if (!host || [DMCredentialChallenge isIPAddress:host]) {
            host = task.currentRequest.URL.host;
        }
        NSURLCredential *credential = [DMCredentialChallenge challenge:challenge host:host];
        return credential;
    };
    manager.requestHeaderField = @{ @"Cache-Control":@"no-store" };
    manager.dnsNodeBlock = config.dnsNodeBlock;
    manager.dnsEnabled = YES;
    if (@available(iOS 10.0, *)) {
        manager.collectingMetricsBlock = ^(NSURLSession * _Nonnull session,
                                           NSURLSessionTask * _Nonnull task,
                                           NSURLSessionTaskMetrics * _Nonnull metrics) {
            HJNetworkMetrics *metric = [[HJNetworkMetrics alloc] initWithMetrics:metrics session:session task:task];
            if ([HJProtocolManager sharedManager].debugLogEnabled) {
                NSLog(@"%@", metric);
            }
        };
    }
    manager.debugLogEnabled = YES;
    
    //    [HJProtocolManager registerProtocol:[DMURLProtocol class]];
    //    [HJProtocolManager registerCustomScheme:@"http" selector:nil];
    //    [HJProtocolManager registerCustomScheme:@"https" selector:nil];
}

- (void)sdWebImageConfig {
    SDWebImageDownloaderConfig.defaultDownloaderConfig.sessionConfiguration = [HJProtocolManager sharedManager].sessionConfiguration;
    //    SDWebImageDownloaderConfig.defaultDownloaderConfig.operationClass = [DMImageDownloaderOperation class];
}

@end
