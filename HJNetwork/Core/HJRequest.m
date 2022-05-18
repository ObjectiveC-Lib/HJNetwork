//
//  HJRequest.m
//  HJNetwork
//
//  Created by navy on 2018/7/5.
//  Copyright © 2018 HJNetwork. All rights reserved.
//

#import "HJRequest.h"
#import "HJNetworkConfig.h"
#import "HJNetworkPrivate.h"
#import "HJNetworkCache.h"

@interface HJCacheMetadata : NSObject<NSSecureCoding>
@property (nonatomic, assign) long long version;
@property (nonatomic, strong) NSDate *creationDate;
@property (nonatomic, strong) NSString *appVersionString;
@property (nonatomic, strong) NSString *sensitiveDataString;
@property (nonatomic, assign) NSStringEncoding stringEncoding;
@end

@implementation HJCacheMetadata

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [self init];
    if (!self) return nil;
    self.version = [[aDecoder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(version))] integerValue];
    self.creationDate = [aDecoder decodeObjectOfClass:[NSDate class] forKey:NSStringFromSelector(@selector(creationDate))];
    self.appVersionString = [aDecoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(appVersionString))];
    self.sensitiveDataString = [aDecoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(sensitiveDataString))];
    self.stringEncoding = [[aDecoder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(stringEncoding))] integerValue];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:@(self.version) forKey:NSStringFromSelector(@selector(version))];
    [aCoder encodeObject:self.creationDate forKey:NSStringFromSelector(@selector(creationDate))];
    [aCoder encodeObject:self.appVersionString forKey:NSStringFromSelector(@selector(appVersionString))];
    [aCoder encodeObject:self.sensitiveDataString forKey:NSStringFromSelector(@selector(sensitiveDataString))];
    [aCoder encodeObject:@(self.stringEncoding) forKey:NSStringFromSelector(@selector(stringEncoding))];
}

@end


@interface HJRequest()
@property (nonatomic, strong) id cacheJSON;
@property (nonatomic, strong) NSData *cacheData;
@property (nonatomic, strong) NSString *cacheString;
@property (nonatomic, strong) NSXMLParser *cacheXML;

@property (nonatomic, assign) BOOL dataFromCache;
@property (nonatomic, strong) HJCacheMetadata *cacheMetadata;

/// Custom
@property (nonatomic, strong) NSString *cacheKey;
@end

@implementation HJRequest

- (void)start {
    if (self.ignoreCache) {
        [self startWithoutCache];
        return;
    }
    
    // Do not cache download request.
    if (self.resumableDownloadPath) {
        [self startWithoutCache];
        return;
    }
    
    if (![self loadCacheWithError:nil]) {
        [self startWithoutCache];
        return;
    }
    
    _dataFromCache = YES;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self requestCompletePreprocessor];
        [self requestCompleteFilter];
        
        HJRequest *strongSelf = self;
        if (strongSelf.delegate && [strongSelf.delegate respondsToSelector:@selector(requestFinished:)]) {
            [strongSelf.delegate requestFinished:strongSelf];
        }
        
        if (strongSelf.successCompletionBlock) {
            strongSelf.successCompletionBlock(strongSelf);
        }
        
        [strongSelf clearCompletionBlock];
    });
}

- (void)startWithoutCache {
    [self clearCacheVariables];
    [super start];
}

#pragma mark - Network Request Delegate

- (void)requestCompletePreprocessor {
    [super requestCompletePreprocessor];
    
    [self saveResponseDataToCacheFile:[super responseData]];
}

#pragma mark - Subclass Override

- (NSInteger)cacheTimeInSeconds {
    return -1;
}

- (long long)cacheVersion {
    return 0;
}

- (id)cacheSensitiveData {
    return nil;
}

#pragma mark -

- (BOOL)isDataFromCache {
    return _dataFromCache;
}

- (NSData *)responseData {
    if (_cacheData) {
        return _cacheData;
    }
    return [super responseData];
}

- (NSString *)responseString {
    if (_cacheString) {
        return _cacheString;
    }
    return [super responseString];
}

- (id)responseJSONObject {
    if (_cacheJSON) {
        return _cacheJSON;
    }
    return [super responseJSONObject];
}

- (id)responseObject {
    if (_cacheJSON) {
        return _cacheJSON;
    }
    if (_cacheXML) {
        return _cacheXML;
    }
    if (_cacheData) {
        return _cacheData;
    }
    return [super responseObject];
}

#pragma mark -

- (BOOL)loadCacheWithError:(NSError * _Nullable __autoreleasing *)error {
    // Make sure cache time in valid.
    if ([self cacheTimeInSeconds] < 0) {
        if (error) {
            *error = [NSError errorWithDomain:HJRequestCacheErrorDomain
                                         code:HJRequestCacheErrorInvalidCacheTime
                                     userInfo:@{ NSLocalizedDescriptionKey:@"Invalid cache time"}];
        }
        return NO;
    }
    
    // Try load metadata.
    if (![self loadCacheMetadata]) {
        if (error) {
            *error = [NSError errorWithDomain:HJRequestCacheErrorDomain
                                         code:HJRequestCacheErrorInvalidMetadata
                                     userInfo:@{ NSLocalizedDescriptionKey:@"Invalid metadata. Cache may not exist"}];
        }
        return NO;
    }
    
    // Check if cache is still valid.
    if (![self validateCacheWithError:error]) {
        return NO;
    }
    
    // Try load cache.
    if (![self loadCacheData]) {
        if (error) {
            *error = [NSError errorWithDomain:HJRequestCacheErrorDomain
                                         code:HJRequestCacheErrorInvalidCacheData
                                     userInfo:@{ NSLocalizedDescriptionKey:@"Invalid cache data"}];
        }
        return NO;
    }
    
    return YES;
}

