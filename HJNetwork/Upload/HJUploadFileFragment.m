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
@property (nonatomic, strong) NSFileHandle *fileHandle;
@end

@implementation HJUploadFileFragment
@synthesize MD5 = _MD5;
@synthesize cryptoMD5 = _cryptoMD5;

- (void)dealloc {
    NSLog(@"HJUploadFileFragment_dealloc");
    if (_fileHandle) {
        if (@available(iOS 13.0, *)) {
            NSError *error = nil;
            [_fileHandle closeAndReturnError:&error];
            if (error) {
                NSLog(@"HJUploadSource_closeFile_error = %@", error);
            }
        } else {
            [_fileHandle closeFile];
        }
        _fileHandle = nil;
    }
}

/// 获取片Data
- (NSData *)fetchData {
    if (!_fileData) {
        _fileData = [self fetchData:self.size offset:0];
        if (!self.isSingle) {
            _MD5 = HJDataMD5String(_fileData);
        }
    }
    return _fileData;
}

- (NSData *)fetchData:(NSUInteger)length offset:(unsigned long long)offset {
    NSData *data = nil;
    if (@available(iOS 13.0, *)) {
        NSError *error = nil;
        [self.fileHandle seekToOffset:self.offset+offset error:&error];
        if (!error) {
            data = [self.fileHandle readDataUpToLength:length error:&error];
        }
        if (error) {
            NSLog(@"HJUploadSource_fetchData_error = %@", error);
            [self.fileHandle closeAndReturnError:&error];
            NSLog(@"HJUploadSource_fetchData_error = %@", error);
        }
    } else {
        [self.fileHandle seekToFileOffset:self.offset+offset];
        data = [self.fileHandle readDataOfLength:length];
    }
    return data;
}

- (NSData *)cryptoData:(NSData *)data {
    return [self.block.config cryptoData:data];
}

- (NSString *)MD5 {
    if (!_MD5) {
        if (self.isSingle) {
            _MD5 = self.block.MD5;
        } else {
            if (self.block.config.formType == HJUploadFormTypeData) {
                [self fetchData];
            } else {
                NSData *data = [self fetchData:self.size offset:0];
                _MD5 = HJDataMD5String(data);
            }
        }
    }
    return _MD5;
}

- (NSFileHandle *)fileHandle {
    if (!_fileHandle) {
        NSString *absolutePath = self.block.absolutePath;
        _fileHandle = [NSFileHandle fileHandleForReadingAtPath:absolutePath];
    }
    return _fileHandle;
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        self.fragmentId = [coder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(fragmentId))];
        self.index = [[coder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(index))] unsignedIntegerValue];
        self.offset = [[coder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(offset))] unsignedLongLongValue];
        self.block = [coder decodeObjectOfClass:[HJUploadFileBlock class] forKey:NSStringFromSelector(@selector(block))];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:self.fragmentId forKey:NSStringFromSelector(@selector(fragmentId))];
    [coder encodeObject:[NSNumber numberWithUnsignedInteger:self.index] forKey:NSStringFromSelector(@selector(index))];
    [coder encodeObject:[NSNumber numberWithUnsignedLongLong:self.offset] forKey:NSStringFromSelector(@selector(offset))];
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
