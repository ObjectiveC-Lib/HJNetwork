//
//  DMSDWebImageManager.m
//  HJNetworkDemo
//
//  Created by navy on 2023/4/6.
//

#import "DMSDWebImageManager.h"
#import "DMSDWebImageOperation.h"
#import <pthread/pthread.h>

#define Lock() pthread_mutex_lock(&_lock)
#define Unlock() pthread_mutex_unlock(&_lock)

#define DM_MAX_FILE_EXTENSION_LENGTH (NAME_MAX - CC_MD5_DIGEST_LENGTH * 2 - 1)
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
static inline NSString * _Nonnull DMFileNameForKey(NSString * _Nullable key, BOOL addExt, BOOL md5) {
    const char *str = key.UTF8String;
    if (str == NULL) {
        str = "";
    }
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), r);
    NSURL *keyURL = [NSURL URLWithString:key];
    NSString *ext = keyURL ? keyURL.pathExtension : key.pathExtension;
    // File system has file name length limit, we need to check if ext is too long, we don't add it to the filename
    if (ext.length > DM_MAX_FILE_EXTENSION_LENGTH) {
        ext = nil;
    }
    
    NSString *filename = keyURL.lastPathComponent.stringByDeletingPathExtension;
    if (md5) {
        filename = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                    r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10],
                    r[11], r[12], r[13], r[14], r[15]];
    }
    
    if (addExt) {
        filename = [filename stringByAppendingFormat:@"%@", ext.length == 0 ? @"" : [NSString stringWithFormat:@".%@", ext]];
    }
    return filename;
}
#pragma clang diagnostic pop

@interface DMSDWebImageManager()
@property (nonatomic, strong, readonly) HJCommonCache *commonCache;
@property (nonatomic, copy, readwrite, nonnull) NSString *diskCachePath;
@end

@implementation DMSDWebImageManager {
    pthread_mutex_t _lock;
}

// Documents
+ (nullable NSString *)userDocumentDirectory {
    NSArray<NSString *> *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return paths.firstObject;
}

// Library/Caches
+ (nullable NSString *)userCacheDirectory {
    NSArray<NSString *> *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return paths.firstObject;
}

// tmp
+ (nullable NSString *)userTemporaryDirectory {
    return NSTemporaryDirectory();
}

+ (NSString *)defaultDiskCacheDirectory {
    return [[self userCacheDirectory] stringByAppendingPathComponent:@"DMResourcesCache"];
}

+ (NSString *)defaultDiskDocumentDirectory {
    return [[self userDocumentDirectory] stringByAppendingPathComponent:@"DMResourcesCache"];
}

+ (NSString *)defaultDiskTemporaryDirectory {
    return [[self userTemporaryDirectory] stringByAppendingPathComponent:@"DMResourcesCache"];
}

+ (instancetype)sharedManager {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = [[self alloc] initWithNamespace:@"Store" diskDirectory:[self.class defaultDiskDocumentDirectory]];
    });
    return instance;
}

- (instancetype)initWithPath:(NSString *)diskCachePath {
    if ((self = [super init])) {
        pthread_mutex_init(&_lock, NULL);
        _diskCachePath = diskCachePath;
        HJCommonCache *cache = [[HJCommonCache alloc] initWithPath:diskCachePath threshold:0];
        if (!cache) return nil;
        _commonCache = cache;
    }
    return self;
}

- (instancetype)initWithNamespace:(nonnull NSString *)ns diskDirectory:(nonnull NSString *)directory {
    NSString *diskCachePath = [directory stringByAppendingPathComponent:ns];
    if (self = [self initWithPath:diskCachePath]) {
        NSAssert(ns, @"Document namespace should not be nil");
        NSAssert(directory, @"Document directory should not be nil");
        
        HJCommonCache *cache = _commonCache;
        cache.diskCache.customArchiveBlock = ^(id object) { return (NSData *)object; };
        cache.diskCache.customUnarchiveBlock = ^(NSData *data) { return (id)data; };
        cache.diskCache.customFileNameBlock = ^NSString * _Nonnull(NSString * _Nonnull key) { return DMFileNameForKey(key, YES, YES); };
        
        SDWebImageDownloaderConfig *downloaderConfig = [[SDWebImageDownloaderConfig alloc] init];
        downloaderConfig.operationClass = [DMSDWebImageOperation class];
        downloaderConfig.sessionConfiguration = [HJProtocolManager sharedManager].sessionConfiguration;
        SDWebImageDownloader *downloader = [[SDWebImageDownloader alloc] initWithConfig:downloaderConfig];
        SDWebImageManager *imageManager = [[SDWebImageManager alloc] initWithCache:cache loader:downloader];
        _imageManager = imageManager;
        
        SDWebImagePrefetcher *imagePrefetcher = [[SDWebImagePrefetcher alloc] initWithImageManager:imageManager];
        _imagePrefetcher = imagePrefetcher;
    }
    return self;
}

@end
