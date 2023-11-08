//
//  HJUploadSource.h
//  HJNetwork
//
//  Created by navy on 2022/9/5.
//  Copyright © 2022 HJNetwork. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <HJTask/HJTask.h>
#import "HJUploadFileBlock.h"
#import "HJRequest.h"

NS_ASSUME_NONNULL_BEGIN

typedef NSString * _Nullable HJUploadSourceKey;
static const HJUploadSourceKey HJUploadSourceKeyInvalid = nil;

typedef  HJCoreRequest *(^HJUploadFragmentBlock)(HJUploadFileFragment * _Nonnull fragment);

@interface HJUploadSource : HJUploadFileBasic <HJTaskProtocol>

@property (nonatomic, copy, nullable) HJTaskKey taskKey;
/// 文件资源ID
@property (nonatomic, strong) NSString *sourceId;
/// 该资源下的所有文件块
@property (nonatomic, strong) NSArray <HJUploadFileBlock *> *blocks;

@property (nonatomic,   copy) HJUploadFragmentBlock uploadFragment;

- (instancetype)initWithAbsolutePaths:(NSArray <NSString *>*)paths config:(HJUploadConfig *)config;

@end

NS_ASSUME_NONNULL_END
