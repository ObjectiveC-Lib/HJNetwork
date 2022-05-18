//
//  HJBaseRequest.h
//  HJNetwork
//
//  Created by navy on 2018/7/4.
//  Copyright © 2018 HJNetwork. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const HJRequestValidationErrorDomain;

NS_ENUM(NSInteger) {
    HJRequestValidationErrorInvalidStatusCode = -8,
    HJRequestValidationErrorInvalidJSONFormat = -9,
    HJRequestValidationErrorInvalidCustomError = -10,
};

typedef NS_ENUM(NSInteger, HJRequestMethod) {
    HJRequestMethodGET = 0,
    HJRequestMethodPOST,
    HJRequestMethodHEAD,
    HJRequestMethodPUT,
    HJRequestMethodDELETE,
    HJRequestMethodPATCH,
};

typedef NS_ENUM(NSInteger, HJRequestSerializerType) {
    HJRequestSerializerTypeHTTP = 0,
    HJRequestSerializerTypeJSON,
};

typedef NS_ENUM(NSInteger, HJResponseSerializerType) {
    HJResponseSerializerTypeHTTP = 0,
    HJResponseSerializerTypeJSON,
    HJResponseSerializerTypeXMLParser,
};

typedef NS_ENUM(NSInteger, HJRequestPriority) {
    HJRequestPriorityLow = -4L,
    HJRequestPriorityDefault = 0,
    HJRequestPriorityHigh = 4,
};

@protocol AFMultipartFormData;
typedef void (^AFConstructingBlock)(id<AFMultipartFormData> formData);
typedef void (^AFURLSessionTaskProgressBlock)(NSProgress *);

@class HJBaseRequest;
typedef void(^HJRequestCompletionBlock)(__kindof HJBaseRequest *request);


///  All the delegate methods will be called on the main queue.
@protocol HJRequestDelegate <NSObject>
@optional
- (void)requestFinished:(__kindof HJBaseRequest *)request;
- (void)requestFailed:(__kindof HJBaseRequest *)request;
@end


///  Track the status of a request
///  All the delegate methods will be called on the main queue.
@protocol HJRequestAccessory <NSObject>
@optional
- (void)requestWillStart:(id)request;
- (void)requestWillStop:(id)request;
- (void)requestDidStop:(id)request;
@end

@class HJDNSNode;

@interface HJBaseRequest : NSObject
@property (nonatomic, strong, readonly) NSURLSessionTask *requestTask;
@property (nonatomic, strong, readonly) NSURLRequest *currentRequest;
@property (nonatomic, strong, readonly) NSURLRequest *originalRequest;

@property (nonatomic, strong, readonly) NSHTTPURLResponse *response;
@property (nonatomic, assign, readonly) NSInteger responseStatusCode;
@property (nonatomic, strong, readonly, nullable) NSDictionary *responseHeaders;
@property (nonatomic, strong, readonly, nullable) NSData *responseData;
@property (nonatomic, strong, readonly, nullable) NSString *responseString;
///  This serialized response object. The actual type of this object is determined by `HJResponseSerializerType`.
///  @discussion If `resumableDownloadPath` and DownloadTask is using, this value will be the path to which file is successfully saved (NSURL)
@property (nonatomic, strong, readonly, nullable) id responseObject;
@property (nonatomic, strong, readonly, nullable) id responseJSONObject;

///  This error can be either serialization error or network error
@property (nonatomic, strong, readonly, nullable) NSError *error;

@property (nonatomic, readonly, getter=isCancelled) BOOL cancelled;
@property (nonatomic, readonly, getter=isExecuting) BOOL executing;
@property (nonatomic, readwrite, getter=isLoadMore) BOOL loadMore;

#pragma mark - Request Configuration

///  Tag can be used to identify request. Default value is 0.
@property (nonatomic, assign) NSInteger tag;

///  The userInfo can be used to store additional info about the request. Default is nil.
@property (nonatomic, strong, nullable) NSDictionary *userInfo;

@property (nonatomic, assign) HJRequestPriority requestPriority;
@property (nonatomic, strong, nullable) NSMutableArray<id<HJRequestAccessory>> *requestAccessories;

