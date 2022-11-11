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

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super init]) {
        self.size = [[coder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(size))] unsignedIntegerValue];
        self.status = [[coder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(status))] unsignedIntegerValue];
        self.callbackInfo = [coder decodeObjectOfClass:[NSMutableDictionary class] forKey:NSStringFromSelector(@selector(callbackInfo))];
        self.error = [coder decodeObjectOfClass:[NSError class] forKey:NSStringFromSelector(@selector(error))];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:[NSNumber numberWithUnsignedInteger:self.size] forKey:NSStringFromSelector(@selector(size))];
    [coder encodeObject:[NSNumber numberWithUnsignedInteger:self.status] forKey:NSStringFromSelector(@selector(status))];
    [coder encodeObject:self.callbackInfo forKey:NSStringFromSelector(@selector(callbackInfo))];
    [coder encodeObject:self.error forKey:NSStringFromSelector(@selector(error))];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    HJUploadFileBasic *basic = [[self class] allocWithZone:zone];
    basic.size = self.size;
    basic.status = self.status;
    basic.callbackInfo = self.callbackInfo;
    basic.error = self.error;
    return basic;
}

@end
