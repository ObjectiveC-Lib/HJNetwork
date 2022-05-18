//
//  HJFileBasic.h
//  HJNetworkDemo
//
//  Created by navy on 2022/9/7.
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
typedef NS_ENUM(NSUInteger, HJFileStatus) {
    HJFileStatusWaiting = 0,    /// 准备
    HJFileStatusProcessing = 1, /// 进行中
    HJFileStatusSuccess = 2,    /// 成功
    HJFileStatusFailure = 3,    /// 失败
};

/// 文件类型
typedef NS_ENUM(NSInteger, HJFileType) {
    HJFileTypeNone = 0,
    HJFileTypeImage = 1,    /// 图片
    HJFileTypeVideo = 2,    /// 视频
};

static inline NSString * _Nullable HJCreateId(NSString * _Nullable identifier) {
    if (identifier == nil || [identifier length] <= 0) return nil;
    
    identifier = [identifier stringByAppendingString:[NSString stringWithFormat:@"%ld", (long)[[NSDate date] timeIntervalSince1970]]];
    identifier = [identifier stringByAppendingString:[NSString stringWithFormat:@"%d",arc4random()%10000]];
    
    const char *value = [identifier UTF8String];
    unsigned char outputBuffer[CC_MD5_DIGEST_LENGTH];
    CC_MD5(value, (CC_LONG)strlen(value), outputBuffer);
    
    NSMutableString *key = [[NSMutableString alloc] initWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (NSInteger count = 0; count < CC_MD5_DIGEST_LENGTH; count++){
        [key appendFormat:@"%02x", outputBuffer[count]];
    }
    return key;
}

typedef void(^HJFileProgressBlock)(NSProgress * _Nullable progress);

typedef void (^HJFileCompletionBlock)(HJFileStatus status, NSError *_Nullable error);

NS_ASSUME_NONNULL_BEGIN

@interface HJFileBasic : NSObject

/// 大小
@property (nonatomic, assign) NSUInteger size;
/// 状态
@property (nonatomic, assign) HJFileStatus status;
/// 进度
@property (nonatomic,   copy) HJFileProgressBlock progress;
/// 结果
@property (nonatomic,   copy) HJFileCompletionBlock completion;

@end

NS_ASSUME_NONNULL_END
