//
//  HJUploadFileBasic.m
//  HJNetwork
//
//  Created by navy on 2022/9/7.
//  Copyright © 2022 HJNetwork. All rights reserved.
//

#import "HJUploadFileBasic.h"

@implementation HJUploadFileBasic

#pragma mark - NSSecureCoding

- (void)dealloc {
    //NSLog(@"HJUploadFileBasic_dealloc");
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super init]) {
        self.isSingle = [[coder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(isSingle))] boolValue];
        self.cryptoEnable = [[coder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(cryptoEnable))] boolValue];
        self.size = [[coder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(size))] unsignedLongLongValue];
        self.cryptoSize = [[coder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(cryptoSize))] unsignedLongLongValue];
        self.bufferSize = [[coder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(bufferSize))] unsignedLongLongValue];
        self.MD5 = [coder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(MD5))];
        self.cryptoMD5 = [coder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(cryptoMD5))];
        self.requestUrl = [coder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(requestUrl))];
        self.status = [[coder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(status))] unsignedIntegerValue];
        self.callbackInfo = [coder decodeObjectOfClass:[NSMutableDictionary class] forKey:NSStringFromSelector(@selector(callbackInfo))];
        self.error = [coder decodeObjectOfClass:[NSError class] forKey:NSStringFromSelector(@selector(error))];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:[NSNumber numberWithBool:self.isSingle] forKey:NSStringFromSelector(@selector(isSingle))];
    [coder encodeObject:[NSNumber numberWithBool:self.cryptoEnable] forKey:NSStringFromSelector(@selector(cryptoEnable))];
    [coder encodeObject:[NSNumber numberWithUnsignedLongLong:self.size] forKey:NSStringFromSelector(@selector(size))];
    [coder encodeObject:[NSNumber numberWithUnsignedLongLong:self.cryptoSize] forKey:NSStringFromSelector(@selector(cryptoSize))];
    [coder encodeObject:[NSNumber numberWithUnsignedLongLong:self.bufferSize] forKey:NSStringFromSelector(@selector(bufferSize))];
    [coder encodeObject:self.MD5 forKey:NSStringFromSelector(@selector(MD5))];
    [coder encodeObject:self.cryptoMD5 forKey:NSStringFromSelector(@selector(cryptoMD5))];
    [coder encodeObject:self.requestUrl forKey:NSStringFromSelector(@selector(requestUrl))];
    [coder encodeObject:[NSNumber numberWithUnsignedInteger:self.status] forKey:NSStringFromSelector(@selector(status))];
    [coder encodeObject:self.callbackInfo forKey:NSStringFromSelector(@selector(callbackInfo))];
    [coder encodeObject:self.error forKey:NSStringFromSelector(@selector(error))];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    HJUploadFileBasic *basic = [[self class] allocWithZone:zone];
    basic.isSingle = self.isSingle;
    basic.cryptoEnable = self.cryptoEnable;
    basic.size = self.size;
    basic.cryptoSize = self.cryptoSize;
    basic.bufferSize = self.bufferSize;
    basic.MD5 = self.MD5;
    basic.cryptoMD5 = self.cryptoMD5;
    basic.requestUrl = self.requestUrl;
    basic.status = self.status;
    basic.callbackInfo = self.callbackInfo;
    basic.error = self.error;
    return basic;
}

@end
