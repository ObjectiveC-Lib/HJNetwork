//
//  HJNetworkConfig.m
//  HJNetwork
//
//  Created by navy on 2018/7/5.
//  Copyright © 2018 HJNetwork. All rights reserved.
//

#import "HJNetworkConfig.h"
#import "HJBaseRequest.h"
#import "HJNetworkCache.h"

#if __has_include(<AFNetworking/AFSecurityPolicy.h>)
#import <AFNetworking/AFSecurityPolicy.h>
#else
#import <AFNetworking/AFSecurityPolicy.h>
#endif

@implementation HJNetworkConfig {
    NSMutableArray<id<HJUrlFilterProtocol>> *_urlFilters;
    NSMutableArray<id<HJCacheDirPathFilterProtocol>> *_cacheDirPathFilters;
}

+ (HJNetworkConfig *)sharedConfig {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _baseUrl = @"";
        _cdnUrl = @"";
        _cacheCountLimit = 200;
        _urlFilters = [NSMutableArray array];
        _cacheDirPathFilters = [NSMutableArray array];
        _securityPolicy = [AFSecurityPolicy defaultPolicy];
        _debugLogEnabled = NO;
    }
    return self;
}

- (void)addUrlFilter:(id<HJUrlFilterProtocol>)filter {
    [_urlFilters addObject:filter];
}

- (void)clearUrlFilter {
    [_urlFilters removeAllObjects];
}

- (void)addCacheDirPathFilter:(id<HJCacheDirPathFilterProtocol>)filter {
    [_cacheDirPathFilters addObject:filter];
}

- (void)clearCacheDirPathFilter {
    [_cacheDirPathFilters removeAllObjects];
}

- (NSArray<id<HJUrlFilterProtocol>> *)urlFilters {
    return [_urlFilters copy];
}

- (NSArray<id<HJCacheDirPathFilterProtocol>> *)cacheDirPathFilters {
    return [_cacheDirPathFilters copy];
}

- (NSInteger)totalCostOfCache {
    return [[HJNetworkCache sharedCache] totalCost];
}

- (void)removeAllCache {
    [[HJNetworkCache sharedCache] removeAllObjects];
}

#pragma mark - NSObject

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p>{ baseURL: %@ } { cdnURL: %@ }", NSStringFromClass([self class]), self, self.baseUrl, self.cdnUrl];
}

@end
