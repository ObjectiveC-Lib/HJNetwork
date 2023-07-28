//
//  HJUploadManager.h
//  HJNetwork
//
//  Created by navy on 2023/7/28.
//  Copyright © 2023 HJNetwork. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HJUploadSource.h"

NS_ASSUME_NONNULL_BEGIN

@interface HJUploadManager : NSObject

+ (HJUploadSourceKey)uploadWithAbsolutePath:(NSString *)path
                                     config:(HJUploadConfig *_Nullable)config
                              uploadRequest:(HJCoreRequest *(^)(HJUploadFileFragment * _Nonnull fragment))uploadRequest
                             uploadProgress:(void (^)(NSProgress * _Nullable progress))uploadProgress
                           uploadCompletion:(void (^)(HJUploadStatus status, id _Nullable callbackInfo, NSError * _Nullable error))uploadCompletion;

+ (void)cancelUpload:(HJUploadSourceKey)key;

@end

NS_ASSUME_NONNULL_END
