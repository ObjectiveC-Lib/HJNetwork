//
//  HJFileSourceManager.m
//  HJNetworkDemo
//
//  Created by navy on 2022/9/5.
//

#import "HJFileSourceManager.h"
#import <WCDB/WCDB.h>
#import "HJFileSource.h"

#define Lock() dispatch_semaphore_wait(self->_lock, DISPATCH_TIME_FOREVER)
#define Unlock() dispatch_semaphore_signal(self->_lock)

@implementation HJFileSourceManager {
    WCTDatabase *_database;
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
        NSString *pathOfRoot = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *baseDirectory = [pathOfRoot stringByAppendingPathComponent:@"UploadDB"];
        NSLog(@"Base Directory: %@", baseDirectory);
        NSString *tableName = NSStringFromClass(HJFileSource.class);
        NSString *tablePath = [baseDirectory stringByAppendingPathComponent:tableName];
        _database = [[WCTDatabase alloc] initWithPath:tablePath];
        [_database createTableAndIndexesOfName:tableName withClass:HJFileSource.class];
        
        _lock = dispatch_semaphore_create(1);
        _sources = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)addSource:(HJFileSource *)source {
    Lock();
    [_sources setObject:source forKey:source.sourceId];
    Unlock();
}

- (void)removeSource:(HJFileSource *)source {
    Lock();
    [_sources removeObjectForKey:source.sourceId];
    Unlock();
}

@end
