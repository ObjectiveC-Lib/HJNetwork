//
//  HJUploadFileSource.m
//  HJNetwork
//
//  Created by navy on 2022/9/5.
//  Copyright © 2022 HJNetwork. All rights reserved.
//

#import "HJUploadFileSource.h"
#import <pthread/pthread.h>

#define Lock() pthread_mutex_lock(&_lock)
#define Unlock() pthread_mutex_unlock(&_lock)

@interface HJUploadSourceManager : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

+ (instancetype)sharedManager;

- (void)addSource:(HJUploadFileSource *)source;
- (void)removeSource:(HJUploadFileSource *)source;
- (nullable HJUploadFileSource *)getSource:(NSString *)sourceId;

@end

@implementation HJUploadSourceManager {
    pthread_mutex_t _lock;
    NSMutableDictionary *_sources;
}

- (void)dealloc {
    pthread_mutex_destroy(&_lock);
}

+ (instancetype)sharedManager {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        pthread_mutex_init(&_lock, NULL);
        _sources = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)addSource:(HJUploadFileSource *)source {
    if (!source) return;
    Lock();
    [_sources setObject:source forKey:source.sourceId];
    Unlock();
}

- (void)removeSource:(HJUploadFileSource *)source {
    if (!source) return;
    Lock();
    [_sources removeObjectForKey:source.sourceId];
    Unlock();
}

- (HJUploadFileSource *)getSource:(NSString *)sourceId {
    if (!sourceId || sourceId.length <= 0) return nil;
    HJUploadFileSource *source = nil;
    Lock();
    if (_sources.count) {
        source = [_sources objectForKey:sourceId];
    }
    Unlock();
    return source;
}

@end

@interface HJUploadFileSource ()
@property (nonatomic, assign) int64_t totalUnitCount;
@property (nonatomic, assign) int64_t completedUnitCount;
@property (nonatomic, strong) NSProgress *fileProgress;
@property (nonatomic, assign) NSUInteger blockCount;
@property (nonatomic, assign) NSUInteger completionCount;
@property (nonatomic, assign) NSUInteger retryCount;
@property (nonatomic, strong) NSMutableDictionary <NSString *, id> *requestDict;
//@property (nonatomic,   copy) void (^startBlock)(HJUploadFileFragment *fragment);
@end

@implementation HJUploadFileSource {
    pthread_mutex_t _lock;
}

- (void)dealloc {
    NSLog(@"HJUploadSource_dealloc_%@: dealloc", self.sourceId);
    
    [self.fileProgress removeObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted))];
    pthread_mutex_destroy(&_lock);
}

- (instancetype)initWithFilePaths:(NSArray <NSString *>*)paths urls:(NSArray <NSString *>*)urls config:(id <HJUploadConfig>)config {
    self = [super init];
    if (self) {
        pthread_mutex_init(&_lock, NULL);
        _config = config;
        _fileProgress = [[NSProgress alloc] initWithParent:nil userInfo:nil];
        _fileProgress.totalUnitCount = NSURLSessionTransferSizeUnknown;
        [_fileProgress addObserver:self
                        forKeyPath:NSStringFromSelector(@selector(fractionCompleted))
                           options:NSKeyValueObservingOptionNew
                           context:NULL];
        _totalUnitCount = 0;
        _completedUnitCount = 0;
        _requestDict = [NSMutableDictionary new];
        
        __weak typeof(self) weakSelf = self;
        NSMutableString *sourceId = [NSMutableString new];
        NSMutableArray *blocks = [NSMutableArray new];
        __block NSUInteger size = 0;
        __block NSUInteger cryptoSize = 0;
        [paths enumerateObjectsUsingBlock:^(NSString * _Nonnull path, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *url = nil;
            if (urls && urls.count) url = urls[idx];
            HJUploadFileBlock *block = [[HJUploadFileBlock alloc] initWithFilePath:path url:url config:config];
            block.source = self;
            size += block.size;
            cryptoSize += block.cryptoSize;
            block.progress = ^(NSProgress * _Nullable progress) {
                __strong typeof(weakSelf) self = weakSelf;
                if (self.blocks.count > 1) {
                    self.completedUnitCount += progress.completedUnitCount;
                } else {
                    self.completedUnitCount = progress.completedUnitCount;
                }
                // NSLog(@"block_completedUnitCount: %lld / %lld", progress.completedUnitCount, progress.totalUnitCount);
            };
            __weak typeof(block) weakBlock = block;
            block.completion = ^(HJUploadStatus status, HJUploadKey key, id _Nullable callbackInfo, NSError * _Nullable error) {
                __strong typeof(weakSelf) self = weakSelf;
                weakBlock.error = error;
                weakBlock.status = status;
                weakBlock.callbackInfo = callbackInfo;
                self.completionCount += 1;
            };
            [blocks addObject:block];
            [sourceId appendString:block.path];
        }];
        _sourceId = HJFileCreateId(sourceId);
        _blocks = [blocks copy];
        
        self.size = size;
        self.cryptoSize = cryptoSize;
        self.retryCount = self.config.retryCount;
        self.bufferSize = self.config.bufferSize;
        self.cryptoEnable = self.config.cryptoEnable;
        self.totalUnitCount = self.cryptoEnable?self.cryptoSize:self.size;
        self.status = HJUploadStatusWaiting;
        self.blockCount = self.blocks.count;
        self.taskKey = self.sourceId;
        self.taskAllowBackground = self.config.allowBackground;
        self.taskMaxConcurrentCount = self.config.maxConcurrentCount;
    }
    return self;
}

