//
//  HJUploadConfig.h
//  HJNetwork
//
//  Created by navy on 2022/9/5.
//  Copyright © 2022 HJNetwork. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NSString * _Nullable HJUploadKey;
static const HJUploadKey HJUploadKeyInvalid = nil;
static const HJUploadKey HJUploadKeyDomainError = @"HJUploadKeyDomainError";

NS_ASSUME_NONNULL_BEGIN

/// 上传表单类型
typedef NS_ENUM(NSUInteger, HJUploadFormType) {
    HJUploadFormTypeData = 0,
    HJUploadFormTypeURL = 1,
    HJUploadFormTypeStream = 2,
};

@protocol HJUploadConfig <NSObject>
@optional
@property (nonatomic, assign) BOOL fragmentEnable;              // default: NO;
@property (nonatomic, assign) unsigned long long fragmentSize;  // default: 2MB=2*1024*1024Bytes;

@property (nonatomic, assign) BOOL retryEnable;                 // default: NO;
@property (nonatomic, assign) NSUInteger retryCount;            // default: 3;
@property (nonatomic, assign) NSUInteger retryInterval;         // default: 1s;

@property (nonatomic, assign) BOOL allowBackground;             // default: NO
@property (nonatomic, assign) NSInteger maxConcurrentCount;     // default: -1; no limit
@property (nonatomic, assign) HJUploadFormType formType;        // default: HJUploadFormTypeData;

@property (nonatomic, assign) BOOL cryptoEnable;                // default: NO;
@property (nonatomic, assign) unsigned long long bufferSize;    // default: 8KB=8*1024Bytes;

@property (nonatomic, strong) NSMutableDictionary *_Nullable payload; // custom information

- (unsigned long long)cryptoDataSize:(unsigned long long)size;
- (NSData *)cryptoData:(NSData *)data;
@end

@interface HJUploadConfig : NSObject <HJUploadConfig>
+ (instancetype)defaultConfig;
@end

@interface HJUploadConfig (Extension)
@end

NS_ASSUME_NONNULL_END
