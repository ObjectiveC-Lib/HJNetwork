//
//  HJUploadFileBlock.m
//  HJNetwork
//
//  Created by navy on 2022/9/2.
//  Copyright © 2022 HJNetwork. All rights reserved.
//

#import "HJUploadFileBlock.h"
#import "HJFileManager.h"
#import "HJUploadSource.h"

@interface HJUploadFileBlock ()
@property (nonatomic, assign) int64_t totalUnitCount;
@property (nonatomic, assign) int64_t completedUnitCount;
@property (nonatomic, assign) int64_t uncompletedUnitCount;
@property (nonatomic, strong) NSProgress *fileProgress;
@property (nonatomic, assign) NSUInteger fragmentCount;
@property (nonatomic, assign) NSUInteger completionCount;
@property (nonatomic, assign) BOOL uploadFragmentFailed;
@property (nonatomic, assign) BOOL sourceCancelTask;
@property (nonatomic, strong) HJUploadConfig *config;
@end

@implementation HJUploadFileBlock

- (void)dealloc {
    [self.fileProgress removeObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted))];
}

- (instancetype)initWithAbsolutePath:(NSString *)path config:(HJUploadConfig *)config {
    self = [super init];
    if (self) {
        _config = config;
        
        _fileProgress = [[NSProgress alloc] initWithParent:nil userInfo:nil];
        _fileProgress.totalUnitCount = NSURLSessionTransferSizeUnknown;
        [_fileProgress addObserver:self
                        forKeyPath:NSStringFromSelector(@selector(fractionCompleted))
                           options:NSKeyValueObservingOptionNew
                           context:NULL];
        _totalUnitCount = 0;
        _completedUnitCount = 0;
        
        [self fetchFileInfo:path];
        [self cutFragments];
    }
    return self;
}

/// 获取文件信息
- (void)fetchFileInfo:(NSString *)absolutePath {
    if (![HJFileManager isExistsAtPath:absolutePath]) {
        NSLog(@"HJUploadFileBlock_文件不存在:%@", absolutePath);
        return;
    }
    
    /// 存取文件路径
    NSURL *url = [NSURL URLWithString:absolutePath];
    if ([absolutePath containsString:[HJFileManager tmpDir]]) {
        self.dirType = HJDirectoryTypeTemporary;
        self.path = [self cutPath:url.path withString:[HJFileManager tmpDir]];
    }
    
    if ([absolutePath containsString:[HJFileManager documentsDir]]) {
        self.dirType = HJDirectoryTypeDocument;
        self.path = [self cutPath:url.path withString:[HJFileManager documentsDir]];
    }
    
    if ([absolutePath containsString:[HJFileManager libraryDir]]) {
        self.dirType = HJDirectoryTypeLibrary;
        self.path = [self cutPath:url.path withString:[HJFileManager libraryDir]];
    }
    
    if ([absolutePath containsString:[HJFileManager cachesDir]]) {
        self.dirType = HJDirectoryTypeCaches;
        self.path = [self cutPath:url.path withString:[HJFileManager cachesDir]];
    }
    
    if ([absolutePath containsString:[HJFileManager mainBundleDir]]) {
        self.dirType = HJDirectoryTypeMainBundle;
        self.path = [self cutPath:url.path withString:[HJFileManager mainBundleDir]];
    }
    
    /// 文件大小
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSDictionary *attr =[fileMgr attributesOfItemAtPath:absolutePath error:nil];
    self.size = attr.fileSize;
    self.totalUnitCount = self.size;
    
    /// 文件名
    self.name = [absolutePath lastPathComponent];
    
    /// 文件类型
    NSString *pathExtension = self.name.pathExtension.lowercaseString;
    NSArray *videoTypes = @[@"mp4", @"mov"];
    if ([videoTypes containsObject:pathExtension]) {
        self.fileType = HJFileTypeVideo;
    }
    
    NSArray *imageTypes = @[@"png", @"jpg", @"gif", @"jpeg", @"webp"];
    if ([imageTypes containsObject:pathExtension]) {
        self.fileType = HJFileTypeImage;
    }
    
    self.blockId = HJFileCreateId(self.path);
}

