//
//  HJUploadConfig.m
//  HJNetwork
//
//  Created by navy on 2022/9/5.
//  Copyright © 2022 HJNetwork. All rights reserved.
//

#import "HJUploadConfig.h"

@implementation HJUploadConfig

- (instancetype)init {
    self = [super init];
    if (self) {
        _fragmentEnable = NO;
        _fragmentMaxSize = 512*1024;
        _failureRetryCount = 0;
    }
    return self;
}

+ (instancetype)defaultConfig {
    HJUploadConfig *config = [[HJUploadConfig alloc] init];
    return config;
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super init]) {
        self.fragmentEnable = [[coder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(fragmentEnable))] boolValue];
        self.fragmentMaxSize = [[coder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(fragmentMaxSize))] unsignedIntegerValue];
        self.failureRetryCount = [[coder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(failureRetryCount))] unsignedIntegerValue];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:[NSNumber numberWithBool:self.fragmentEnable] forKey:NSStringFromSelector(@selector(fragmentEnable))];
    [coder encodeObject:[NSNumber numberWithUnsignedInteger:self.fragmentMaxSize] forKey:NSStringFromSelector(@selector(fragmentMaxSize))];
    [coder encodeObject:[NSNumber numberWithUnsignedInteger:self.failureRetryCount] forKey:NSStringFromSelector(@selector(failureRetryCount))];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    HJUploadConfig *config = [[self class] allocWithZone:zone];
    config.fragmentEnable = self.fragmentEnable;
    config.fragmentMaxSize = self.fragmentMaxSize;
    config.failureRetryCount = self.failureRetryCount;
    return config;
}

@end
