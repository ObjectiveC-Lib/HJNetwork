//
//  HJUploadManager.m
//  HJNetwork
//
//  Created by navy on 2023/7/28.
//  Copyright © 2023 HJNetwork. All rights reserved.
//

#import "HJUploadManager.h"

@implementation HJUploadManager

+ (HJUploadSourceKey)uploadWithAbsolutePath:(NSString *)path
                                     config:(HJUploadConfig *)config
                              uploadRequest:(HJCoreRequest *(^)(HJUploadFileFragment *fragment))uploadRequest
                             uploadProgress:(void (^)(NSProgress *progress))uploadProgress
                           uploadCompletion:(void (^)(HJUploadStatus status, id callbackInfo, NSError *error))uploadCompletion {
    if (!path || path.length < 0) return HJUploadSourceKeyInvalid;
    if (!config) config = [HJUploadConfig defaultConfig];
    
    HJUploadSource *source = [[HJUploadSource alloc] initWithAbsolutePaths:@[path] config:config];
    source.uploadFragment = uploadRequest;
    source.progress = uploadProgress;
    source.completion = uploadCompletion;
    [[HJTaskManager sharedInstance] executor:source
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
            source.completion(status, callbackInfo, error);
        }
    }];
    
    return source.sourceId;
}

+ (void)cancelUpload:(HJUploadSourceKey)key {
    [[HJTaskManager sharedInstance] cancelWithKey:key];
}

@end
