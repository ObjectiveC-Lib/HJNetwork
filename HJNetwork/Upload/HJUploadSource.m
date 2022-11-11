//
//  HJUploadSource.m
//  HJNetwork
//
//  Created by navy on 2022/9/5.
//  Copyright © 2022 HJNetwork. All rights reserved.
//

#import "HJUploadSource.h"
#import "HJUploadSourceManager.h"

@interface HJUploadSource ()
@property (nonatomic, assign) int64_t totalUnitCount;
@property (nonatomic, assign) int64_t completedUnitCount;
@property (nonatomic, strong) NSProgress *fileProgress;
@property (nonatomic, assign) NSUInteger blockCount;
@property (nonatomic, assign) NSUInteger completionCount;
@property (nonatomic, assign) NSUInteger failureRetryCount;
@property (nonatomic,   copy) void (^startBlock)(HJUploadFileFragment *fragment);
@end

@implementation HJUploadSource

- (void)dealloc {
    [self.fileProgress removeObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted))];
    NSLog(@"HJUploadSource_%@: dealloc", self.sourceId);
}

- (instancetype)initWithAbsolutePaths:(NSArray <NSString *>*)paths config:(HJUploadConfig *)config {
    self = [super init];
    if (self) {
        _fileProgress = [[NSProgress alloc] initWithParent:nil userInfo:nil];
        _fileProgress.totalUnitCount = NSURLSessionTransferSizeUnknown;
        [_fileProgress addObserver:self
                        forKeyPath:NSStringFromSelector(@selector(fractionCompleted))
                           options:NSKeyValueObservingOptionNew
                           context:NULL];
        _totalUnitCount = 0;
        _completedUnitCount = 0;
        
        __weak typeof(self) weakself = self;
        NSMutableString *sourceId = [NSMutableString new];
        NSMutableArray *blocks = [NSMutableArray new];
        __block NSUInteger size = 0;
        [paths enumerateObjectsUsingBlock:^(NSString * _Nonnull path, NSUInteger idx, BOOL * _Nonnull stop) {
            HJUploadFileBlock *block = [[HJUploadFileBlock alloc] initWithAbsolutePath:path config:config];
            block.source = self;
            size += block.size;
            block.progress = ^(NSProgress * _Nullable progress) {
                __strong typeof(weakself) self = weakself;
                self.completedUnitCount += progress.completedUnitCount;
            };
            __weak typeof(block) weakblock = block;
            block.completion = ^(HJUploadStatus status, NSDictionary<NSString *,id> * _Nullable callbackInfo, NSError * _Nullable error) {
                __strong typeof(weakself) self = weakself;
                weakblock.error = error;
                weakblock.status = status;
                if (callbackInfo && callbackInfo.count) {
                    weakblock.callbackInfo = callbackInfo.mutableCopy;
                } else {
                    weakblock.callbackInfo = @{}.mutableCopy;
                }
                self.completionCount += 1;
            };
            [blocks addObject:block];
            [sourceId appendString:block.path];
        }];
        _sourceId = HJFileCreateId(sourceId);
        _blocks = [blocks copy];
        
        self.size = size;
        self.totalUnitCount = self.size;
        self.status = HJUploadStatusWaiting;
        self.failureRetryCount = config.failureRetryCount;
        self.blockCount = self.blocks.count;
    }
    return self;
}

- (void)startWithBlock:(void (^)(HJUploadFileFragment * _Nonnull fragment))block {
    [[HJUploadSourceManager sharedManager] addSource:self];
    self.startBlock = block;
    
    [self.blocks enumerateObjectsUsingBlock:^(HJUploadFileBlock * _Nonnull block, NSUInteger idx, BOOL * _Nonnull stop) {
        [block.fragments enumerateObjectsUsingBlock:^(HJUploadFileFragment * _Nonnull fragment, NSUInteger idx, BOOL * _Nonnull stop) {
            fragment.status = HJUploadStatusProcessing;
            if (self.startBlock) {
                self.startBlock(fragment);
            }
        }];
    }];
}

- (void)restart {
    [self.blocks enumerateObjectsUsingBlock:^(HJUploadFileBlock * _Nonnull block, NSUInteger idx, BOOL * _Nonnull stop) {
        block.error = nil;
        [block.fragments enumerateObjectsUsingBlock:^(HJUploadFileFragment * _Nonnull fragment, NSUInteger idx, BOOL * _Nonnull stop) {
            if (fragment.status == HJUploadStatusFailure) {
                fragment.status = HJUploadStatusProcessing;
                fragment.error = nil;
                if (self.startBlock) {
                    self.startBlock(fragment);
                }
            }
        }];
    }];
}

- (void)cancelWithBlock:(void (^)(HJUploadFileFragment * _Nonnull fragment))cancelBlock {
    [self.blocks enumerateObjectsUsingBlock:^(HJUploadFileBlock * _Nonnull block, NSUInteger idx, BOOL * _Nonnull stop) {
        [block.fragments enumerateObjectsUsingBlock:^(HJUploadFileFragment * _Nonnull fragment, NSUInteger idx, BOOL * _Nonnull stop) {
            if (fragment.status == HJUploadStatusProcessing) {
                if (cancelBlock) {
                    cancelBlock(fragment);
                }
            }
        }];
    }];
}

