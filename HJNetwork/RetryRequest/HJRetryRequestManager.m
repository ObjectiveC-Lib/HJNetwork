//
//  HJRetryRequestManager.m
//  HJNetwork
//
//  Created by navy on 2023/6/13.
//  Copyright © 2023 HJNetwork. All rights reserved.

#import "HJRetryRequestManager.h"
#import <HJTask/HJTask.h>

@interface HJRetryTaskManager : HJTaskManager
+ (instancetype)sharedInstance;
@end

@implementation HJRetryTaskManager
+ (instancetype)sharedInstance {
    static dispatch_once_t once;
    static HJRetryTaskManager *sharedInstance;
    dispatch_once(&once, ^ {
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}
@end

@implementation HJRetryRequestManager

+ (HJRetryRequestKey)requestWithConfig:(HJRetryRequestConfig *)config
                          retryRequest:(HJCoreRequest *(^)(void))retryRequest
                       requestProgress:(void (^)(NSProgress *progress))requestProgress
                     requestCompletion:(void (^)(HJRetryRequestStatus status, id callbackInfo, NSError *error))requestCompletion {
    if (!config) config = [HJRetryRequestConfig defaultConfig];
    
    HJRetryRequestSource *source = [[HJRetryRequestSource alloc] initWithConfig:config];
    source.retryRequestBlock = retryRequest;
    source.progress = requestProgress;
    source.completion = requestCompletion;
    [[HJRetryTaskManager sharedInstance] executor:source
                                         progress:^(HJTaskKey key, NSProgress * _Nullable taskProgress) {
        if (source.progress) {
            source.progress(taskProgress);
        }
    } completion:^(HJTaskKey key, HJTaskStage stage, id _Nullable callbackInfo, NSError * _Nullable error) {
        HJRetryRequestStatus status = source.status;
        if (stage == HJTaskStageFinished) {
            status = error?HJRetryRequestStatusFailure:HJRetryRequestStatusSuccess;
        } else if (stage == HJTaskStageCancelled) {
            status = HJRetryRequestStatusCancel;
        }
        if (source.completion) {
            source.completion(status, callbackInfo, error);
        }
    }];
    
    return source.sourceId;
}

+ (void)cancelRequest:(HJRetryRequestKey)key {
    [[HJRetryTaskManager sharedInstance] cancelWithKey:key];
}

@end
