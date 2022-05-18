//
//  HJRequest.h
//  HJNetwork
//
//  Created by navy on 2018/7/5.
//  Copyright © 2018 HJNetwork. All rights reserved.
//

#import "HJBaseRequest.h"

NS_ENUM(NSInteger) {
    HJRequestCacheErrorExpired = -1,
    HJRequestCacheErrorVersionMismatch = -2,
    HJRequestCacheErrorSensitiveDataMismatch = -3,
    HJRequestCacheErrorAppVersionMismatch = -4,
    HJRequestCacheErrorInvalidCacheTime = -5,
    HJRequestCacheErrorInvalidMetadata = -6,
    HJRequestCacheErrorInvalidCacheData = -7,
};

NS_ASSUME_NONNULL_BEGIN

///  HJRequest is the base class you should inherit to create your own request class.
///  Based on HJBaseRequest, HJRequest adds local caching feature. Note download
///  request will not be cached whatsoever, because download request may involve complicated
///  cache control policy controlled by `Cache-Control`, `Last-Modified`, etc.
@interface HJRequest : HJBaseRequest

///  Whether to use cache as response or not.
///  Default is NO, which means caching will take effect with specific arguments.
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

///  The max time duration that cache can stay in disk until it's considered expired.
///  Default is -1, which means response is not actually saved as cache.
- (NSInteger)cacheTimeInSeconds;

///  Version can be used to identify and invalidate local cache. Default is 0.
- (long long)cacheVersion;

///  This can be used as additional identifier that tells the cache needs updating.
///  Using `NSArray` or `NSDictionary` as return value type is recommended
- (nullable id)cacheSensitiveData;

@end

NS_ASSUME_NONNULL_END
