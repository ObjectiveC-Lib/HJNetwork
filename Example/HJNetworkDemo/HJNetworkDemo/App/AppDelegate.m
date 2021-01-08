//
//  AppDelegate.m
//  HJNetworkDemo
//
//  Created by navy on 2020/12/23.
//

#import "AppDelegate.h"
#import "DMNetworkManage.h"
#import "ViewController.h"


@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(nullable NSDictionary<UIApplicationLaunchOptionsKey, id> *)launchOptions NS_AVAILABLE_IOS(6_0) {
    [self setupNetworkConfig];
    
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
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    
    HJNetworkConfig *config = [HJNetworkConfig sharedConfig];
    config.cacheCountLimit = 200;
    config.securityPolicy.validatesDomainName = NO;
    config.securityPolicy.allowInvalidCertificates = YES;
    config.sessionConfiguration.HTTPShouldSetCookies = YES;
    config.debugLogEnabled = YES;
    config.baseUrl = [DMNetworkManage serverHost];
    [config addUrlFilter:[DMNetworkManage urlFilter]];
}

@end
