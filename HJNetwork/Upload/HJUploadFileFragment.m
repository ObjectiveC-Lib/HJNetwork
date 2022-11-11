//
//  HJUploadFileFragment.m
//  HJNetwork
//
//  Created by navy on 2022/9/2.
//  Copyright © 2022 HJNetwork. All rights reserved.
//

#import "HJUploadFileFragment.h"
#import "HJUploadFileBlock.h"
#import "HJFileManager.h"

@interface HJUploadFileFragment ()
@property (nonatomic, strong) NSData *fileData;
@property (nonatomic, strong) NSString *md5;
@end

@implementation HJUploadFileFragment

/// 获取片Data
- (NSData *)fetchData {
    if (_fileData) return _fileData;
    
    NSData *data = nil;
    NSString *absolutePath = self.block.absolutePath;
    if ([[NSFileManager defaultManager] fileExistsAtPath:absolutePath]) {
        NSFileHandle *readHandle = [NSFileHandle fileHandleForReadingAtPath:absolutePath];
        [readHandle seekToFileOffset:self.offset];
        data = [readHandle readDataOfLength:self.size];
        [readHandle closeFile];
    }
    _fileData = data;
    
    return _fileData;
}

- (NSString *)md5 {
    if (_md5) return _md5;
    
    [self fetchData];
    _md5 = HJDataMD5String(_fileData);
    return _md5;
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        self.fragmentId = [coder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(fragmentId))];
        self.index = [[coder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(index))] unsignedIntegerValue];
        self.offset = [[coder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(offset))] unsignedIntegerValue];
        self.block = [coder decodeObjectOfClass:[HJUploadFileBlock class] forKey:NSStringFromSelector(@selector(block))];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:self.fragmentId forKey:NSStringFromSelector(@selector(fragmentId))];
    [coder encodeObject:[NSNumber numberWithUnsignedInteger:self.index] forKey:NSStringFromSelector(@selector(index))];
    [coder encodeObject:[NSNumber numberWithUnsignedInteger:self.offset] forKey:NSStringFromSelector(@selector(offset))];
    [coder encodeObject:self.block forKey:NSStringFromSelector(@selector(block))];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    HJUploadFileFragment *fragment = [super copyWithZone:zone];
    fragment.fragmentId = self.fragmentId;
    fragment.index = self.index;
    fragment.offset = self.offset;
    fragment.block = self.block;
    return fragment;
}

@end
