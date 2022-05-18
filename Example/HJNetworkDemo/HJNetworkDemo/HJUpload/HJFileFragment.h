//
//  HJFileFragment.h
//  HJNetworkDemo
//
//  Created by navy on 2022/9/2.
//

#import <Foundation/Foundation.h>
#import "HJFileBasic.h"

/// 每片大小 512k
#define HJFileFragmentMaxSize  512*1024

@class HJFileBlock;

NS_ASSUME_NONNULL_BEGIN

@interface HJFileFragment : HJFileBasic
/// 文件块ID
@property (nonatomic, retain) NSString *fragmentId;
/// 片的索引
@property (nonatomic, assign) NSUInteger index;
/// 片的偏移量
@property (nonatomic, assign) NSUInteger offset;
/// default: 512k=512*1024;
@property (nonatomic, assign) NSUInteger maxSize;
/// default: 0;
@property (nonatomic, assign) NSUInteger failureRetryCount;
/// 该片所处的文件块
@property (nonatomic,   weak) HJFileBlock *block;

/// 获取片Data
- (NSData *)fetchFragmentData;

@end

NS_ASSUME_NONNULL_END
