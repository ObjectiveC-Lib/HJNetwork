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
/// 文件片的索引
@property (nonatomic, assign) NSUInteger index;
/// 文件片的偏移量
@property (nonatomic, assign) unsigned long long offset;
/// 文件只有一个fragment
@property (nonatomic, assign) BOOL isSingle;
/// 该片所处的文件块
@property (nonatomic,   weak) HJUploadFileBlock *block;

/// 获取片Data
- (NSData *)fetchData;
- (NSData *)fetchData:(NSUInteger)length offset:(unsigned long long)offset;
- (NSData *)cryptoData:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