+ (void)cancelWithKey:(HJUploadSourceKey)key block:(void (^)(HJUploadFileFragment * _Nonnull fragment))block {
    HJUploadSource *source = [[HJUploadSourceManager sharedManager] getSource:key];
    if (source) {
        [source cancelWithBlock:block];
    }
}

- (void)setCompletionCount:(NSUInteger)completionCount {
    _completionCount = completionCount;
    
    if (_completionCount == self.blockCount) {
        self.blockCount = 0;
        _completionCount = 0;
        
        __block HJUploadStatus status = HJUploadStatusSuccess;
        __block NSError *error = nil;
        __block NSMutableDictionary <NSString *, id> * _Nullable callbackInfo = [NSMutableDictionary new];
        if (self.callbackInfo && self.callbackInfo.count) {
            [callbackInfo addEntriesFromDictionary:self.callbackInfo];
        }
        [self.blocks enumerateObjectsUsingBlock:^(HJUploadFileBlock * _Nonnull block, NSUInteger idx, BOOL * _Nonnull stop) {
            if (block.callbackInfo && block.callbackInfo.count) {
                [callbackInfo setObject:block.callbackInfo.copy forKey:block.blockId];
            } else {
                [callbackInfo setObject:@{} forKey:block.blockId];
            }
            if (block.status == HJUploadStatusFailure || block.status == HJUploadStatusCancel) {
                status = block.status;;
                error = HJErrorWithUnderlyingError(block.error, error);
                if (block.status == HJUploadStatusFailure) {
                    self.blockCount += 1;
                }
            }
        }];
        self.status = status;
        self.error = error;
        self.callbackInfo = callbackInfo.mutableCopy;
        
        if (self.error) {
            if (self.failureRetryCount > 0 && self.status == HJUploadStatusFailure) {
                [self restart];
                self.failureRetryCount -= 1;
            } else {
                if (self.completion) {
                    self.completion(self.status, self.callbackInfo, self.error);
                }
                [[HJUploadSourceManager sharedManager] removeSource:self];
            }
        } else {
            if (_completedUnitCount >= self.totalUnitCount) {
                self.fileProgress.completedUnitCount = self.totalUnitCount;
                self.fileProgress.totalUnitCount = self.totalUnitCount;
                if (self.completion) {
                    self.completion(self.status, self.callbackInfo, self.error);
                }
                [[HJUploadSourceManager sharedManager] removeSource:self];
            }
        }
    }
}

- (void)setCompletedUnitCount:(int64_t)completedUnitCount {
    _completedUnitCount = completedUnitCount;
    
    if (_completedUnitCount >= self.totalUnitCount) {
        if (_completionCount == self.blockCount) {
            self.fileProgress.completedUnitCount = self.totalUnitCount;
            self.fileProgress.totalUnitCount = self.totalUnitCount;
        }
    } else {
        self.fileProgress.completedUnitCount = _completedUnitCount;
        self.fileProgress.totalUnitCount = self.totalUnitCount;
    }
}

#pragma mark - NSProgress Tracking

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if ([object isEqual:self.fileProgress]) {
        if (self.progress) {
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
        self.sourceId = [coder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(sourceId))];
        self.blocks = [coder decodeObjectOfClass:[NSArray class] forKey:NSStringFromSelector(@selector(blocks))];
        
        self.totalUnitCount = [[coder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(totalUnitCount))] longLongValue];
        self.completedUnitCount = [[coder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(completedUnitCount))] longLongValue];
        self.fileProgress = [coder decodeObjectOfClass:[NSProgress class] forKey:NSStringFromSelector(@selector(fileProgress))];
        self.blockCount = [[coder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(blockCount))] unsignedIntegerValue];
        self.completionCount = [[coder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(completionCount))] unsignedIntegerValue];
        self.failureRetryCount = [[coder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(failureRetryCount))] unsignedIntegerValue];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:self.sourceId forKey:NSStringFromSelector(@selector(sourceId))];
    [coder encodeObject:self.blocks forKey:NSStringFromSelector(@selector(blocks))];
    
    [coder encodeObject:[NSNumber numberWithLongLong:self.totalUnitCount] forKey:NSStringFromSelector(@selector(totalUnitCount))];
    [coder encodeObject:[NSNumber numberWithLongLong:self.completedUnitCount] forKey:NSStringFromSelector(@selector(completedUnitCount))];
    [coder encodeObject:self.fileProgress forKey:NSStringFromSelector(@selector(fileProgress))];
    [coder encodeObject:[NSNumber numberWithUnsignedInteger:self.blockCount] forKey:NSStringFromSelector(@selector(blockCount))];
    [coder encodeObject:[NSNumber numberWithUnsignedInteger:self.completionCount] forKey:NSStringFromSelector(@selector(completionCount))];
    [coder encodeObject:[NSNumber numberWithUnsignedInteger:self.failureRetryCount] forKey:NSStringFromSelector(@selector(failureRetryCount))];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    HJUploadSource *source = [super copyWithZone:zone];
    source.sourceId = self.sourceId;
    source.blocks = self.blocks;
    
    source.totalUnitCount = self.totalUnitCount;
    source.completedUnitCount = self.completedUnitCount;
    source.fileProgress = self.fileProgress;
    source.blockCount = self.blockCount;
    source.completionCount = self.completionCount;
    source.failureRetryCount = self.failureRetryCount;
    return source;
}

@end
