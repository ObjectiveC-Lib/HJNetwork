//
//  HJNetworkConfig.h
//  HJNetwork
//
//  Created by navy on 2018/7/5.
//  Copyright © 2018 HJNetwork. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class HJBaseRequest;
@class AFSecurityPolicy;

@protocol HJUrlFilterProtocol <NSObject>
- (NSString *)filterUrl:(NSString *)originUrl urlEncode:(BOOL)urlEncode withRequest:(HJBaseRequest *)request;
@end

@protocol HJCacheDirPathFilterProtocol <NSObject>
- (NSString *)filterCacheDirPath:(NSString *)originPath withRequest:(HJBaseRequest *)request;
@end

@interface HJNetworkConfig : NSObject
@property NSUInteger cacheCountLimit;
@property (nonatomic, strong) NSString *baseUrl;
@property (nonatomic, strong) NSString *cdnUrl;
@property (nonatomic, strong, readonly) NSArray<id<HJUrlFilterProtocol>> *urlFilters;
@property (nonatomic, strong, readonly) NSArray<id<HJCacheDirPathFilterProtocol>> *cacheDirPathFilters;
@property (nonatomic, strong) AFSecurityPolicy *securityPolicy;
@property (nonatomic) BOOL debugLogEnabled;
@property (nonatomic, strong) NSURLSessionConfiguration *sessionConfiguration;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
+ (HJNetworkConfig *)sharedConfig;

- (void)addUrlFilter:(id<HJUrlFilterProtocol>)filter;
- (void)clearUrlFilter;
- (void)addCacheDirPathFilter:(id<HJCacheDirPathFilterProtocol>)filter;
- (void)clearCacheDirPathFilter;

- (NSInteger)totalCostOfCache;
- (void)removeAllCache;
@end

NS_ASSUME_NONNULL_END
