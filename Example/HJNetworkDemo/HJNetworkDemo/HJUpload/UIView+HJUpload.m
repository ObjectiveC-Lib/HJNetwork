//
//  UIView+HJUpload.m
//  HJUpload
//
//  Created by navy on 2019/3/13.
//  Copyright © 2019 navy. All rights reserved.
//

#import "UIView+HJUpload.h"
#import <objc/runtime.h>
#import <HJCache/HJCacheDefault.h>

// Use dummy class for category in static library.
// 减少 -all_load 或者 -force_load xxx在编译期间的耗时.
@interface UIView_HJUpload : NSObject @end
@implementation UIView_HJUpload @end

@implementation UIView (HJUpload)

#pragma mark - Attribute

- (void)hj_cancelUploadWithKey:(HJTaskKey)key {
    if (key == HJTaskKeyInvalid) return;
    
    [[HJTaskManager sharedInstance] cancelWithKey:key];
}

#pragma mark - Image Upload

- (HJTaskKey)hj_upload:(nullable NSObject<HJTaskProtocol> *)upload
                 image:(nullable UIImage *)image
              progress:(nullable HJTaskProgressBlock)progress
            completion:(nullable HJTaskCompletionBlock)completion {
    if (!image) return HJTaskKeyInvalid;
    
    HJTaskKey key = [[HJTaskManager sharedInstance] executor:upload
                                                   preHandle:^BOOL(HJTaskKey key) {
        [[HJImageCache sharedCache] setImage:image forKey:key];
        return YES;
    }
                                                    progress:progress
                                                  completion:^(HJTaskKey key, HJTaskStage stage, NSDictionary<NSString *,id> * _Nullable callbackInfo, NSError * _Nullable error) {
        [[HJImageCache sharedCache] removeImageForKey:key];
        if (completion) {
            completion(key, stage, callbackInfo, error);
        }
    }];
    return key;
}

#pragma mark - Video Upload

- (HJTaskKey)hj_upload:(nullable NSObject<HJTaskProtocol> *)upload
                 video:(nullable PHAsset *)video
              progress:(nullable HJTaskProgressBlock)progress
            completion:(nullable HJTaskCompletionBlock)completion {
    if (!video) return HJTaskKeyInvalid;
    
    HJTaskKey key = [[HJTaskManager sharedInstance] executor:upload
                                                   preHandle:^BOOL(HJTaskKey key) {
        [[HJVideoCache sharedCache] setVideo:video forKey:key];
        return YES;
    }
                                                    progress:progress
                                                  completion:^(HJTaskKey key, HJTaskStage stage, NSDictionary<NSString *,id> * _Nullable callbackInfo, NSError * _Nullable error) {
        [[HJVideoCache sharedCache] removeVideoForKey:key];
        if (completion) {
            completion(key, stage, callbackInfo, error);
        }
    }];
    return key;
}

@end
