//
//  HJUploadSourceManager.m
//  HJNetwork
//
//  Created by navy on 2022/9/5.
//  Copyright © 2022 HJNetwork. All rights reserved.
//

#import "HJUploadSourceManager.h"
#import "HJUploadSource.h"

#define Lock() dispatch_semaphore_wait(self->_lock, DISPATCH_TIME_FOREVER)
#define Unlock() dispatch_semaphore_signal(self->_lock)

@implementation HJUploadSourceManager {
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
        //        NSString *pathOfRoot = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        //        NSString *baseDirectory = [pathOfRoot stringByAppendingPathComponent:@"UploadDB"];
        //        NSLog(@"Base Directory: %@", baseDirectory);
        //        NSString *tableName = NSStringFromClass(HJUploadSource.class);
        //        NSString *tablePath = [baseDirectory stringByAppendingPathComponent:tableName];
        
        _lock = dispatch_semaphore_create(1);
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
