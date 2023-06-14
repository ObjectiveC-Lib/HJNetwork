//
//  HJRetryRequestManager.m
//  HJNetwork
//
//  Created by navy on 2023/6/13.
//  Copyright © 2023 HJNetwork. All rights reserved.

#import "HJRetryRequestManager.h"
#import "HJRetryRequestConfig.h"
#import <HJNetwork/HJNetworkCommon.h>

@implementation HJRetryRequestManager

+ (HJRetryRequestKey)request:(HJCoreRequest <HJTaskProtocol>*)request
                      config:(HJRetryRequestConfig *)config
             requestProgress:(void (^)(NSProgress * _Nullable progress))requestProgress
           requestCompletion:(void (^)(NSDictionary<NSString *, id> * _Nullable callbackInfo, NSError * _Nullable error))requestCompletion {
    if (!request || [request requestUrl].length <= 0) return HJRetryRequestKeyInvalid;
    if (!config) config = [HJRetryRequestConfig defaultConfig];
    
    HJRetryRequestSource *requestsSource = [[HJRetryRequestSource alloc] initWithRequestUrl:[request requestUrl]
                                                                                     config:config
                                                                            requestProgress:requestProgress
                                                                          requestCompletion:requestCompletion];
    [requestsSource startWithBlock:^(HJRetryRequestSource * _Nonnull source) {
        HJLog(@"HJRetryRequestSource_%@", source.sourceId);
        request.taskKey = source.sourceId;
        [[HJTaskManager sharedInstance] executor:request
                                        progress:^(HJTaskKey key, NSProgress * _Nullable taskProgress) {
            if (source.progress) {
                source.progress(taskProgress);
            }
        } completion:^(HJTaskKey key, HJTaskStage stage, NSDictionary<NSString *,id> * _Nullable callbackInfo, NSError * _Nullable error) {
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
    }];
    
    return requestsSource.sourceId;
}

+ (void)cancelRequest:(HJRetryRequestKey)key {
    [HJRetryRequestSource cancelWithKey:key block:^(HJRetryRequestSource * _Nonnull source) {
        [[HJTaskManager sharedInstance] cancelWithKey:source.sourceId];
    }];
}

@end
