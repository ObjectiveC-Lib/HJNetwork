//
//  DMDNSTest.m
//  HJNetworkDemo
//
//  Created by navy on 2022/11/15.
//

#import "DMDNSTest.h"
#import "DMDNSManager.h"

@implementation DMDNSTest

- (instancetype)init {
    self = [super init];
    if (self) {
    }
    return self;
}

+ (void)resolveURL {
    HJDNSNode *node = [[DMDNSManager sharedManager] resolveURL:[NSURL URLWithString:@"https://map.aaa.com"]];
    NSLog(@"Node : Url = %@, Host = %@", node.url, node.host);
}

+ (void)negative {
    [[DMDNSManager sharedManager] setNegativeUrl:@"https://dog01.com" host:@"map.aaa.com"];
    [[DMDNSManager sharedManager] setNegativeUrl:@"https://dog01.com" host:@"map.aaa.com"];
    [[DMDNSManager sharedManager] setNegativeUrl:@"https://dog01.com" host:@"map.aaa.com"];
    //    [[DMDNSManager sharedManager] setNegativeUrl:@"https://8.8.8.100" host:@"map.aaa.com"];
    //    [[DMDNSManager sharedManager] setNegativeUrl:@"https://8.8.8.101" host:@"map.aaa.com"];
    //    [[DMDNSManager sharedManager] setNegativeUrl:@"https://8.8.8.102" host:@"map.aaa.com"];
    
    NSLog(@"%@", [DMDNSManager sharedManager]);
}

+ (void)positive {
    [[DMDNSManager sharedManager] setPositiveUrl:@"https://dog01.com" host:@"map.aaa.com"];
    [[DMDNSManager sharedManager] setPositiveUrl:@"https://dog02.com" host:@"map.aaa.com"];
    [[DMDNSManager sharedManager] setPositiveUrl:@"https://dog03.com" host:@"map.aaa.com"];
    [[DMDNSManager sharedManager] setPositiveUrl:@"https://8.8.8.100" host:@"map.aaa.com"];
    
    NSLog(@"%@", [DMDNSManager sharedManager]);
}

@end
