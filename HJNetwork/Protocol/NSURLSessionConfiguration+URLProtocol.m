//
//  NSURLSessionConfiguration+URLProtocol.m
//  HJNetwork
//
//  Created by navy on 2022/8/9.
//  Copyright © 2022 HJNetwork. All rights reserved.
//

#import "NSURLSessionConfiguration+URLProtocol.h"

@implementation NSURLSessionConfiguration (URLProtocol)

+ (instancetype)sharedProtocolConfig:(Class)protocol {
    static dispatch_once_t once;
    static NSURLSessionConfiguration *config = nil;
    dispatch_once(&once, ^{
        config = [NSURLSessionConfiguration defaultSessionConfiguration];
        if (protocol) {
            NSMutableArray *protocolClasses = config.protocolClasses.mutableCopy;
            [protocolClasses insertObject:protocol atIndex:0];
            config.protocolClasses = [protocolClasses copy];
        }
    });
    return config;
}

@end
