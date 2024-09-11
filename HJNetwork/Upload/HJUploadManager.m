//
//  HJUploadManager.m
//  HJNetwork
//
//  Created by navy on 2023/7/28.
//  Copyright © 2023 HJNetwork. All rights reserved.
//

#import "HJUploadManager.h"
#import <HJTask/HJTask.h>

@interface HJUploadTaskManager : HJTaskManager
+ (instancetype)sharedManager;
@end

@implementation HJUploadTaskManager
+ (instancetype)sharedManager {
    static id instance = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^ {
        instance = [[self alloc] init];
    });
    return instance;
}
@end

@implementation HJUploadManager

+ (HJUploadKey)uploadWithFilePath:(NSString *)path
                              url:(NSString *)url
                           config:(id <HJUploadConfig>)config
                       preprocess:(HJUploadPreprocessBlock)preprocess
                    uploadRequest:(HJUploadRequestBlock)uploadRequest
                   uploadProgress:(HJUploadProgressBlock)uploadProgress
                 uploadCompletion:(HJUploadCompletionBlock)uploadCompletion {
    if (!path || path.length < 0) return HJUploadKeyInvalid;
    if (!config) config = [HJUploadConfig defaultConfig];
    
    HJUploadFileSource *source = [[HJUploadFileSource alloc] initWithFilePaths:@[path] urls:url?@[url]:@[] config:config];
    source.preprocess = preprocess;
    source.request = uploadRequest;
    source.progress = uploadProgress;
    source.completion = uploadCompletion;
    [[HJUploadTaskManager sharedManager] executor:source
                                         progress:^(HJTaskKey key, NSProgress * _Nullable taskProgress) {
        if (source.progress) {
            source.progress(taskProgress);
        }
    } completion:^(HJTaskKey key, HJTaskStage stage, id _Nullable callbackInfo, NSError * _Nullable error) {
        HJUploadStatus status = source.status;
        if (stage == HJTaskStageFinished) {
            status = error?HJUploadStatusFailure:HJUploadStatusSuccess;
        } else if (stage == HJTaskStageCancelled) {
            status = HJUploadStatusCancel;
        }
        if (source.completion) {
            source.completion(status, key, callbackInfo, error);
        }
    }];
    
    return source.sourceId;
}

+ (void)cancelUpload:(HJUploadKey)key {
    [[HJUploadTaskManager sharedManager] cancelWithKey:key];
}

+ (void)cancelAllUpload {
    [[HJUploadTaskManager sharedManager] cancelAll];
}

@end
