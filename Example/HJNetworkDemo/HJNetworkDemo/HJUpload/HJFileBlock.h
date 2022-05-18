//
//  HJFileBlock.h
//  HJNetworkDemo
//
//  Created by navy on 2022/9/2.
//

#import <Foundation/Foundation.h>
#import "HJFileBasic.h"
#import "HJFileFragment.h"

NS_ASSUME_NONNULL_BEGIN

@class HJFileSource;

@interface HJFileBlock : HJFileBasic
/// 文件块ID
@property (nonatomic, retain) NSString *blockId;
/// 文件名带后缀
@property (nonatomic, retain) NSString *name;
/// 文件相对路径
@property (nonatomic, retain) NSString *path;
/// 文件绝对路径
@property (nonatomic, retain) NSString *absolutePath;
/// 文件类型
@property (nonatomic, assign) HJFileType fileType;
/// 文件所在文件夹类型
@property (nonatomic, assign) HJDirectoryType dirType;
/// 分片数组
@property (nonatomic, retain) NSArray <HJFileFragment*> *fragments;
/// 该块所处的文件资源
@property (nonatomic,   weak) HJFileSource *source;

- (instancetype)initWithAbsolutePath:(NSString *)path config:(HJUploadConfig *)config;

@end

NS_ASSUME_NONNULL_END
