//
//  HJNetworkCache.m
//  HJNetwork
//
//  Created by navy on 2019/3/7.
//  Copyright © 2019 HJNetwork. All rights reserved.
//

#import "HJNetworkCache.h"
#import "HJMemoryCache.h"
#import "HJDiskCache.h"

#ifndef NSFoundationVersionNumber_iOS_8_0
#define NSFoundationVersionNumber_With_QoS_Available 1140.11
#else
#define NSFoundationVersionNumber_With_QoS_Available NSFoundationVersionNumber_iOS_8_0
#endif

static dispatch_queue_t HJRequest_cache_writing_queue() {
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_queue_attr_t attr = DISPATCH_QUEUE_SERIAL;
        if (NSFoundationVersionNumber >= NSFoundationVersionNumber_With_QoS_Available) {
            attr = dispatch_queue_attr_make_with_qos_class(attr, QOS_CLASS_BACKGROUND, 0);
        }
        queue = dispatch_queue_create("com.hj.hjrequest.caching", attr);
    });
    return queue;
}

@implementation HJNetworkCache

#pragma mark - Initializer

+ (HJNetworkCache *)sharedCache {
    static HJNetworkCache *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory,
                                                                   NSUserDomainMask, YES) firstObject];
        cachePath = [cachePath stringByAppendingPathComponent:@"HJNetworkCache"];
        instance = [[self alloc] initWithPath:cachePath];
    });
    return instance;
}

- (nullable instancetype)initWithPath:(NSString *)path {
    if (path.length == 0) return nil;
    
    HJDiskCache *diskCache = [[HJDiskCache alloc] initWithPath:path inlineThreshold:0];
    if (!diskCache) return nil;
    
    NSString *name = [path lastPathComponent];
    HJMemoryCache *memoryCache = [HJMemoryCache new];
    memoryCache.name = name;
    memoryCache.shouldRemoveAllObjectsOnMemoryWarning = YES;
    memoryCache.shouldRemoveAllObjectsWhenEnteringBackground = YES;
    memoryCache.countLimit = NSUIntegerMax;
    memoryCache.costLimit = NSUIntegerMax;
    memoryCache.ageLimit = 12 * 60 * 60;
    
    self = [super init];
    
    _name = name;
    _diskCache = diskCache;
    _memoryCache = memoryCache;
    
    [self addDoNotBackupAttribute:path];
    
    return self;
}

- (void)addDoNotBackupAttribute:(NSString *)path {
    NSURL *url = [NSURL fileURLWithPath:path];
    NSError *error = nil;
    [url setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:&error];
    if (error) {
        NSLog(@"HJNetworkCache: Error to set do not backup attribute, error = %@", error);
    }
}

#pragma mark - Access Methods

- (BOOL)containsObjectForKey:(NSString *)key {
    return [_memoryCache containsObjectForKey:key] || [_diskCache containsObjectForKey:key];
}

- (void)containsObjectForKey:(NSString *)key withBlock:(nullable void(^)(NSString *key, BOOL contains))block {
    if (!block) return;
    
    if ([_memoryCache containsObjectForKey:key]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            block(key, YES);
        });
    } else {
        [_diskCache containsObjectForKey:key withBlock:block];
    }
}

- (nullable id<NSCoding>)objectForKey:(NSString *)key {
    if (!key) return nil;
    
    id<NSCoding> object = [_memoryCache objectForKey:key];
    if (!object) {
        object = [_diskCache objectForKey:key];
        if (object) {
            [_memoryCache setObject:object forKey:key];
        }
    }
    return object;
}

- (void)objectForKey:(NSString *)key withBlock:(nullable void(^)(NSString *key, id<NSCoding> object))block {
    if (!key || !block) return;
    
    id<NSCoding> object = [_memoryCache objectForKey:key];
    if (object) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                block(key, object);
            });
        });
    } else {
        [_diskCache objectForKey:key withBlock:^(NSString *key, id<NSCoding>object) {
            if (object && ![self->_memoryCache objectForKey:key]) {
                [self->_memoryCache setObject:object forKey:key];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                block(key, object);
            });
        }];
    }
}

- (nullable id)extendedDataForKey:(NSString *)key {
    if (!key) return nil;
    
    id object = [self objectForKey:key];
    if (!object) return nil;
    
    id extendedData = nil;
    id data = [HJDiskCache getExtendedDataFromObject:object];
    if (data) {
        extendedData = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
    
    return extendedData;
}

- (void)setObject:(nullable id<NSCoding>)object forKey:(NSString *)key withExtendedData:(id)extendedData {
    if (!key || (!object || !extendedData)) return;
    
    __weak typeof(self) _self = self;
    dispatch_async(HJRequest_cache_writing_queue(), ^{
        __strong typeof(_self) self = _self;
        if (!self) return;
        [self.memoryCache setObject:object forKey:key];
    });
    
    dispatch_async(HJRequest_cache_writing_queue(), ^{
        __strong typeof(_self) self = _self;
        if (!self) return;
        NSError *error = nil;
        if (@available(iOS 11.0, *)) {
            [HJDiskCache setExtendedData:[NSKeyedArchiver archivedDataWithRootObject:extendedData
                                                               requiringSecureCoding:YES
                                                                               error:&error]
                                toObject:object];
        } else {
            [HJDiskCache setExtendedData:[NSKeyedArchiver archivedDataWithRootObject:extendedData] toObject:object];
        }
        [self.diskCache setObject:object forKey:key];
    });
}

- (void)removeObjectForKey:(NSString *)key {
    [_memoryCache removeObjectForKey:key];
    [_diskCache removeObjectForKey:key];
}

- (void)removeObjectForKey:(NSString *)key withBlock:(nullable void(^)(NSString *key))block {
    [_memoryCache removeObjectForKey:key];
    [_diskCache removeObjectForKey:key withBlock:block];
}

- (void)removeAllObjects {
    [_memoryCache removeAllObjects];
    [_diskCache removeAllObjects];
}

- (void)removeAllObjectsWithBlock:(void(^)(void))block {
    [_memoryCache removeAllObjects];
    [_diskCache removeAllObjectsWithBlock:block];
}

- (void)removeAllObjectsWithProgressBlock:(nullable void(^)(int removedCount, int totalCount))progress
                                 endBlock:(nullable void(^)(BOOL error))end {
    [_memoryCache removeAllObjects];
    [_diskCache removeAllObjectsWithProgressBlock:progress endBlock:end];
}

- (NSInteger)totalCost {
    return [_diskCache totalCost];
}

- (NSString *)description {
    if (_name) return [NSString stringWithFormat:@"<%@: %p> (%@)", self.class, self, _name];
    else return [NSString stringWithFormat:@"<%@: %p>", self.class, self];
}

@end
