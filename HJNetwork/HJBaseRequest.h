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
    HJRequestValidationErrorInvalidCustomCode = -10,
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
    HJResponseSerializerTypeHTTP,
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

@protocol HJRequestDelegate <NSObject>
@optional
- (void)requestFinished:(__kindof HJBaseRequest *)request;
- (void)requestFailed:(__kindof HJBaseRequest *)request;
@end


@protocol HJRequestAccessory <NSObject>
@optional
- (void)requestWillStart:(id)request;
- (void)requestWillStop:(id)request;
- (void)requestDidStop:(id)request;
@end


@interface HJBaseRequest : NSObject
@property (nonatomic, strong, readonly) NSURLSessionTask *requestTask;
@property (nonatomic, strong, readonly) NSURLRequest *currentRequest;
@property (nonatomic, strong, readonly) NSURLRequest *originalRequest;
@property (nonatomic, assign, readonly) NSInteger requestDuration; // msec
@property (nonatomic, assign, readonly) NSTimeInterval requestStartTime;
@property (nonatomic, assign, readonly) NSTimeInterval requestStopTime;

@property (nonatomic, strong, readonly) NSHTTPURLResponse *response;
@property (nonatomic, readonly) NSInteger responseStatusCode;
@property (nonatomic, strong, readonly, nullable) NSDictionary *responseHeaders;
@property (nonatomic, strong, readonly, nullable) NSData *responseData;
@property (nonatomic, strong, readonly, nullable) NSString *responseString;
@property (nonatomic, strong, readonly, nullable) id responseObject;
@property (nonatomic, strong, readonly, nullable) id responseJSONObject;

@property (nonatomic, strong, readonly, nullable) NSError *error;

@property (nonatomic, readonly, getter=isCancelled) BOOL cancelled;
@property (nonatomic, readonly, getter=isExecuting) BOOL executing;
@property (nonatomic, readwrite, getter=isLoadMore) BOOL loadMore;


#pragma mark - Request Configuration

@property (nonatomic) NSInteger tag;
@property (nonatomic, strong, nullable) NSDictionary *userInfo;
@property (nonatomic, weak, nullable) id<HJRequestDelegate> delegate;
@property (nonatomic, copy, nullable) HJRequestCompletionBlock successCompletionBlock;
@property (nonatomic, copy, nullable) HJRequestCompletionBlock failureCompletionBlock;
@property (nonatomic, strong, nullable) NSMutableArray<id<HJRequestAccessory>> *requestAccessories;

@property (nonatomic, copy, nullable) AFConstructingBlock constructingBodyBlock;
@property (nonatomic, strong, nullable) NSString *resumableDownloadPath;
@property (nonatomic, copy, nullable) AFURLSessionTaskProgressBlock resumableDownloadProgressBlock;
@property (nonatomic, copy, nullable) AFURLSessionTaskProgressBlock uploadProgressBlock;
@property (nonatomic, copy, nullable) AFURLSessionTaskProgressBlock downloadProgressBlock;

@property (nonatomic) HJRequestPriority requestPriority;

- (void)setCompletionBlockWithSuccess:(nullable HJRequestCompletionBlock)success
                              failure:(nullable HJRequestCompletionBlock)failure;

- (void)clearCompletionBlock;

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

///  The URL path of request. This should only contain the path part of URL, e.g., /v1/user. See alse `baseUrl`.
///  Additionaly, if `requestUrl` itself is a valid URL, it will be used as the result URL and `baseUrl` will be ignored.
- (NSString *)requestUrl;

- (NSString *)cdnUrl;

- (NSTimeInterval)requestTimeoutInterval;

- (nullable id)requestArgument;

- (id)cacheFileNameFilterForRequestArgument:(id)argument;

- (HJRequestMethod)requestMethod;

- (HJRequestSerializerType)requestSerializerType;

- (HJResponseSerializerType)responseSerializerType;

/// The acceptable MIME type for response serializer type of HJResponseSerializerTypeJSON.
- (NSString *)acceptableContentType;

- (nullable NSArray<NSString *> *)requestAuthorizationHeaderFieldArray;

- (nullable NSDictionary<NSString *, NSString *> *)requestHeaderFieldValueDictionary;

///  Use this to build custom request. If this method return non-nil value, `requestUrl`, `requestTimeoutInterval`,
///  `requestArgument`, `allowsCellularAccess`, `requestMethod` and `requestSerializerType` will all be ignored.
- (nullable NSURLRequest *)buildCustomUrlRequest;

- (BOOL)useCDN;

- (BOOL)allowsCellularAccess;

- (nullable id)jsonValidator;

- (BOOL)statusCodeValidator;

- (BOOL)customCodeValidator;

@end

NS_ASSUME_NONNULL_END
