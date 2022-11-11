//
//  HJUploadManager.m
//  HJNetworkDemo
//
//  Created by navy on 2023/1/3.
//

#import "HJUploadManager.h"
#import <HJTask/HJTask.h>
#import "HJUploadRequest.h"

@implementation HJUploadManager

+ (HJUploadSourceKey)uploadWithAbsolutePath:(NSString *)path
                             uploadProgress:(void (^)(NSProgress * _Nullable progress))uploadProgress
                                 completion:(void (^)(NSDictionary<NSString *,id> * _Nullable callbackInfo, NSError * _Nullable error))completion {
    if (path.length <= 0) return HJUploadSourceKeyInvalid;
    
    HJUploadConfig *config = [HJUploadConfig defaultConfig];
    config.failureRetryCount = 3;
    config.fragmentEnable = YES;
    config.fragmentMaxSize = 128*1024;
    
    HJUploadSource *source = [[HJUploadSource alloc] initWithAbsolutePaths:@[path] config:config];
    __weak typeof (source) _source = source;
    source.progress = ^(NSProgress * _Nullable progress) {
        NSLog(@"HJUploadSource_%@: %lld / %lld...%.0lf",
              _source.sourceId,
              progress.completedUnitCount,
              progress.totalUnitCount,
              progress.fractionCompleted * 100);
        if (uploadProgress) {
            uploadProgress(progress);
        }
    };
    source.completion = ^(HJUploadStatus status, NSDictionary<NSString *,id> * _Nullable callbackInfo, NSError * _Nullable error) {
        NSLog(@"HJUploadSource_%@: status = %lu callbackInfo = %@",
              _source.sourceId,
              (unsigned long)status,
              callbackInfo);
        if (error) {
            NSLog(@"HJUploadSource_%@: error = %@",
                  _source.sourceId,
                  error);
        }
        
        if (completion) {
            completion(callbackInfo, error);
        }
    };
    
    [source startWithBlock:^(HJUploadFileFragment * _Nonnull fragment) {
        NSLog(@"HJUploadSource_%@: index = %lu, %@",
              _source.sourceId,
              (unsigned long)fragment.index,
              fragment.block.name);
        
        HJUploadRequest *upload = [[HJUploadRequest alloc] initWithFragment:fragment];
        [[HJTaskManager sharedInstance] executor:upload
                                        progress:^(HJTaskKey key, NSProgress * _Nullable taskProgress) {
            if (fragment.progress) {
                fragment.progress(taskProgress);
            }
        } completion:^(HJTaskKey key,
                       HJTaskStage stage,
                       NSDictionary<NSString *, id> * _Nullable callbackInfo,
                       NSError * _Nullable error) {
            HJUploadStatus status = fragment.status;
            if (stage == HJTaskStageFinished) {
                status = error?HJUploadStatusFailure:HJUploadStatusSuccess;
            } else if (stage == HJTaskStageCancelled) {
                status = HJUploadStatusCancel;
            }
            if (fragment.completion) {
                fragment.completion(status, callbackInfo, error);
            }
        }];
    }];
    
    //        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
    //            [source cancelWithBlock:^(HJUploadFileFragment * _Nonnull fragment) {
    //                [[HJTaskManager sharedInstance] cancelWithKey:fragment.fragmentId];
    //            }];
    //        });
    
    return source.sourceId;
}

+ (void)cancelSource:(HJUploadSourceKey)key {
    [HJUploadSource cancelWithKey:key block:^(HJUploadFileFragment * _Nonnull fragment) {
        [[HJTaskManager sharedInstance] cancelWithKey:fragment.fragmentId];
    }];
}

@end
