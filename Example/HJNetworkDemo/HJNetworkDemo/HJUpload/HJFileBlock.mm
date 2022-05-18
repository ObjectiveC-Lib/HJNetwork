//
//  HJFileBlock.m
//  HJNetworkDemo
//
//  Created by navy on 2022/9/2.
//

#import "HJFileBlock.h"
#import <WCDB/WCDB.h>
#import "HJFileManager.h"
#import "HJFileSource.h"

@interface HJFileBlock ()
@property (nonatomic, assign) int64_t totalUnitCount;
@property (nonatomic, assign) int64_t completedUnitCount;
@property (nonatomic, assign) NSUInteger completionCount;
@property (nonatomic, strong) NSProgress *fileProgress;
@end

@implementation HJFileBlock

WCDB_IMPLEMENTATION(HJFileBlock)

WCDB_SYNTHESIZE(HJFileBlock, blockId)
WCDB_SYNTHESIZE(HJFileBlock, name)
WCDB_SYNTHESIZE(HJFileBlock, path)
WCDB_SYNTHESIZE(HJFileBlock, absolutePath)
WCDB_SYNTHESIZE(HJFileBlock, fileType)
WCDB_SYNTHESIZE(HJFileBlock, dirType)
WCDB_SYNTHESIZE(HJFileBlock, fragments)
WCDB_SYNTHESIZE(HJFileBlock, source)

WCDB_PRIMARY(HJFileBlock, blockId)

- (void)dealloc {
    [self.fileProgress removeObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted))];
}

- (instancetype)initWithAbsolutePath:(NSString *)path config:(HJUploadConfig *)config {
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
        
        [self fetchFileInfo:path];
        [self cutFragments:config];
    }
    return self;
}

/// 获取文件信息
- (void)fetchFileInfo:(NSString *)absolutePath {
    if (![HJFileManager isExistsAtPath:absolutePath]) {
        NSLog(@"+++ 文件不存在 +++：%@", absolutePath);
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
    
    self.blockId = HJCreateId(self.path);
}

- (void)cutFragments:(HJUploadConfig *)config {
    __weak typeof(self) weakself = self;
    NSUInteger fragmentMaxSize = config.fragmentMaxSize;
    NSUInteger fragmentCount = (self.size%fragmentMaxSize==0)?(self.size/fragmentMaxSize):(self.size/(fragmentMaxSize)+1);
    NSMutableArray<HJFileFragment *> *fragments = [[NSMutableArray alloc] initWithCapacity:0];
    for (NSUInteger i = 0; i < fragmentCount; i++) {
        HJFileFragment *fragment = [[HJFileFragment alloc] init];
        fragment.maxSize = fragmentMaxSize;
        fragment.failureRetryCount = config.failureRetryCount;
        fragment.fragmentId = HJCreateId([NSString stringWithFormat:@"%@_%lu", self.name, (unsigned long)i]);
        fragment.index = i;
        fragment.offset = i * fragmentMaxSize;
        if (i != fragmentCount - 1) {
            fragment.size = fragmentMaxSize;
        } else {
            fragment.size = self.size - fragment.offset;
        }
        fragment.status = HJFileStatusWaiting;
        fragment.block = self;
        fragment.progress = ^(NSProgress * _Nullable progress) {
            __strong typeof(weakself) self = weakself;
            self.completedUnitCount += progress.completedUnitCount;
        };
        fragment.completion = ^(HJFileStatus status, NSError * _Nullable error) {
            __strong typeof(weakself) self = weakself;
            self.completionCount += 1;
        };
        [fragments addObject:fragment];
    }
    self.fragments = fragments.copy;
}

- (void)setCompletionCount:(NSUInteger)completionCount {
    _completionCount = completionCount;
    
    if (_completionCount == self.fragments.count) {
        __block HJFileStatus status = HJFileStatusSuccess;
        [self.fragments enumerateObjectsUsingBlock:^(HJFileFragment * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.status == HJFileStatusFailure) {
                status = HJFileStatusFailure;
                *stop = YES;
            }
        }];
        self.status = status;
        if (self.completion) {
            self.completion(status, nil);
        }
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
            self.progress(object);
        }
    }
}

@end
