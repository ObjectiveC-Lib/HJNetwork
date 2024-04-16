//
//  HJRetryRequestConfig.m
//  HJNetwork
//
//  Created by navy on 2023/6/13.
//  Copyright © 2023 HJNetwork. All rights reserved.

#import "HJRetryRequestConfig.h"

@implementation HJRetryRequestConfig

- (instancetype)init {
    self = [super init];
    if (self) {
        _allowBackground = YES;
        _retryEnable = YES;
        _retryCount = 3;
        _retryInterval = 1;
    }
    return self;
}

+ (instancetype)defaultConfig {
    HJRetryRequestConfig *config = [[HJRetryRequestConfig alloc] init];
    return config;
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super init]) {
        self.allowBackground = [[coder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(allowBackground))] boolValue];
        self.retryEnable = [[coder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(retryEnable))] boolValue];
        self.retryCount = [[coder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(retryCount))] unsignedIntegerValue];
        self.retryInterval = [[coder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(retryInterval))] unsignedIntegerValue];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:[NSNumber numberWithBool:self.allowBackground] forKey:NSStringFromSelector(@selector(allowBackground))];
    [coder encodeObject:[NSNumber numberWithBool:self.retryEnable] forKey:NSStringFromSelector(@selector(retryEnable))];
    [coder encodeObject:[NSNumber numberWithUnsignedInteger:self.retryCount] forKey:NSStringFromSelector(@selector(retryCount))];
    [coder encodeObject:[NSNumber numberWithUnsignedInteger:self.retryInterval] forKey:NSStringFromSelector(@selector(retryInterval))];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    HJRetryRequestConfig *config = [[self class] allocWithZone:zone];
    config.allowBackground = self.allowBackground;
    config.retryEnable = self.retryEnable;
    config.retryCount = self.retryCount;
    config.retryInterval = self.retryInterval;
    return config;
}

@end
