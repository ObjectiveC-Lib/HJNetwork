//
//  HJUploadFileBlock.h
//  HJNetwork
//
//  Created by navy on 2022/9/2.
//  Copyright © 2022 HJNetwork. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HJUploadFileBasic.h"
#import "HJUploadFileFragment.h"

NS_ASSUME_NONNULL_BEGIN

@class HJUploadFileSource;

@interface HJUploadFileBlock : HJUploadFileBasic
/// 文件块ID
@property (nonatomic, strong) NSString *blockId;
/// 文件名带后缀
@property (nonatomic, strong) NSString *name;
/// 文件原始路径
@property (nonatomic, strong) NSString *originalPath;
/// 文件相对路径
@property (nonatomic, strong) NSString *path;
/// 文件绝对路径
@property (nonatomic, strong) NSString *absolutePath;
/// 文件绝对路径URL
@property (nonatomic, strong) NSURL *absolutePathURL;
/// 文件类型
@property (nonatomic, assign) HJFileType fileType;
/// 文件所在文件夹类型
@property (nonatomic, assign) HJDirectoryType dirType;
/// 分片数组
@property (nonatomic, strong) NSArray <HJUploadFileFragment*> *fragments;
/// 该块所处的文件资源
@property (nonatomic,   weak) HJUploadFileSource *source;

@property (nonatomic, strong) id<HJUploadConfig> config;

- (instancetype)initWithAbsolutePath:(NSString *)path config:(id <HJUploadConfig>)config;

@end

NS_ASSUME_NONNULL_END
