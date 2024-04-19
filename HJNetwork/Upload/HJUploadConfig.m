//
//  HJUploadConfig.m
//  HJNetwork
//
//  Created by navy on 2022/9/5.
//  Copyright © 2022 HJNetwork. All rights reserved.
//

#import "HJUploadConfig.h"
#import <objc/runtime.h>

@implementation HJUploadConfig

- (void)dealloc {
    NSLog(@"HJUploadConfig_dealloc");
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.fragmentEnable = NO;
        self.fragmentSize = 2*1024*1024;
        
        self.retryEnable = NO;
        self.retryCount = 3;
        self.retryInterval = 1;
        
        self.allowBackground = NO;
        self.maxConcurrentCount = -1;
        self.formType = HJUploadFormTypeData;
        
        self.cryptoEnable = NO;
        self.bufferSize = 8*1024;
        
        self.payload = [NSMutableDictionary new];
    }
    return self;
}

+ (instancetype)defaultConfig {
    HJUploadConfig *config = [[HJUploadConfig alloc] init];
    return config;
}

#pragma mark - HJUploadConfig

- (BOOL)fragmentEnable {
    id objc = objc_getAssociatedObject(self, _cmd);
    if (objc) return [objc boolValue];
    
    return NO;
}

- (unsigned long long)fragmentSize {
    if (!self.fragmentEnable) return 0;
    
    id objc = objc_getAssociatedObject(self, _cmd);
    if (objc)  return [objc unsignedLongLongValue];
    
    return 2*1024*1024;
}

- (BOOL)retryEnable {
    id objc = objc_getAssociatedObject(self, _cmd);
    if (objc) return [objc boolValue];
    
    return NO;
}

- (NSUInteger)retryCount {
    if (!self.retryEnable) return 0;
    
    id objc = objc_getAssociatedObject(self, _cmd);
    if (objc)  return [objc unsignedIntegerValue];
    
    return 3;
}

- (NSUInteger)retryInterval {
    if (!self.retryEnable) return 0;
    
    id objc = objc_getAssociatedObject(self, _cmd);
    if (objc)  return [objc unsignedIntegerValue];
    
    return 1;
}

- (BOOL)allowBackground {
    id objc = objc_getAssociatedObject(self, _cmd);
    if (objc) return [objc boolValue];
    
    return NO;
}

- (NSInteger)maxConcurrentCount {
    id objc = objc_getAssociatedObject(self, _cmd);
    if (objc) return [objc integerValue];
    
    return 3;
}

- (HJUploadFormType)formType {
    id objc = objc_getAssociatedObject(self, _cmd);
    if (objc)  return (HJUploadFormType)[objc unsignedIntegerValue];
    
    return HJUploadFormTypeData;
}

- (BOOL)cryptoEnable {
    id objc = objc_getAssociatedObject(self, _cmd);
    if (objc) return [objc boolValue];
    
    return NO;
}

- (unsigned long long)bufferSize {
    id objc = objc_getAssociatedObject(self, _cmd);
    if (objc) return [objc unsignedLongLongValue];
    
    return 8*1024;
}

- (unsigned long long)cryptoDataSize:(unsigned long long)size {
    if (!self.cryptoEnable) return 0;
    
    return size;
}

- (NSData *)cryptoData:(NSData *)data {
    if (!self.cryptoEnable) return nil;
    
    return data;
}

@end

@implementation HJUploadConfig (Extension)

- (void)setFragmentEnable:(BOOL)fragmentEnable {
    objc_setAssociatedObject(self, @selector(fragmentEnable), @(fragmentEnable), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setFragmentSize:(unsigned long long)fragmentSize {
    objc_setAssociatedObject(self, @selector(fragmentSize), @(fragmentSize), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setRetryEnable:(BOOL)retryEnable {
    objc_setAssociatedObject(self, @selector(retryEnable), @(retryEnable), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setRetryCount:(NSUInteger)retryCount {
    objc_setAssociatedObject(self, @selector(retryCount), @(retryCount), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setRetryInterval:(NSUInteger)retryInterval {
    objc_setAssociatedObject(self, @selector(retryInterval), @(retryInterval), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setAllowBackground:(BOOL)allowBackground {
    objc_setAssociatedObject(self, @selector(allowBackground), @(allowBackground), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setMaxConcurrentCount:(NSInteger)maxConcurrentCount {
    objc_setAssociatedObject(self, @selector(maxConcurrentCount), @(maxConcurrentCount), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setFormType:(HJUploadFormType)formType {
    objc_setAssociatedObject(self, @selector(formType), @(formType), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setCryptoEnable:(BOOL)cryptoEnable {
    objc_setAssociatedObject(self, @selector(cryptoEnable), @(cryptoEnable), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setBufferSize:(unsigned long long)bufferSize {
    objc_setAssociatedObject(self, @selector(bufferSize), @(bufferSize), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setPayload:(NSMutableDictionary *)payload {
    objc_setAssociatedObject(self, @selector(payload), payload, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSMutableDictionary *)payload {
    return objc_getAssociatedObject(self, _cmd);;
}

@end
