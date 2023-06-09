//
//  DMHTTPSessionManager.m
//  HJNetworkDemo
//
//  Created by navy on 2023/6/9.
//

#import "DMHTTPSessionManager.h"

@implementation DMHTTPSessionManager

+ (instancetype)manager {
    return [super manager:[HJNetworkConfig sharedConfig]];
}

- (void)setupDefaultConfig {
    [super setupDefaultConfig];
    NSLog(@"setupDefaultConfig");
}

@end
