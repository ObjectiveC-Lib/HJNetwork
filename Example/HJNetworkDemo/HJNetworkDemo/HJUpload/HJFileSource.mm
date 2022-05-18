//
//  HJFileSource.m
//  HJNetworkDemo
//
//  Created by navy on 2022/9/5.
//

#import "HJFileSource.h"
#import "HJFileSourceManager.h"
#import <WCDB/WCDB.h>

@interface HJFileSource ()
@property (nonatomic, assign) int64_t totalUnitCount;
@property (nonatomic, assign) int64_t completedUnitCount;
@property (nonatomic, assign) NSUInteger completionCount;
@property (nonatomic, strong) NSProgress *fileProgress;
@end

@implementation HJFileSource

WCDB_IMPLEMENTATION(HJFileSource)
WCDB_SYNTHESIZE(HJFileSource, sourceId)
WCDB_SYNTHESIZE(HJFileSource, blocks)
WCDB_PRIMARY(HJFileSource, sourceId)

- (void)dealloc {
    [self.fileProgress removeObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted))];
    
    NSLog(@"HJFileSource dealloc");
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
            HJFileBlock *block = [[HJFileBlock alloc] initWithAbsolutePath:path config:config];
            block.source = self;
            size += block.size;
            block.progress = ^(NSProgress * _Nullable progress) {
                __strong typeof(weakself) self = weakself;
                self.completedUnitCount += progress.completedUnitCount;
            };
            block.completion = ^(HJFileStatus status, NSError * _Nullable error) {
                __strong typeof(weakself) self = weakself;
                self.completionCount += 1;
            };
            [blocks addObject:block];
            [sourceId appendString:block.path];
        }];
        _sourceId = HJCreateId(sourceId);
        _blocks = [blocks copy];
        
        self.size = size;
        self.totalUnitCount = self.size;
        self.status = HJFileStatusWaiting;
    }
    return self;
}

- (void)startWithBlock:(void (^)(HJFileFragment * _Nonnull fragment))sourceBlock {
    [[HJFileSourceManager sharedManager] addSource:self];
    
    [self.blocks enumerateObjectsUsingBlock:^(HJFileBlock * _Nonnull block, NSUInteger idx, BOOL * _Nonnull stop) {
        [block.fragments enumerateObjectsUsingBlock:^(HJFileFragment * _Nonnull fragment, NSUInteger idx, BOOL * _Nonnull stop) {
            if (sourceBlock) {
                sourceBlock(fragment);
            }
        }];
    }];
}

- (void)cancelWithBlock:(void (^)(HJFileFragment * _Nonnull fragment))sourceBlock {
    [self.blocks enumerateObjectsUsingBlock:^(HJFileBlock * _Nonnull block, NSUInteger idx, BOOL * _Nonnull stop) {
        [block.fragments enumerateObjectsUsingBlock:^(HJFileFragment * _Nonnull fragment, NSUInteger idx, BOOL * _Nonnull stop) {
            if (sourceBlock) {
                sourceBlock(fragment);
            }
        }];
    }];
}

- (void)setCompletionCount:(NSUInteger)completionCount {
    _completionCount = completionCount;
    
    if (_completionCount == self.blocks.count) {
        __block HJFileStatus status = HJFileStatusSuccess;
        [self.blocks enumerateObjectsUsingBlock:^(HJFileBlock * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.status == HJFileStatusFailure) {
                status = HJFileStatusFailure;
                *stop = YES;
            }
        }];
        self.status = status;
        if (self.completion) {
            self.completion(status, nil);
        }
        
        [[HJFileSourceManager sharedManager] removeSource:self];
    }
}

- (void)setCompletedUnitCount:(int64_t)completedUnitCount {
    _completedUnitCount = completedUnitCount;
    
    if (_completedUnitCount >= self.totalUnitCount) {
        self.fileProgress.completedUnitCount = self.totalUnitCount;
        self.fileProgress.totalUnitCount = self.totalUnitCount;
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

@end