- (BOOL)validateCacheWithError:(NSError * _Nullable __autoreleasing *)error {
    // Date
    NSDate *creationDate = self.cacheMetadata.creationDate;
    NSTimeInterval duration = -[creationDate timeIntervalSinceNow];
    if (duration < 0 || duration > [self cacheTimeInSeconds]) {
        if (error) {
            *error = [NSError errorWithDomain:HJRequestCacheErrorDomain
                                         code:HJRequestCacheErrorExpired
                                     userInfo:@{ NSLocalizedDescriptionKey:@"Cache expired"}];
        }
        return NO;
    }
    
    // Version
    long long cacheVersionFileContent = self.cacheMetadata.version;
    if (cacheVersionFileContent != [self cacheVersion]) {
        if (error) {
            *error = [NSError errorWithDomain:HJRequestCacheErrorDomain
                                         code:HJRequestCacheErrorVersionMismatch
                                     userInfo:@{ NSLocalizedDescriptionKey:@"Cache version mismatch"}];
        }
        return NO;
    }
    
    // Sensitive data
    NSString *sensitiveDataString = self.cacheMetadata.sensitiveDataString;
    NSString *currentSensitiveDataString = ((NSObject *)[self cacheSensitiveData]).description;
    if (sensitiveDataString || currentSensitiveDataString) {
        // If one of the strings is nil, short-circuit evaluation will trigger
        if (sensitiveDataString.length != currentSensitiveDataString.length
            || ![sensitiveDataString isEqualToString:currentSensitiveDataString]) {
            if (error) {
                *error = [NSError errorWithDomain:HJRequestCacheErrorDomain
                                             code:HJRequestCacheErrorSensitiveDataMismatch
                                         userInfo:@{ NSLocalizedDescriptionKey:@"Cache sensitive data mismatch"}];
            }
            return NO;
        }
    }
    
    // App version
    NSString *appVersionString = self.cacheMetadata.appVersionString;
    NSString *currentAppVersionString = [HJNetworkUtils appVersionString];
    if (appVersionString || currentAppVersionString) {
        if (appVersionString.length != currentAppVersionString.length
            || ![appVersionString isEqualToString:currentAppVersionString]) {
            if (error) {
                *error = [NSError errorWithDomain:HJRequestCacheErrorDomain
                                             code:HJRequestCacheErrorAppVersionMismatch
                                         userInfo:@{ NSLocalizedDescriptionKey:@"App version mismatch"}];
            }
            return NO;
        }
    }
    return YES;
}

- (BOOL)loadCacheMetadata {
    self.cacheMetadata = [[HJNetworkCache sharedCache] extendedDataForKey:self.cacheKey];
    return (self.cacheMetadata != nil);
}

- (BOOL)loadCacheData {
    NSData *data = [[HJNetworkCache sharedCache] objectForKey:self.cacheKey];
    if (!data) return NO;
    
    self.cacheData = data;
    self.cacheString = [[NSString alloc] initWithData:self.cacheData encoding:self.cacheMetadata.stringEncoding];
    
    switch (self.responseSerializerType) {
        case HJResponseSerializerTypeHTTP: {
            return YES;
        }
        case HJResponseSerializerTypeJSON: {
            NSError *error = nil;
            self.cacheJSON = [NSJSONSerialization JSONObjectWithData:self.cacheData options:(NSJSONReadingOptions)0 error:&error];
            return (error == nil);
        }
        case HJResponseSerializerTypeXMLParser: {
            self.cacheXML = [[NSXMLParser alloc] initWithData:self.cacheData];
            return YES;
        }
    }
    
    return NO;
}

- (void)saveResponseDataToCacheFile:(NSData *)data {
    if ([self cacheTimeInSeconds] > 0 && ![self isDataFromCache] && !self.isLoadMore) {
        if (data != nil) {
            HJCacheMetadata *metadata = [[HJCacheMetadata alloc] init];
            metadata.version = [self cacheVersion];
            metadata.sensitiveDataString = ((NSObject *)[self cacheSensitiveData]).description;
            metadata.stringEncoding = [HJNetworkUtils stringEncodingWithRequest:self];
            metadata.creationDate = [NSDate date];
            metadata.appVersionString = [HJNetworkUtils appVersionString];
            [[HJNetworkCache sharedCache] setObject:data forKey:self.cacheKey withExtendedData:metadata];
        }
    }
}

- (void)clearCacheVariables {
    _cacheKey = nil;
    _cacheData = nil;
    _cacheXML = nil;
    _cacheJSON = nil;
    _cacheString = nil;
    _cacheMetadata = nil;
    _dataFromCache = NO;
}

- (NSString *)cacheKey {
    if (_cacheKey) return _cacheKey;
    
    NSString *requestUrl = [self requestUrl];
    NSString *baseUrl = [HJNetworkConfig sharedConfig].baseUrl;
    id argument = [self cacheFileNameFilterForRequestArgument:[self requestArgument]];
    NSString *requestInfo = [NSString stringWithFormat:@"Method:%ld Host:%@ Url:%@ Argument:%@", (long)[self requestMethod], baseUrl, requestUrl, argument];
    _cacheKey = [HJNetworkUtils md5StringFromString:requestInfo];
    
    return _cacheKey;
}

@end
