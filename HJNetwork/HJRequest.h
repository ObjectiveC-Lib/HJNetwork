//
//  HJRequest.h
//  HJNetwork
//
//  Created by navy on 2018/7/5.
//  Copyright © 2018 HJNetwork. All rights reserved.
//

#import "HJBaseRequest.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const HJRequestCacheErrorDomain;

NS_ENUM(NSInteger) {
    HJRequestCacheErrorExpired = -1,
    HJRequestCacheErrorVersionMismatch = -2,
    HJRequestCacheErrorSensitiveDataMismatch = -3,
    HJRequestCacheErrorAppVersionMismatch = -4,
    HJRequestCacheErrorInvalidCacheTime = -5,
    HJRequestCacheErrorInvalidMetadata = -6,
    HJRequestCacheErrorInvalidCacheData = -7,
};

@interface HJRequest : HJBaseRequest

/// Default is NO, Whether to use cache as response or not.
@property (nonatomic, assign) BOOL ignoreCache;

///  Whether data is from local cache.
- (BOOL)isDataFromCache;

///  Manually load cache from storage.
- (BOOL)loadCacheWithError:(NSError * __autoreleasing *)error;

///  Start request without reading local cache even if it exists. Use this to update local cache.
- (void)startWithoutCache;

///  Save response data (probably from another request) to this request's cache location
- (void)saveResponseDataToCacheFile:(NSData *)data;

#pragma mark - Subclass Override

///  Default is -1, which means response is not actually saved as cache.
- (NSInteger)cacheTimeInSeconds;

/// Default is 0.
- (long long)cacheVersion;

///  This can be used as additional identifier that tells the cache needs updating.
///  Using `NSArray` or `NSDictionary` as return value type is recommended
- (nullable id)cacheSensitiveData;

///  Whether cache is asynchronously written to storage. Default is YES.
- (BOOL)writeCacheAsynchronously;

@end

NS_ASSUME_NONNULL_END
