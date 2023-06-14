//
//  HJRetryRequestSourceManager.m
//  HJNetwork
//
//  Created by navy on 2023/6/13.
//  Copyright © 2023 HJNetwork. All rights reserved.

#import "HJRetryRequestSourceManager.h"
#import "HJRetryRequestSource.h"

#define Lock() dispatch_semaphore_wait(self->_lock, DISPATCH_TIME_FOREVER)
#define Unlock() dispatch_semaphore_signal(self->_lock)

@implementation HJRetryRequestSourceManager {
    dispatch_semaphore_t _lock;
    NSMutableDictionary *_sources;
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
        _lock = dispatch_semaphore_create(1);
        _sources = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)addSource:(HJRetryRequestSource *)source {
    if (!source) return;
    Lock();
    [_sources setObject:source forKey:source.sourceId];
    Unlock();
}

- (void)removeSource:(HJRetryRequestSource *)source {
    if (!source) return;
    Lock();
    [_sources removeObjectForKey:source.sourceId];
    Unlock();
}

- (HJRetryRequestSource *)getSource:(NSString *)sourceId {
    if (!sourceId || sourceId.length <= 0) return nil;
    HJRetryRequestSource *source = nil;
    Lock();
    if (_sources.count) {
        source = [_sources objectForKey:sourceId];
    }
    Unlock();
    return source;
}

@end