- (void)reStartRequest {
    __weak typeof(self) weakSelf = self;
    [self.blocks enumerateObjectsUsingBlock:^(HJUploadFileBlock * _Nonnull block, NSUInteger idx, BOOL * _Nonnull stop) {
        block.error = nil;
        [block.fragments enumerateObjectsUsingBlock:^(HJUploadFileFragment * _Nonnull fragment, NSUInteger idx, BOOL * _Nonnull stop) {
            if (fragment.status == HJUploadStatusFailure) {
                fragment.status = HJUploadStatusProcessing;
                fragment.error = nil;
                if (weakSelf.request) {
                    HJCoreRequest *request = weakSelf.request(fragment);
                    Lock();
                    [weakSelf.requestDict setObject:request forKey:fragment.fragmentId];
                    Unlock();
                    request.uploadProgressBlock = ^(NSProgress *progress) {
                        fragment.status = HJUploadStatusProcessing;
                        // NSLog(@"reStartRequest_fragment_completedUnitCount: %lld / %lld", progress.completedUnitCount, progress.totalUnitCount);
                        if (fragment.progress) {
                            fragment.progress(progress);
                        }
                    };
                    [request startWithCompletionBlockWithSuccess:^(__kindof HJCoreRequest * _Nonnull request) {
                        fragment.status = HJUploadStatusSuccess;
                        if (fragment.completion) {
                            fragment.completion(HJUploadStatusSuccess, weakSelf.sourceId, request.responseObject, nil);
                        }
                        Lock();
                        [weakSelf.requestDict removeObjectForKey:fragment.fragmentId];
                        Unlock();
                    } failure:^(__kindof HJCoreRequest * _Nonnull request) {
                        fragment.status = HJUploadStatusFailure;
                        NSString *errorDesc = request.error.localizedDescription;
                        if ((errorDesc && [errorDesc isEqualToString:@"cancelled"]) || weakSelf.status == HJUploadStatusCancel) {
                            fragment.status = HJUploadStatusCancel;
                        }
                        if (fragment.completion) {
                            fragment.completion(fragment.status, weakSelf.sourceId, request.responseObject, request.error);
                        }
                        Lock();
                        [weakSelf.requestDict removeObjectForKey:fragment.fragmentId];
                        Unlock();
                    }];
                }
            }
        }];
    }];
}

- (void)startRequest {
    __weak typeof(self) weakSelf = self;
    [self.blocks enumerateObjectsUsingBlock:^(HJUploadFileBlock * _Nonnull block, NSUInteger idx, BOOL * _Nonnull stop) {
        if (weakSelf.preprocess) {
            NSDictionary *callbackInfo = weakSelf.preprocess(block);
            if (block.error) {
                if (block.completion) {
                    block.completion(HJUploadStatusFailure, weakSelf.sourceId, callbackInfo, block.error);
                }
                *stop = YES;
                return;
            }
        }
        block.error = nil;
        [block.fragments enumerateObjectsUsingBlock:^(HJUploadFileFragment * _Nonnull fragment, NSUInteger idx, BOOL * _Nonnull stop) {
            if (fragment.status == HJUploadStatusSuccess) {
                if (fragment.completion) {
                    fragment.completion(fragment.status, weakSelf.sourceId, nil, nil);
                }
            } else {
                fragment.status = HJUploadStatusProcessing;
                if (weakSelf.request) {
                    HJCoreRequest *request = weakSelf.request(fragment);
                    Lock();
                    [weakSelf.requestDict setObject:request forKey:fragment.fragmentId];
                    Unlock();
                    request.uploadProgressBlock = ^(NSProgress *progress) {
                        fragment.status = HJUploadStatusProcessing;
                        // NSLog(@"startRequest_fragment_completedUnitCount: %lld / %lld", progress.completedUnitCount, progress.totalUnitCount);
                        if (fragment.progress) {
                            fragment.progress(progress);
                        }
                    };
                    [request startWithCompletionBlockWithSuccess:^(__kindof HJCoreRequest * _Nonnull request) {
                        fragment.status = HJUploadStatusSuccess;
                        if (fragment.completion) {
                            fragment.completion(HJUploadStatusSuccess, weakSelf.sourceId, request.responseObject, nil);
                        }
                        Lock();
                        [weakSelf.requestDict removeObjectForKey:fragment.fragmentId];
                        Unlock();
                    } failure:^(__kindof HJCoreRequest * _Nonnull request) {
                        fragment.status = HJUploadStatusFailure;
                        NSString *errorDesc = request.error.localizedDescription;
                        if ((errorDesc && [errorDesc isEqualToString:@"cancelled"]) || weakSelf.status == HJUploadStatusCancel) {
                            fragment.status = HJUploadStatusCancel;
                        }
                        if (fragment.completion) {
                            fragment.completion(fragment.status, weakSelf.sourceId, request.responseObject, request.error);
                        }
                        Lock();
                        [weakSelf.requestDict removeObjectForKey:fragment.fragmentId];
                        Unlock();
                    }];
                }
            }
        }];
    }];
}

