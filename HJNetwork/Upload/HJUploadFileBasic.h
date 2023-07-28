//
//  HJUploadFileBasic.h
//  HJNetwork
//
//  Created by navy on 2022/9/7.
//  Copyright © 2022 HJNetwork. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>
#import "HJUploadConfig.h"

typedef NS_ENUM(NSUInteger, HJDirectoryType) {
    HJDirectoryTypeNone = 0,
    HJDirectoryTypeDocument,
    HJDirectoryTypeLibrary,
    HJDirectoryTypeCaches,
    HJDirectoryTypeTemporary,
    HJDirectoryTypeMainBundle
};

/// 文件上传状态
typedef NS_ENUM(NSUInteger, HJUploadStatus) {
    HJUploadStatusWaiting = 0,    /// 准备
    HJUploadStatusProcessing = 1, /// 进行中
    HJUploadStatusSuccess = 2,    /// 成功
    HJUploadStatusFailure = 3,    /// 失败
    HJUploadStatusCancel = 4,     /// 取消
};

/// 文件类型
typedef NS_ENUM(NSInteger, HJFileType) {
    HJFileTypeNone = 0,
    HJFileTypeImage = 1,    /// 图片
    HJFileTypeVideo = 2,    /// 视频
};

static inline NSString * _Nullable HJFileCreateId(NSString * _Nullable identifier) {
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

static inline NSString * _Nullable HJDataMD5String(NSData * _Nullable data) {
    if (!data) return nil;
    
    unsigned char outputBuffer[CC_MD5_DIGEST_LENGTH];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    CC_MD5(data.bytes, (CC_LONG)(data.length), outputBuffer);
#pragma clang diagnostic pop
    
    NSMutableString *key = [[NSMutableString alloc] initWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (NSInteger count = 0; count < CC_MD5_DIGEST_LENGTH; count++) {
        [key appendFormat:@"%02x", outputBuffer[count]];
    }
    return key;
}

static inline NSError * _Nullable HJErrorWithUnderlyingError(NSError * _Nullable error, NSError * _Nullable underlyingError) {
    if (!error) {
        return underlyingError;
    }
    
    if (!underlyingError || error.userInfo[NSUnderlyingErrorKey]) {
        return error;
    }
    
    NSMutableDictionary *mutableUserInfo = [error.userInfo mutableCopy];
    mutableUserInfo[NSUnderlyingErrorKey] = underlyingError;
    
    return [[NSError alloc] initWithDomain:error.domain code:error.code userInfo:mutableUserInfo];
}

typedef void(^HJUploadProgressBlock)(NSProgress * _Nullable progress);

typedef void (^HJUploadCompletionBlock)(HJUploadStatus status, id _Nullable callbackInfo, NSError *_Nullable error);

NS_ASSUME_NONNULL_BEGIN

@interface HJUploadFileBasic : NSObject <NSSecureCoding, NSCopying>

/// 大小
@property (nonatomic, assign) NSUInteger size;
/// 状态
@property (nonatomic, assign) HJUploadStatus status;
/// 进度
@property (nonatomic,   copy) HJUploadProgressBlock progress;
/// 结果
@property (nonatomic,   copy) HJUploadCompletionBlock completion;
/// 回调信息
@property (nonatomic, strong) id _Nullable callbackInfo;
/// 错误
@property (nonatomic, strong) NSError *_Nullable error;

@end

NS_ASSUME_NONNULL_END
