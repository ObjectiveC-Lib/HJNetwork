//
//  HJUploadFileBasic.h
//  HJNetwork
//
//  Created by navy on 2022/9/7.
//  Copyright © 2022 HJNetwork. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>

#if TARGET_OS_IOS || TARGET_OS_WATCH || TARGET_OS_TV
#import <MobileCoreServices/MobileCoreServices.h>
#else
#import <CoreServices/CoreServices.h>
#endif

#import "HJUploadConfig.h"

typedef NS_ENUM(NSUInteger, HJDirectoryType) {
    HJDirectoryTypeNone = 0,
    HJDirectoryTypeDocument,
    HJDirectoryTypeLibrary,
    HJDirectoryTypeCaches,
    HJDirectoryTypeTemporary,
    HJDirectoryTypeMainBundle
};

/// 上传状态
typedef NS_ENUM(NSUInteger, HJUploadStatus) {
    HJUploadStatusWaiting = 0,    /// 准备
    HJUploadStatusProcessing = 1, /// 进行中
    HJUploadStatusSuccess = 2,    /// 成功
    HJUploadStatusFailure = 3,    /// 失败
    HJUploadStatusCancel = 4,     /// 取消
};

/// 文件类型
typedef NS_ENUM(NSInteger, HJFileType) {
    HJFileTypeUnknown = 0,
    HJFileTypeImage = 1,    /// 图片
    HJFileTypeVideo = 2,    /// 视频
    HJFileTypeAudio = 3,    /// 音频
};

static inline NSString * _Nullable HJUploadContentTypeForPathExtension(NSString * _Nullable extension) {
    NSString *UTI = (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)extension, NULL);
    NSString *contentType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)UTI, kUTTagClassMIMEType);
    if (!contentType) {
        return @"application/octet-stream";
    } else {
        return contentType;
    }
}

static inline NSString * _Nullable HJStringMD5String(NSString * _Nullable string) {
    if (!string) return nil;
    
    const char *value = [string UTF8String];
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

static inline CFStringRef _Nullable HJFileMD5CFString(CFStringRef _Nullable filePath, size_t bufferSize) {
    // Declare needed variables
    CFStringRef result = NULL;
    CFReadStreamRef readStream = NULL;
    // Get the file URL
    CFURLRef fileURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)filePath, kCFURLPOSIXPathStyle, (Boolean)false);
    if (!fileURL) {
        if (readStream) {
            CFReadStreamClose(readStream);
            CFRelease(readStream);
        }
        if (fileURL) {
            CFRelease(fileURL);
        }
        return result;
    }
    
    // Create and open the read stream
    readStream = CFReadStreamCreateWithFile(kCFAllocatorDefault, (CFURLRef)fileURL);
    if (!readStream) {
        if (readStream) {
            CFReadStreamClose(readStream);
            CFRelease(readStream);
        }
        if (fileURL) {
            CFRelease(fileURL);
        }
        return result;
    }
    
    bool didSucceed = (bool)CFReadStreamOpen(readStream);
    if (!didSucceed) {
        if (readStream) {
            CFReadStreamClose(readStream);
            CFRelease(readStream);
        }
        if (fileURL) {
            CFRelease(fileURL);
        }
        return result;
    }
    
    // Initialize the hash object
    CC_MD5_CTX hashObject;
    CC_MD5_Init(&hashObject);
    
    // Feed the data to the hash object
    bool hasMoreData = true;
    while (hasMoreData) {
        uint8_t buffer[bufferSize];
        CFIndex readBytesCount = CFReadStreamRead(readStream, (UInt8 *)buffer, (CFIndex)sizeof(buffer));
        if (readBytesCount == -1) break;
        if (readBytesCount == 0) {
            hasMoreData = false;
            continue;
        }
        CC_MD5_Update(&hashObject, (const void *)buffer, (CC_LONG)readBytesCount);
    }
    
    // Check if the read operation succeeded
    didSucceed = !hasMoreData;
    // Compute the hash digest
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5_Final(digest, &hashObject);
    // Abort if the read operation failed
    if (!didSucceed) {
        if (readStream) {
            CFReadStreamClose(readStream);
            CFRelease(readStream);
        }
        if (fileURL) {
            CFRelease(fileURL);
        }
        return result;
    }
    
    // Compute the string result
    char hash[2 * sizeof(digest) + 1];
    for (size_t i = 0; i < sizeof(digest); ++i) {
        snprintf(hash + (2 * i), 3, "%02x", (int)(digest[i]));
    }
    result = CFStringCreateWithCString(kCFAllocatorDefault, (const char *)hash, kCFStringEncodingUTF8);
    
    if (readStream) {
        CFReadStreamClose(readStream);
        CFRelease(readStream);
    }
    if (fileURL) {
        CFRelease(fileURL);
    }
    return result;
}

static inline NSString * _Nullable HJFileMD5String(NSString *_Nullable filePath, NSInteger bufferSize) {
    if (!filePath) return nil;
    return (__bridge_transfer NSString *)HJFileMD5CFString((__bridge CFStringRef)filePath, bufferSize);
}

static inline NSString * _Nullable HJFileCreateId(NSString * _Nullable identifier) {
    if (identifier == nil || [identifier length] <= 0) return nil;
    
    identifier = [identifier stringByAppendingString:[NSString stringWithFormat:@"%ld", (long)[[NSDate date] timeIntervalSince1970]]];
    identifier = [identifier stringByAppendingString:[NSString stringWithFormat:@"%d",arc4random()%10000]];
    
    return HJStringMD5String(identifier);
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

typedef void (^HJUploadProgressBlock)(NSProgress * _Nullable progress);
typedef void (^HJUploadCompletionBlock)(HJUploadStatus status, HJUploadKey key, id _Nullable callbackInfo, NSError *_Nullable error);

NS_ASSUME_NONNULL_BEGIN

@interface HJUploadFileBasic : NSObject <NSSecureCoding, NSCopying>
/// 文件只有一个fragment
@property (nonatomic, assign) BOOL isSingle;
/// 是否加密
@property (nonatomic, assign) BOOL cryptoEnable;
/// 原始大小
@property (nonatomic, assign) unsigned long long size;
/// 加密后大小
@property (nonatomic, assign) unsigned long long cryptoSize;
/// Buffer Size
@property (nonatomic, assign) unsigned long long bufferSize;
/// MD5
@property (nonatomic, strong) NSString *MD5;
/// 加密后MD5
@property (nonatomic, strong) NSString *cryptoMD5;
/// 上传url
@property (nonatomic, strong) NSString *requestUrl;
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
