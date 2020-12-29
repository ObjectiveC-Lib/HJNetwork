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

typedef void (^AFURLSessionTaskDidFinishCollectingMetricsBlock)(NSURLSession *session, NSURLSessionTask *task, NSURLSessionTaskMetrics * metrics) API_AVAILABLE(ios(10), macosx(10.12), watchos(3), tvos(10));

@protocol HJUrlFilterProtocol <NSObject>
- (NSString *)filterUrl:(NSString *)originUrl urlEncode:(BOOL)urlEncode withRequest:(HJBaseRequest *)request;
@end

@protocol HJCacheDirPathFilterProtocol <NSObject>
- (NSString *)filterCacheDirPath:(NSString *)originPath withRequest:(HJBaseRequest *)request;
@end

@interface HJNetworkConfig : NSObject

@property (nonatomic, strong) NSString *baseUrl;
@property (nonatomic, strong) NSString *cdnUrl;
@property (nonatomic, assign) BOOL debugLogEnabled;
@property (nonatomic, assign) NSUInteger cacheCountLimit;
@property (nonatomic, strong) NSURLSessionConfiguration *sessionConfiguration;
@property (nonatomic, strong) AFSecurityPolicy *securityPolicy;
@property (nonatomic, strong, readonly) NSArray<id<HJUrlFilterProtocol>> *urlFilters;
@property (nonatomic, strong, readonly) NSArray<id<HJCacheDirPathFilterProtocol>> *cacheDirPathFilters;
@property (nonatomic, strong) AFURLSessionTaskDidFinishCollectingMetricsBlock collectingMetricsBlock API_AVAILABLE(ios(10), macosx(10.12), watchos(3), tvos(10));

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
