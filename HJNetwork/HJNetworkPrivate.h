//
//  HJNetworkPrivate.h
//  HJNetwork
//
//  Created by navy on 2018/7/4.
//  Copyright © 2018 HJNetwork. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HJRequest.h"
#import "HJBaseRequest.h"
#import "HJBatchRequest.h"
#import "HJChainRequest.h"
#import "HJNetworkAgent.h"
#import "HJNetworkConfig.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT void HJLog(NSString *format, ...) NS_FORMAT_FUNCTION(1,2);
FOUNDATION_EXPORT BOOL HJNSStringAvailable(NSString *string);

@class AFHTTPSessionManager;

@interface HJNetworkPrivate : NSObject
@end

@interface HJNetworkUtils : NSObject
+ (BOOL)validateResumeData:(NSData *)data;
+ (BOOL)validateJSON:(id)json withValidator:(id)jsonValidator;
+ (BOOL)containsOfString:(NSString *)string originalStr:(NSString *)originalStr;
+ (void)addDoNotBackupAttribute:(NSString *)path;
+ (NSString *)appVersionString;
+ (NSString *)md5StringFromString:(NSString *)string;
+ (NSString *)stringByURLDecode:(NSString *)string;
+ (NSStringEncoding)stringEncodingWithRequest:(HJBaseRequest *)request;
@end


@interface HJRequest (Getter)
- (NSString *)cacheBasePath;
@end


@interface HJBaseRequest (Setter)
@property (nonatomic, strong, readwrite) NSURLSessionTask *requestTask;
@property (nonatomic, strong, readwrite, nullable) NSData *responseData;
@property (nonatomic, strong, readwrite, nullable) id responseJSONObject;
@property (nonatomic, strong, readwrite, nullable) id responseObject;
@property (nonatomic, strong, readwrite, nullable) NSString *responseString;
@property (nonatomic, strong, readwrite, nullable) NSError *error;
@property (nonatomic, assign, readwrite) NSTimeInterval requestStartTime;
@property (nonatomic, assign, readwrite) NSTimeInterval requestStopTime;
@end


@interface HJBaseRequest (RequestAccessory)
- (void)toggleAccessoriesWillStartCallBack;
- (void)toggleAccessoriesWillStopCallBack;
- (void)toggleAccessoriesDidStopCallBack;
@end


@interface HJBatchRequest (RequestAccessory)
- (void)toggleAccessoriesWillStartCallBack;
- (void)toggleAccessoriesWillStopCallBack;
- (void)toggleAccessoriesDidStopCallBack;
@end


@interface HJChainRequest (RequestAccessory)
- (void)toggleAccessoriesWillStartCallBack;
- (void)toggleAccessoriesWillStopCallBack;
- (void)toggleAccessoriesDidStopCallBack;
@end


@interface HJNetworkAgent (Private)
- (AFHTTPSessionManager *)manager;
- (void)resetURLSessionManager;
- (void)resetURLSessionManagerWithConfiguration:(NSURLSessionConfiguration *)configuration;
- (NSString *)incompleteDownloadTempCacheFolder;
@end

NS_ASSUME_NONNULL_END

