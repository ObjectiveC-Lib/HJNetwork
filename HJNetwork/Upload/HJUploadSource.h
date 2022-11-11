//
//  HJUploadSource.h
//  HJNetwork
//
//  Created by navy on 2022/9/5.
//  Copyright © 2022 HJNetwork. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HJUploadConfig.h"
#import "HJUploadFileBasic.h"
#import "HJUploadFileBlock.h"

NS_ASSUME_NONNULL_BEGIN

typedef NSString * _Nullable HJUploadSourceKey;
static const HJUploadSourceKey HJUploadSourceKeyInvalid = nil;

@interface HJUploadSource : HJUploadFileBasic

/// 文件资源ID
@property (nonatomic, strong) NSString *sourceId;
/// 该资源下的所有文件块
@property (nonatomic, strong) NSArray <HJUploadFileBlock *> *blocks;

- (instancetype)initWithAbsolutePaths:(NSArray <NSString *>*)paths config:(HJUploadConfig *)config;

- (void)startWithBlock:(void (^)(HJUploadFileFragment * _Nonnull fragment))block;
- (void)cancelWithBlock:(void (^)(HJUploadFileFragment * _Nonnull fragment))block;

+ (void)cancelWithKey:(HJUploadSourceKey)key block:(void (^)(HJUploadFileFragment * _Nonnull fragment))block;

@end

NS_ASSUME_NONNULL_END
