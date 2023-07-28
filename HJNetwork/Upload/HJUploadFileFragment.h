//
//  HJUploadFileFragment.h
//  HJNetwork
//
//  Created by navy on 2022/9/2.
//  Copyright © 2022 HJNetwork. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HJUploadFileBasic.h"

@class HJUploadFileBlock;

NS_ASSUME_NONNULL_BEGIN

@interface HJUploadFileFragment : HJUploadFileBasic
/// 文件片ID
@property (nonatomic, strong) NSString *fragmentId;
/// 片的索引
@property (nonatomic, assign) NSUInteger index;
/// 片的偏移量
@property (nonatomic, assign) NSUInteger offset;
/// 该片所处的文件块
@property (nonatomic,   weak) HJUploadFileBlock *block;

/// 获取片Data
- (NSData *)fetchData;
/// MD5
- (NSString *)md5;

@end

NS_ASSUME_NONNULL_END
