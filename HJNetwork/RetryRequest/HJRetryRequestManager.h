//
//  HJRetryRequestManager.h
//  HJNetwork
//
//  Created by navy on 2023/6/13.
//  Copyright © 2023 HJNetwork. All rights reserved.

#import <Foundation/Foundation.h>
#import "HJRetryRequestSource.h"

NS_ASSUME_NONNULL_BEGIN

@interface HJRetryRequestManager : NSObject

+ (HJRetryRequestKey)request:(HJCoreRequest *)request
                      config:(HJRetryRequestConfig * _Nullable)config
             requestProgress:(void (^)(NSProgress * _Nullable progress))requestProgress
           requestCompletion:(void (^)(id _Nullable callbackInfo, NSError * _Nullable error))requestCompletion;

+ (void)cancelRequest:(HJRetryRequestKey)key;

@end

NS_ASSUME_NONNULL_END
