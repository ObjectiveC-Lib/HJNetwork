//
//  HJRetryRequestManager.m
//  HJNetwork
//
//  Created by navy on 2023/6/13.
//  Copyright © 2023 HJNetwork. All rights reserved.

#import "HJRetryRequestManager.h"
#import <HJTask/HJTask.h>

@implementation HJRetryRequestManager

+ (HJRetryRequestKey)request:(HJCoreRequest *)request
                      config:(HJRetryRequestConfig *)config
             requestProgress:(void (^)(NSProgress * _Nullable progress))requestProgress
           requestCompletion:(void (^)(id _Nullable callbackInfo, NSError * _Nullable error))requestCompletion {
    if (!request || [request requestUrl].length <= 0) return HJRetryRequestKeyInvalid;
    if (!config) config = [HJRetryRequestConfig defaultConfig];
    
    HJRetryRequestSource *requestsSource = [[HJRetryRequestSource alloc] initWithRequest:request
                                                                                  config:config
                                                                         requestProgress:requestProgress
                                                                       requestCompletion:requestCompletion];
    
    [[HJTaskManager sharedInstance] executor:requestsSource
                                    progress:^(HJTaskKey key, NSProgress * _Nullable taskProgress) {
        if (requestsSource.progress) {
            requestsSource.progress(taskProgress);
        }
    } completion:^(HJTaskKey key, HJTaskStage stage, id _Nullable callbackInfo, NSError * _Nullable error) {
        HJRetryRequestStatus status = requestsSource.status;
        if (stage == HJTaskStageFinished) {
            status = error?HJRetryRequestStatusFailure:HJRetryRequestStatusSuccess;
        } else if (stage == HJTaskStageCancelled) {
            status = HJRetryRequestStatusCancel;
        }
        if (requestsSource.completion) {
            requestsSource.completion(status, callbackInfo, error);
        }
    }];
    
    return requestsSource.sourceId;
}

+ (void)cancelRequest:(HJRetryRequestKey)key {
    [[HJTaskManager sharedInstance] cancelWithKey:key];
}

@end
