//
//  HJUploadManager.h
//  HJNetwork
//
//  Created by navy on 2023/7/28.
//  Copyright © 2023 HJNetwork. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HJUploadFileSource.h"

NS_ASSUME_NONNULL_BEGIN

@interface HJUploadManager : NSObject

+ (HJUploadKey)uploadWithFilePath:(NSString *)path
                              url:(NSString *_Nullable)url
                           config:(id <HJUploadConfig> _Nullable)config
                       preprocess:(HJUploadPreprocessBlock)preprocess
                    uploadRequest:(HJUploadRequestBlock)uploadRequest
                   uploadProgress:(HJUploadProgressBlock)uploadProgress
                 uploadCompletion:(HJUploadCompletionBlock)uploadCompletion;

+ (void)cancelUpload:(HJUploadKey)key;

+ (void)cancelAllUpload;

@end

NS_ASSUME_NONNULL_END
