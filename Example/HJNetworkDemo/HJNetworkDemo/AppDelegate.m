//
//  AppDelegate.m
//  HJNetworkDemo
//
//  Created by navy on 2022/5/19.
//

#import "AppDelegate.h"
#import "HJCredentialChallenge.h"
#import "ViewController.h"
#import "DMSDWebImageOperation.h"
#import "DMURLProtocol.h"
#import "DMDNSManager.h"
#import <SDWebImage/SDWebImage.h>
#import <SDWebImageWebPCoder/SDWebImageWebPCoder.h>
#import <SDWebImageFLIFCoder/SDWebImageFLIFCoder.h>
#import <SDWebImageSVGKitPlugin/SDWebImageSVGKitPlugin.h>
//#import <SDWebImageSVGCoder/SDWebImageSVGCoder.h>

@interface AppDelegate ()
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(nullable NSDictionary<UIApplicationLaunchOptionsKey,id> *)launchOptions {
    [self setupNetworkConfig];
    [self setupSDWebImageConfig];
    
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
        __block NSURLCredential *credential = nil;
        __block NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
        [HJCredentialChallenge challenge:challenge
                                    host:host
                       completionHandler:^(NSURLSessionAuthChallengeDisposition disp, NSURLCredential * _Nullable cred) {
            disposition = disp;
            credential = cred;
        }];
        return credential;
    };
    manager.requestHeaderField = @{ @"Cache-Control":@"no-store" };
    manager.useDNS = YES;
    manager.dnsNodeBlock = ^HJDNSNode * _Nullable(NSString * _Nonnull originalURLString) {
        HJDNSNode *node = [[DMDNSManager sharedManager] resolveURL:[NSURL URLWithString:originalURLString]];
        return node?:nil;
    };
    if (@available(iOS 10.0, *)) {
        manager.collectingMetricsBlock = ^(NSURLSession * _Nonnull session,
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
    manager.debugLogEnabled = YES;
    
    //    [HJProtocolManager registerProtocol:[DMURLProtocol class]];
    //    [WKWebView registerCustomScheme:@"http"];
    //    [WKWebView registerCustomScheme:@"https"];
}

- (void)setupSDWebImageConfig {
    SDImageCacheConfig.defaultCacheConfig.maxDiskAge = 60 * 60 * 24 * 180; // 180 day
    SDWebImageDownloaderConfig.defaultDownloaderConfig.sessionConfiguration = [HJProtocolManager sharedManager].sessionConfiguration;
    // SDWebImageDownloaderConfig.defaultDownloaderConfig.operationClass = [DMImageDownloaderOperation class];
    
    if (@available(iOS 14, *)) {
        // iOS 14 supports WebP built-in
        [[SDImageCodersManager sharedManager] addCoder:[SDImageAWebPCoder sharedCoder]];
    } else {
        // iOS 13 does not supports WebP, use third-party codec
        [[SDImageCodersManager sharedManager] addCoder:[SDImageWebPCoder sharedCoder]];
    }
    
    if (@available(iOS 13, *)) {
        // For HEIC animated image. Animated image is new introduced in iOS 13, but it contains performance issue for now.
        [[SDImageCodersManager sharedManager] addCoder:[SDImageHEICCoder sharedCoder]];
    }
    
    //    if (@available(iOS 13, *)) {
    //        // The SVG rendering is done using Apple's framework CoreSVG.framework (introduced in iOS 13/macOS 10.15).
    //        [[SDImageCodersManager sharedManager] addCoder:[SDImageSVGCoder sharedCoder]];
    //    } else {
    //        // Which provide the image loading support for SVG using SVGKit SVG engine.
    //        [[SDImageCodersManager sharedManager] addCoder:[SDImageSVGKCoder sharedCoder]];
    //    }
    
    [[SDImageCodersManager sharedManager] addCoder:[SDImageSVGKCoder sharedCoder]];
    
    [[SDImageCodersManager sharedManager] addCoder:[SDImageFLIFCoder sharedCoder]];
}

@end