- (void)cutFragments {
    __weak typeof(self) weakself = self;
    NSUInteger fragmentMaxSize = self.config.fragmentEnable?self.config.fragmentMaxSize:self.size;
    NSUInteger fragmentCount = (self.size%fragmentMaxSize==0)?(self.size/fragmentMaxSize):(self.size/(fragmentMaxSize)+1);
    NSMutableArray<HJUploadFileFragment *> *fragments = [[NSMutableArray alloc] initWithCapacity:fragmentCount];
    for (NSUInteger i = 0; i < fragmentCount; i++) {
        HJUploadFileFragment *fragment = [[HJUploadFileFragment alloc] init];
        fragment.fragmentId = HJFileCreateId([NSString stringWithFormat:@"%@_%lu", self.name, (unsigned long)i]);
        fragment.index = i;
        fragment.offset = i * fragmentMaxSize;
        if (i != fragmentCount - 1) {
            fragment.size = fragmentMaxSize;
        } else {
            fragment.size = self.size - fragment.offset;
        }
        fragment.status = HJUploadStatusWaiting;
        fragment.block = self;
        fragment.progress = ^(NSProgress * _Nullable progress) {
            __strong typeof(weakself) self = weakself;
            if (self.fragments.count == 1) {
                self.completedUnitCount += progress.completedUnitCount;
            }
        };
        __weak typeof(fragment) weakfragment = fragment;
        fragment.completion = ^(HJUploadStatus status, id _Nullable callbackInfo, NSError * _Nullable error) {
            __strong typeof(weakself) self = weakself;
            weakfragment.error = error;
            weakfragment.status = status;
            weakfragment.callbackInfo = callbackInfo;
            if (error || status == HJUploadStatusCancel || status == HJUploadStatusFailure) {
                self.uploadFragmentFailed = YES;
            }
            
            if (self.fragments.count > 1 && status == HJUploadStatusSuccess) {
                // NSLog(@"weakfragment.size = %d", weakfragment.size);
                self.completedUnitCount += weakfragment.size;
            }
            self.completionCount += 1;
        };
        [fragments addObject:fragment];
    }
    
    self.fragments = fragments.copy;
    self.fragmentCount = self.fragments.count;
}

- (void)setCompletionCount:(NSUInteger)completionCount {
    _completionCount = completionCount;
    
    if (_completionCount == self.fragmentCount) {
        self.fragmentCount = 0;
        _completionCount = 0;
        self.uploadFragmentFailed = NO;
        self.sourceCancelTask = NO;
        
        __block HJUploadStatus status = HJUploadStatusSuccess;
        __block NSError *error = nil;
        __block NSMutableDictionary <NSString *, id> * _Nullable callbackInfo = [NSMutableDictionary new];
        __weak typeof(self) weakself = self;
        [self.fragments enumerateObjectsUsingBlock:^(HJUploadFileFragment * _Nonnull fragment, NSUInteger idx, BOOL * _Nonnull stop) {
            if (fragment.callbackInfo) {
                [callbackInfo setObject:fragment.callbackInfo forKey:fragment.fragmentId];
            }
            
            if (fragment.status == HJUploadStatusFailure || fragment.status == HJUploadStatusCancel) {
                if (fragment.status == HJUploadStatusCancel) {
                    status = fragment.status;
                }
                if (status != HJUploadStatusCancel) {
                    status = fragment.status;
                }
                error = HJErrorWithUnderlyingError(fragment.error, error);
                if (fragment.status == HJUploadStatusFailure) {
                    weakself.fragmentCount += 1;
                }
                if (weakself.fragments.count == 1) {
                    weakself.uncompletedUnitCount = weakself.completedUnitCount;
                    weakself.completedUnitCount = 0;
                }
            }
        }];
        self.status = status;
        self.error = error;
        if (callbackInfo.count) self.callbackInfo = callbackInfo;
        
        if (self.error) {
            if (self.completion) {
                self.completion(self.status, self.callbackInfo, self.error);
            }
        } else {
            if (_completedUnitCount >= self.totalUnitCount) {
                self.fileProgress.completedUnitCount = self.totalUnitCount;
                self.fileProgress.totalUnitCount = self.totalUnitCount;
                if (self.completion) {
                    self.completion(self.status, self.callbackInfo, self.error);
                }
            }
        }
    } else if (!self.sourceCancelTask && !self.config.retryEnable && self.uploadFragmentFailed) {
        self.sourceCancelTask = YES;
        [self.source cancelTask];
    }
}

- (void)setCompletedUnitCount:(int64_t)completedUnitCount {
    _completedUnitCount = completedUnitCount;
    
    if (_completedUnitCount >= self.totalUnitCount) {
        if (_completionCount == self.fragmentCount) {
            self.fileProgress.completedUnitCount = self.totalUnitCount;
            self.fileProgress.totalUnitCount = self.totalUnitCount;
        }
    } else {
        if (_completedUnitCount >= self.uncompletedUnitCount) {
            self.uncompletedUnitCount = 0;
            self.fileProgress.completedUnitCount = _completedUnitCount;
            self.fileProgress.totalUnitCount = self.totalUnitCount;
        }
    }
}

