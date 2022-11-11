//
//  DMDNSTest.m
//  HJNetworkDemo
//
//  Created by navy on 2022/11/15.
//

#import "DMDNSTest.h"

@implementation DMDNSTest

- (instancetype)init {
    self = [super init];
    if (self) {
    }
    return self;
}

+ (void)setDefaultDNS {
    //    NSMutableDictionary *defaultDNSDict = @{
    //        @"":@[@"", @"", @""],
    //        @"":@[@"", @"", @""],
    //        @"":@[@"", @"", @""],
    //    };
    
    NSMutableDictionary *defaultDNSDict = @{
        @"https://map.aaa.com":@[@"https://map.bbb.com", @"https://map0.bbb.com"],
        @"https://map0.bbb.com":@[@"https://map1.bbb.com", @"https://map2.bbb.com", @"https://map3.bbb.com", @"https://map4.bbb.com"],
        @"https://map1.bbb.com":@[@"https://8.8.8.100", @"https://8.8.8.101", @"https://8.8.8.102"],
        @"https://map2.bbb.com":@[@"https://8.8.8.200", @"https://8.8.8.201", @"https://8.8.8.202"],
        @"https://map3.bbb.com":@[@"https://dog11.com", @"https://dog12.com", @"https://dog13.com"],
        @"https://map4.bbb.com":@[@"https://8.8.8.400", @"https://8.8.8.401", @"https://8.8.8.402"],
        @"https://map.bbb.com":@[@"https://dog01.com", @"https://dog02.com", @"https://dog03.com"],
    }.mutableCopy;
    
    [[HJDNSResolveManager sharedManager] setDefaultDNS:defaultDNSDict];
}

+ (void)resolveURL {
    HJDNSNode *node = [[HJDNSResolveManager sharedManager] resolveURL:[NSURL URLWithString:@"https://map.aaa.com"]];
    NSLog(@"Node : Url = %@, Host = %@", node.url, node.host);
}

+ (void)negative {
    [[HJDNSResolveManager sharedManager] setNegativeUrl:@"https://dog01.com" host:@"map.aaa.com"];
    [[HJDNSResolveManager sharedManager] setNegativeUrl:@"https://dog01.com" host:@"map.aaa.com"];
    [[HJDNSResolveManager sharedManager] setNegativeUrl:@"https://dog01.com" host:@"map.aaa.com"];
//    [[HJDNSResolveManager sharedManager] setNegativeUrl:@"https://8.8.8.100" host:@"map.aaa.com"];
//    [[HJDNSResolveManager sharedManager] setNegativeUrl:@"https://8.8.8.101" host:@"map.aaa.com"];
//    [[HJDNSResolveManager sharedManager] setNegativeUrl:@"https://8.8.8.102" host:@"map.aaa.com"];

    NSLog(@"%@", [HJDNSResolveManager sharedManager]);
}

+ (void)positive {
    [[HJDNSResolveManager sharedManager] setPositiveUrl:@"https://dog01.com" host:@"map.aaa.com"];
    [[HJDNSResolveManager sharedManager] setPositiveUrl:@"https://dog02.com" host:@"map.aaa.com"];
    [[HJDNSResolveManager sharedManager] setPositiveUrl:@"https://dog03.com" host:@"map.aaa.com"];
    [[HJDNSResolveManager sharedManager] setPositiveUrl:@"https://8.8.8.100" host:@"map.aaa.com"];
    
    NSLog(@"%@", [HJDNSResolveManager sharedManager]);
}

@end
