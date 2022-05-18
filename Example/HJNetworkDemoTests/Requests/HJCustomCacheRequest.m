//
//  HJCustomCacheRequest.m
//  HJNetworkDemo
//
//  Created by navy on 18/8/12.
//  Copyright © 2018 HJNetwork. All rights reserved.
//

#import "HJCustomCacheRequest.h"

@interface HJCustomCacheRequest ()

@property (nonatomic, assign) NSInteger cacheTimeInSeconds;
@property (nonatomic, assign) long long cacheVersion;
@property (nonatomic, strong) id cacheSensitiveData;
@end

@implementation HJCustomCacheRequest

- (instancetype)initWithRequestUrl:(NSString *)url cacheTimeInSeconds:(NSInteger)time {
    self = [super initWithRequestUrl:url];
    if (self) {
        _cacheTimeInSeconds = time;
        _cacheVersion = 0;
        _cacheSensitiveData = nil;
    }
    return self;
}

- (instancetype)initWithRequestUrl:(NSString *)url cacheTimeInSeconds:(NSInteger)time cacheVersion:(long long)version cacheSensitiveData:(id)sensitiveData {
    self = [super initWithRequestUrl:url];
    if (self) {
        _cacheTimeInSeconds = time;
        _cacheVersion = version;
        _cacheSensitiveData = sensitiveData;
    }
    return self;
}

- (NSInteger)cacheTimeInSeconds {
    return _cacheTimeInSeconds;
}

- (long long)cacheVersion {
    return _cacheVersion;
}

- (id)cacheSensitiveData {
    return _cacheSensitiveData;
}

- (BOOL)writeCacheAsynchronously {
    return NO; // For testing.
}

@end