- (NSString *)cutPath:(NSString *)path withString:(NSString *)string {
    NSString *tmpPath = [path stringByReplacingOccurrencesOfString:string withString:@""];
    if ([tmpPath hasPrefix:@"/"]) {
        tmpPath = [tmpPath stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@""];
    }
    return tmpPath;
}

- (NSString *)absolutePath {
    NSString *absolutePath = self.path;
    switch (self.dirType) {
        case HJDirectoryTypeDocument:
            absolutePath = [[HJFileManager documentsDir] stringByAppendingPathComponent:self.path];
            break;
        case HJDirectoryTypeLibrary:
            absolutePath = [[HJFileManager libraryDir] stringByAppendingPathComponent:self.path];
            break;
        case HJDirectoryTypeCaches:
            absolutePath = [[HJFileManager cachesDir] stringByAppendingPathComponent:self.path];
            break;
        case HJDirectoryTypeTemporary:
            absolutePath = [[HJFileManager tmpDir] stringByAppendingPathComponent:self.path];
            break;
        case HJDirectoryTypeMainBundle:
            absolutePath = [[HJFileManager mainBundleDir] stringByAppendingPathComponent:self.path];
            break;
        default:
            break;
    }
    
    return absolutePath;
}

#pragma mark - NSProgress Tracking

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if ([object isEqual:self.fileProgress]) {
        if (self.progress) {
            // NSLog(@"block_completedUnitCount: %lld / %lld", [(NSProgress *)object completedUnitCount], [(NSProgress *)object totalUnitCount]);
            self.progress(object);
        }
    }
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        self.blockId = [coder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(blockId))];
        self.name = [coder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(name))];
        self.path = [coder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(path))];
        self.absolutePath = [coder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(absolutePath))];
        self.fileType = [[coder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(fileType))] unsignedIntegerValue];
        self.dirType = [[coder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(dirType))] unsignedIntegerValue];
        self.fragments = [coder decodeObjectOfClass:[NSArray class] forKey:NSStringFromSelector(@selector(fragments))];
        self.source = [coder decodeObjectOfClass:[HJUploadSource class] forKey:NSStringFromSelector(@selector(source))];
        
        self.totalUnitCount = [[coder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(totalUnitCount))] longLongValue];
        self.completedUnitCount = [[coder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(completedUnitCount))] longLongValue];
        self.fileProgress = [coder decodeObjectOfClass:[NSProgress class] forKey:NSStringFromSelector(@selector(fileProgress))];
        self.fragmentCount = [[coder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(fragmentCount))] unsignedIntegerValue];
        self.completionCount = [[coder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(completionCount))] unsignedIntegerValue];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:self.blockId forKey:NSStringFromSelector(@selector(blockId))];
    [coder encodeObject:self.name forKey:NSStringFromSelector(@selector(name))];
    [coder encodeObject:self.path forKey:NSStringFromSelector(@selector(path))];
    [coder encodeObject:self.absolutePath forKey:NSStringFromSelector(@selector(absolutePath))];
    [coder encodeObject:[NSNumber numberWithUnsignedInteger:self.fileType] forKey:NSStringFromSelector(@selector(fileType))];
    [coder encodeObject:[NSNumber numberWithUnsignedInteger:self.dirType] forKey:NSStringFromSelector(@selector(dirType))];
    [coder encodeObject:self.fragments forKey:NSStringFromSelector(@selector(fragments))];
    [coder encodeObject:self.source forKey:NSStringFromSelector(@selector(source))];
    
    [coder encodeObject:[NSNumber numberWithLongLong:self.totalUnitCount] forKey:NSStringFromSelector(@selector(totalUnitCount))];
    [coder encodeObject:[NSNumber numberWithLongLong:self.completedUnitCount] forKey:NSStringFromSelector(@selector(completedUnitCount))];
    [coder encodeObject:self.fileProgress forKey:NSStringFromSelector(@selector(fileProgress))];
    [coder encodeObject:[NSNumber numberWithUnsignedInteger:self.fragmentCount] forKey:NSStringFromSelector(@selector(fragmentCount))];
    [coder encodeObject:[NSNumber numberWithUnsignedInteger:self.completionCount] forKey:NSStringFromSelector(@selector(completionCount))];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    HJUploadFileBlock *block = [super copyWithZone:zone];
    block.blockId = self.blockId;
    block.path = self.path;
    block.absolutePath = self.absolutePath;
    block.fileType = self.fileType;
    block.dirType = self.dirType;
    block.fragments = self.fragments;
    block.source = self.source;
    
    block.totalUnitCount = self.totalUnitCount;
    block.completedUnitCount = self.completedUnitCount;
    block.fileProgress = self.fileProgress;
    block.fragmentCount = self.fragmentCount;
    block.completionCount = self.completionCount;
    return block;
}

@end