@property (nonatomic, weak, nullable) id<HJRequestDelegate> delegate;
@property (nonatomic, copy, nullable) HJRequestCompletionBlock successCompletionBlock;
@property (nonatomic, copy, nullable) HJRequestCompletionBlock failureCompletionBlock;

///  This value is used to perform resumable download request. Default is nil.
///
///  @discussion NSURLSessionDownloadTask is used when this value is not nil.
///              The exist file at the path will be removed before the request starts. If request succeed, file will
///              be saved to this path automatically, otherwise the response will be saved to `responseData`
///              and `responseString`. For this to work, server must support `Range` and response with
///              proper `Last-Modified` and/or `Etag`. See `NSURLSessionDownloadTask` for more detail.
@property (nonatomic, strong, nullable) NSString *resumableDownloadPath;
@property (nonatomic, copy, nullable) AFURLSessionTaskProgressBlock resumableDownloadProgressBlock;
@property (nonatomic, copy, nullable) AFURLSessionTaskProgressBlock uploadProgressBlock;

///  This can be use to construct HTTP body when needed in POST request. Default is nil.
@property (nonatomic, copy, nullable) AFConstructingBlock constructingBodyBlock;

- (void)clearCompletionBlock;

- (void)setCompletionBlockWithSuccess:(nullable HJRequestCompletionBlock)success
                              failure:(nullable HJRequestCompletionBlock)failure;

- (void)addAccessory:(id<HJRequestAccessory>)accessory;

#pragma mark - Request Action

- (void)start;
- (void)stop;
- (void)startWithCompletionBlockWithSuccess:(nullable HJRequestCompletionBlock)success
                                    failure:(nullable HJRequestCompletionBlock)failure;
- (void)startWithCompletionBlockWithSuccess:(nullable HJRequestCompletionBlock)success
                                    failure:(nullable HJRequestCompletionBlock)failure
                                   loadMore:(BOOL)loadMore;

#pragma mark - Subclass Override

- (void)requestCompletePreprocessor;

- (void)requestCompleteFilter;

- (void)requestFailedPreprocessor;

- (void)requestFailedFilter;

///  The baseURL of request. This should only contain the host part of URL, e.g., http://www.example.com.
- (NSString *)baseUrl;

///  The URL path of request. This should only contain the path part of URL, e.g., /v1/user.
///  Additionaly, if `requestUrl` itself is a valid URL, it will be used as the result URL and `baseUrl` will be ignored.
- (NSString *)requestUrl;

///  Optional CDN URL for request.
- (NSString *)cdnUrl;

- (nullable HJDNSNode *)dnsNode;

///  Request timeout interval. Default is 60s.
- (NSTimeInterval)requestTimeoutInterval;

///  Additional request argument.
- (nullable id)requestArgument;

///  Override this method to filter requests with certain arguments when caching.
- (id)cacheFileNameFilterForRequestArgument:(id)argument;

- (HJRequestMethod)requestMethod;

- (HJRequestSerializerType)requestSerializerType;

- (HJResponseSerializerType)responseSerializerType;

///  Username and password used for HTTP authorization. Should be formed as @[@"Username", @"Password"].
- (nullable NSArray<NSString *> *)requestAuthorizationHeaderFieldArray;

///  Additional HTTP request header field.
- (nullable NSDictionary<NSString *, NSString *> *)requestHeaderFieldValueDictionary;

///  Use this to build custom request. If this method return non-nil value, `requestUrl`, `requestTimeoutInterval`,
///  `requestArgument`, `allowsCellularAccess`, `requestMethod` and `requestSerializerType` will all be ignored.
- (nullable NSURLRequest *)buildCustomUrlRequest;

- (BOOL)useCDN;

- (BOOL)useDNS;

///  Default is YES.
- (BOOL)allowsCellularAccess;

///  The validator will be used to test if `responseJSONObject` is correctly formed.
- (nullable id)jsonValidator;

///  This validator will be used to test if `responseStatusCode` is valid.
- (BOOL)statusCodeValidator;

///  Custom Default is NO.
///  This validator will be used to test if `custom error` is valid.
- (BOOL)customErrorValidator:(NSError * _Nullable __autoreleasing *)error;

@end

NS_ASSUME_NONNULL_END
