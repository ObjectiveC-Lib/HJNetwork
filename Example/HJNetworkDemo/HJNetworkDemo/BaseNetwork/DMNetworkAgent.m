//
//  DMNetworkAgent.m
//  HJNetworkDemo
//
//  Created by navy on 2024/9/10.
//

#import "DMNetworkAgent.h"
#import "DMNetworkConfig.h"

@implementation DMNetworkAgent

+ (instancetype)sharedAgent {
    static id instance = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        instance = [[self class] agentWithConfig:[DMNetworkConfig sharedConfig]];
    });
    return instance;
}

@end
