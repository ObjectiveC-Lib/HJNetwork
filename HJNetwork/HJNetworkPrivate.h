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


@interface HJNetworkUtils : NSObject
+ (BOOL)validateJSON:(id)json withValidator:(id)jsonValidator;
+ (void)addDoNotBackupAttribute:(NSString *)path;
+ (NSString *)md5StringFromString:(NSString *)string;
+ (NSString *)appVersionString;
+ (NSStringEncoding)stringEncodingWithRequest:(HJBaseRequest *)request;
+ (BOOL)validateResumeData:(NSData *)data;
+ (BOOL)containsOfString:(NSString *)string originalStr:(NSString *)originalStr;
+ (NSString *)stringByURLDecode:(NSString *)string;
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

