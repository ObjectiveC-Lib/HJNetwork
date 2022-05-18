//
//  HJFileSource.h
//  HJNetworkDemo
//
//  Created by navy on 2022/9/5.
//

#import <Foundation/Foundation.h>
#import "HJUploadConfig.h"
#import "HJFileBasic.h"
#import "HJFileBlock.h"

NS_ASSUME_NONNULL_BEGIN

@interface HJFileSource : HJFileBasic

/// 文件资源ID
@property (nonatomic, retain) NSString *sourceId;
/// 该资源下的所有文件块
@property (nonatomic, retain) NSArray <HJFileBlock *> *blocks;

- (instancetype)initWithAbsolutePaths:(NSArray <NSString *>*)paths config:(HJUploadConfig *)config;

- (void)startWithBlock:(void (^)(HJFileFragment * _Nonnull fragment))block;
- (void)cancelWithBlock:(void (^)(HJFileFragment * _Nonnull fragment))block;

@end

NS_ASSUME_NONNULL_END
