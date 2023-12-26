//
//  HJUploadSourceManager.m
//  HJNetwork
//
//  Created by navy on 2022/9/5.
//  Copyright © 2022 HJNetwork. All rights reserved.
//

#import "HJUploadSourceManager.h"
#import "HJUploadSource.h"
#import <pthread/pthread.h>

#define Lock() pthread_mutex_lock(&_lock)
#define Unlock() pthread_mutex_unlock(&_lock)

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

- (void)addSource:(HJUploadSource *)source {
    if (!source) return;
    Lock();
    [_sources setObject:source forKey:source.sourceId];
    Unlock();
}

- (void)removeSource:(HJUploadSource *)source {
    if (!source) return;
    Lock();
    [_sources removeObjectForKey:source.sourceId];
    Unlock();
}

- (HJUploadSource *)getSource:(NSString *)sourceId {
    if (!sourceId || sourceId.length <= 0) return nil;
    HJUploadSource *source = nil;
    Lock();
    if (_sources.count) {
        source = [_sources objectForKey:sourceId];
    }
    Unlock();
    return source;
}

@end
