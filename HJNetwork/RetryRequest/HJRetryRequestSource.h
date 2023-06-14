//
//  HJRetryRequestSource.h
//  HJNetwork
//
//  Created by navy on 2023/6/13.
//  Copyright © 2023 HJNetwork. All rights reserved.

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>

#ifndef dispatch_request_main_async_safe
#define dispatch_request_main_async_safe(block)\
if (dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(dispatch_get_main_queue())) {\
    block();\
} else {\
    dispatch_async(dispatch_get_main_queue(), block);\
}
#endif

@class HJRetryRequestConfig;

NS_ASSUME_NONNULL_BEGIN

/// 请求状态
typedef NS_ENUM(NSUInteger, HJRetryRequestStatus) {
    HJRetryRequestStatusWaiting = 0,    /// 准备
    HJRetryRequestStatusProcessing = 1, /// 进行中
    HJRetryRequestStatusSuccess = 2,    /// 成功
    HJRetryRequestStatusFailure = 3,    /// 失败
    HJRetryRequestStatusCancel = 4,     /// 取消
};

static inline NSString * _Nullable HJRetryRequestCreateId(NSString * _Nullable identifier) {
    if (identifier == nil || [identifier length] <= 0) return nil;
    
    identifier = [identifier stringByAppendingString:[NSString stringWithFormat:@"%ld", (long)[[NSDate date] timeIntervalSince1970]]];
    identifier = [identifier stringByAppendingString:[NSString stringWithFormat:@"%d",arc4random()%10000]];
    
    const char *value = [identifier UTF8String];
    unsigned char outputBuffer[CC_MD5_DIGEST_LENGTH];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    CC_MD5(value, (CC_LONG)strlen(value), outputBuffer);
#pragma clang diagnostic pop
    
    NSMutableString *key = [[NSMutableString alloc] initWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (NSInteger count = 0; count < CC_MD5_DIGEST_LENGTH; count++){
        [key appendFormat:@"%02x", outputBuffer[count]];
    }
    return key;
}

typedef NSString * _Nullable HJRetryRequestKey;
static const HJRetryRequestKey HJRetryRequestKeyInvalid = nil;

typedef void (^HJRetryRequestProgressBlock)(NSProgress * _Nullable progress);
typedef void (^HJRetryRequestCompletionBlock)(HJRetryRequestStatus status, NSDictionary<NSString *, id> * _Nullable callbackInfo, NSError *_Nullable error);

@interface HJRetryRequestSource : NSObject <NSSecureCoding, NSCopying>
/// identifier
@property (nonatomic, strong) HJRetryRequestKey sourceId;
/// 状态
@property (nonatomic, assign) HJRetryRequestStatus status;
/// 进度
@property (nonatomic,   copy) HJRetryRequestProgressBlock progress;
/// 结果
@property (nonatomic,   copy) HJRetryRequestCompletionBlock completion;
/// 回调信息
@property (nonatomic, strong) NSMutableDictionary <NSString *, id> * _Nullable callbackInfo;
/// 错误
@property (nonatomic, strong) NSError *_Nullable error;

- (instancetype)initWithRequestUrl:(NSString *)requestUrl
                            config:(HJRetryRequestConfig *)config
                   requestProgress:(void (^)(NSProgress * _Nullable progress))requestProgress
                 requestCompletion:(void (^)(NSDictionary<NSString *,id> * _Nullable callbackInfo, NSError * _Nullable error))requestCompletion;

- (void)startWithBlock:(void (^)(HJRetryRequestSource *source))block;
- (void)cancelWithBlock:(void (^)(HJRetryRequestSource *source))cancelBlock;

+ (void)cancelWithKey:(HJRetryRequestKey)key block:(void (^)(HJRetryRequestSource *source))block;

@end

NS_ASSUME_NONNULL_END
