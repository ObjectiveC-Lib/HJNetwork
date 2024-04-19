//
//  HJUploadFileSource.h
//  HJNetwork
//
//  Created by navy on 2022/9/5.
//  Copyright © 2022 HJNetwork. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <HJTask/HJTask.h>
#import "HJRequest.h"
#import "HJUploadFileBlock.h"

NS_ASSUME_NONNULL_BEGIN

typedef NSDictionary * _Nullable (^HJUploadPreprocessBlock)(HJUploadFileBlock * _Nullable block);
typedef HJCoreRequest * _Nullable (^HJUploadRequestBlock)(HJUploadFileFragment * _Nullable fragment);

@interface HJUploadFileSource : HJUploadFileBasic <HJTaskProtocol>
/// 文件资源ID
@property (nonatomic, strong) NSString *sourceId;
/// 该资源下的所有文件块
@property (nonatomic, strong) NSArray <HJUploadFileBlock *> *blocks;

@property (nonatomic,   copy) HJUploadPreprocessBlock preprocess;

@property (nonatomic,   copy) HJUploadRequestBlock request;

@property (nonatomic, strong) id<HJUploadConfig> config;

- (instancetype)initWithFilePaths:(NSArray <NSString *>*)paths urls:(NSArray <NSString *>*)urls config:(id <HJUploadConfig>)config;

@end

NS_ASSUME_NONNULL_END
