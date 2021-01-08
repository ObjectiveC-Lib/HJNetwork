//
//  HJUpload.m
//  HJUpload
//
//  Created by navy on 2019/3/26.
//  Copyright © 2019 navy. All rights reserved.
//

#import "HJUpload.h"
#import <HJCache/HJCacheDefault.h>

@implementation HJUpload

+ (void)hj_removeMediaWithKey:(HJTaskKey)key {
    if (key == HJTaskKeyInvalid) return;
    
    [[HJImageCache sharedCache] removeImageForKey:key];
    [[HJVideoCache sharedCache] removeVideoForKey:key];
}

+ (void)hj_cancelUploadWithKey:(HJTaskKey)key {
    if (key == HJTaskKeyInvalid) return;
    
    [[HJTaskManager sharedInstance] cancelWithKey:key];
}

#pragma mark - Image Upload

+ (HJTaskKey)hj_upload:(nullable NSObject<HJTaskProtocol> *)upload
                 image:(nullable UIImage *)image
              progress:(nullable HJTaskProgressBlock)progress
            completion:(nullable HJTaskCompletionBlock)completion {
    if (!image || !upload) return HJTaskKeyInvalid;
    
    HJTaskKey key = [[HJTaskManager sharedInstance] executor:upload
                                                   preHandle:^BOOL(HJTaskKey key) {
        [[HJImageCache sharedCache] setImage:image forKey:key];
        return YES;
    }
                                                    progress:progress
                                                  completion:completion];
    return key;
}

#pragma mark - Video Upload

+ (HJTaskKey)hj_upload:(nullable NSObject<HJTaskProtocol> *)upload
                 video:(nullable PHAsset *)video
              progress:(nullable HJTaskProgressBlock)progress
            completion:(nullable HJTaskCompletionBlock)completion {
    if (!video || !upload) return HJTaskKeyInvalid;
    
    HJTaskKey key = [[HJTaskManager sharedInstance] executor:upload
                                                   preHandle:^BOOL(HJTaskKey key) {
        [[HJVideoCache sharedCache] setVideo:video forKey:key];
        return YES;
    }
                                                    progress:progress
                                                  completion:completion];
    return key;
}

@end
