//
//  HJUploadCustomConfig.m
//  HJNetworkDemo
//
//  Created by navy on 2024/4/9.
//

#import "HJUploadCustomConfig.h"

@implementation HJUploadCustomConfig

- (instancetype)init {
    self = [super init];
    if (self) {
        self.fragmentEnable = YES;
        self.fragmentSize = 1*1024*1024;
        
        self.retryEnable = YES;
        self.allowBackground = YES;
        self.maxConcurrentCount = 3;
        self.formType = HJUploadFormTypeStream;
    }
    return self;
}

+ (instancetype)defaultConfig {
    HJUploadCustomConfig *config = [[HJUploadCustomConfig alloc] init];
    return config;
}

- (unsigned long long)cryptoDataSize:(unsigned long long)size {
    if (size <= 0) return 0;
    if (!self.cryptoEnable) return size;
    
    NSUInteger bufferCount = 0;
    if ((size % self.bufferSize) == 0) {
        bufferCount = size / self.bufferSize;
    } else {
        bufferCount = (size / self.bufferSize) + 1;
    }
    
    long long cryptoSize = size + bufferCount * HJCryptoBufferExtendSize;
    return cryptoSize;
}

- (NSData *)cryptoData:(NSData *)data {
    if (!data) return data;
    if (!self.cryptoEnable) return data;
    
    return data;
}

@end
