//
//  DMDNSManager.m
//  HJNetworkDemo
//
//  Created by navy on 2024/9/9.
//

#import "DMDNSManager.h"

@implementation DMDNSManager

+ (instancetype)sharedManager {
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
        self.debug = YES;
#endif
        self.dnsRemoteUrl = @"";
        NSDictionary *defaultDNSDict = @{
            @"https://map.aaa.com":@[@"https://map.bbb.com", @"https://map0.bbb.com"],
            @"https://map0.bbb.com":@[@"https://map1.bbb.com", @"https://map2.bbb.com", @"https://map3.bbb.com", @"https://map4.bbb.com"],
            @"https://map1.bbb.com":@[@"https://8.8.8.100", @"https://8.8.8.101", @"https://8.8.8.102"],
            @"https://map2.bbb.com":@[@"https://8.8.8.200", @"https://8.8.8.201", @"https://8.8.8.202"],
            @"https://map3.bbb.com":@[@"https://dog11.com", @"https://dog12.com", @"https://dog13.com"],
            @"https://map4.bbb.com":@[@"https://8.8.8.400", @"https://8.8.8.401", @"https://8.8.8.402"],
            @"https://map.bbb.com":@[@"https://dog01.com", @"https://dog02.com", @"https://dog03.com"],
        };
        [self setDefaultDNS:defaultDNSDict];
        self.dnsRemoteDictBlock = ^(NSString * _Nullable dnsRemoteUrl, HJDNSDictBlock  _Nullable dnsDict) {
            NSLog(@"dnsRemoteUrl = %@", dnsRemoteUrl);
            if (dnsDict) {
                dnsDict(@{});
            }
        };
    }
    return self;
}

@end
