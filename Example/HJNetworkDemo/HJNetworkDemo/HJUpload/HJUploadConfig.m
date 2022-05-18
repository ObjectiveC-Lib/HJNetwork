//
//  HJUploadConfig.m
//  HJNetworkDemo
//
//  Created by navy on 2022/9/5.
//

#import "HJUploadConfig.h"

@implementation HJUploadConfig

- (instancetype)init {
    self = [super init];
    if (self) {
        _fragmentMaxSize = 512*1024;
        _failureRetryCount = 0;
    }
    return self;
}

+ (instancetype)defaultConfig {
    HJUploadConfig *config = [[HJUploadConfig alloc] init];
    return config;
}

@end