- (void)cancelRequest {
    __weak typeof(self) weakSelf = self;
    [self.blocks enumerateObjectsUsingBlock:^(HJUploadFileBlock * _Nonnull block, NSUInteger idx, BOOL * _Nonnull stop) {
        [block.fragments enumerateObjectsUsingBlock:^(HJUploadFileFragment * _Nonnull fragment, NSUInteger idx, BOOL * _Nonnull stop) {
            if (fragment.status == HJUploadStatusProcessing) {
                Lock();
                HJCoreRequest *request = weakSelf.requestDict[fragment.fragmentId];
                Unlock();
                if (request && request.executing) {
                    [request stop];
                    fragment.status == HJUploadStatusCancel;
                }
            }
        }];
    }];
}

- (void)setCompletionCount:(NSUInteger)completionCount {
    _completionCount = completionCount;
    
    if (_completionCount == self.blockCount) {
        self.blockCount = 0;
        _completionCount = 0;
        
        __block HJUploadStatus status = HJUploadStatusSuccess;
        __block NSError *error = nil;
        __weak typeof(self) weakSelf = self;
        [self.blocks enumerateObjectsUsingBlock:^(HJUploadFileBlock * _Nonnull block, NSUInteger idx, BOOL * _Nonnull stop) {
            weakSelf.callbackInfo = block.callbackInfo;
            if (block.status == HJUploadStatusFailure || block.status == HJUploadStatusCancel) {
                status = HJUploadStatusFailure;
                error = HJErrorWithUnderlyingError(block.error, error);
                if (block.status == HJUploadStatusFailure && ![block.error.domain isEqualToString:HJUploadKeyDomainError]) {
                    weakSelf.blockCount += 1;
                }
            }
        }];
        if (self.status != HJUploadStatusCancel) self.status = status;
        self.error = error;
        
        if (self.error) {
            if (self.config.retryEnable &&
                self.retryCount > 0 &&
                self.blockCount > 0 &&
                self.status == HJUploadStatusFailure) {
                if (self.config.retryInterval) {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.config.retryInterval * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        [self reStartRequest];
                        self.retryCount -= 1;
                        // NSLog(@"HJUploadSource_retryCount = %lu", (self.config.retryCount - self.retryCount));
                    });
                } else {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        [self reStartRequest];
                        self.retryCount -= 1;
                        // NSLog(@"HJUploadSource_retryCount = %lu", (self.config.retryCount - self.retryCount));
                    });
                }
            } else {
                if (self.taskCompletion) {
                    self.taskCompletion(self.taskKey,
                                        self.status==HJUploadStatusCancel?HJTaskStageCancelled:HJTaskStageFinished,
                                        self.callbackInfo, self.error);
                }
                [[HJUploadSourceManager sharedManager] removeSource:self];
            }
        } else {
            if (_completedUnitCount >= self.totalUnitCount) {
                self.fileProgress.completedUnitCount = self.totalUnitCount;
                self.fileProgress.totalUnitCount = self.totalUnitCount;
                if (self.taskCompletion) {
                    self.taskCompletion(self.taskKey, HJTaskStageFinished, self.callbackInfo, self.error);
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
        if (self.taskProgress) {
            // NSLog(@"source_completedUnitCount: %lld / %lld", [(NSProgress *)object completedUnitCount], [(NSProgress *)object totalUnitCount]);
            self.taskProgress(self.taskKey, self.fileProgress);
        }
    }
}

#pragma mark - HJTaskProtocol

- (void)startTask {
    [[HJUploadSourceManager sharedManager] addSource:self];
    self.status = HJUploadStatusProcessing;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self startRequest];
    });
}

- (void)cancelTask {
    self.status = HJUploadStatusCancel;
    [self cancelRequest];
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
        self.retryCount = [[coder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(retryCount))] unsignedIntegerValue];
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
    [coder encodeObject:[NSNumber numberWithUnsignedInteger:self.retryCount] forKey:NSStringFromSelector(@selector(retryCount))];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    HJUploadFileSource *source = [super copyWithZone:zone];
    source.sourceId = self.sourceId;
    source.blocks = self.blocks;
    
    source.totalUnitCount = self.totalUnitCount;
    source.completedUnitCount = self.completedUnitCount;
    source.fileProgress = self.fileProgress;
    source.blockCount = self.blockCount;
    source.completionCount = self.completionCount;
    source.retryCount = self.retryCount;
    return source;
}

@end
