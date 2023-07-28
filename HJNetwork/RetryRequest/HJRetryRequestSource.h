//
//  HJRetryRequestSource.h
//  HJNetwork
//
//  Created by navy on 2023/6/13.
//  Copyright © 2023 HJNetwork. All rights reserved.

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>
#import <HJNetwork/HJRequest.h>
#import <HJTask/HJTask.h>
#import "HJRetryRequestConfig.h"

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
typedef void (^HJRetryRequestCompletionBlock)(HJRetryRequestStatus status, id _Nullable callbackInfo, NSError *_Nullable error);

@interface HJRetryRequestSource : NSObject <NSSecureCoding, NSCopying, HJTaskProtocol>

@property (nonatomic, copy, nullable) HJTaskKey taskKey;
/// identifier
@property (nonatomic, strong) HJRetryRequestKey sourceId;
/// 状态
@property (nonatomic, assign) HJRetryRequestStatus status;
/// 进度
@property (nonatomic,   copy) HJRetryRequestProgressBlock progress;
/// 结果
@property (nonatomic,   copy) HJRetryRequestCompletionBlock completion;
/// 回调信息
@property (nonatomic, strong) id _Nullable callbackInfo;
/// 错误
@property (nonatomic, strong) NSError *_Nullable error;
/// Retry Request
@property (nonatomic,   copy) HJCoreRequest *(^retryRequestBlock)(void);

- (instancetype)initWithConfig:(HJRetryRequestConfig *)config;
@end

NS_ASSUME_NONNULL_END
