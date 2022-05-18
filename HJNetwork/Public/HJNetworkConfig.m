//
//  HJNetworkConfig.m
//  HJNetwork
//
//  Created by navy on 2018/7/5.
//  Copyright © 2018 HJNetwork. All rights reserved.
//

#import "HJNetworkConfig.h"

#if __has_include(<AFNetworking/AFSecurityPolicy.h>)
#import <AFNetworking/AFSecurityPolicy.h>
#elif __has_include("AFSecurityPolicy.h")
#import "AFSecurityPolicy.h"
#endif

NSString *const HJRequestCacheErrorDomain = @"com.hj.request.caching";

void HJLog(NSString *format, ...) {
#ifdef DEBUG
    if (![HJNetworkConfig sharedConfig].debugLogEnabled) return;
    
    va_list argptr;
    va_start(argptr, format);
    NSLogv(format, argptr);
    va_end(argptr);
#endif
}

@implementation HJNetworkConfig {
    NSMutableArray<id<HJUrlFilterProtocol>> *_urlFilters;
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
        _urlFilters = [NSMutableArray array];
        _securityPolicy = [AFSecurityPolicy defaultPolicy];
        _sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
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

- (NSArray<id<HJUrlFilterProtocol>> *)urlFilters {
    return [_urlFilters copy];
}

#pragma mark - NSObject

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p>{ baseURL: %@ } { cdnURL: %@ }", NSStringFromClass([self class]), self, self.baseUrl, self.cdnUrl];
}

@end
