//
//  UIView+HJUpload.h
//  HJUpload
//
//  Created by navy on 2019/3/13.
//  Copyright © 2019 navy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
#import <HJTask/HJTask.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (HJUpload)

- (void)hj_cancelUploadWithKey:(HJTaskKey)key;

#pragma mark - Image Upload

- (HJTaskKey)hj_upload:(nullable NSObject<HJTaskProtocol> *)upload
                 image:(nullable UIImage *)image
              progress:(nullable HJTaskProgressBlock)progress
            completion:(nullable HJTaskCompletionBlock)completion;

#pragma mark - Video Upload

- (HJTaskKey)hj_upload:(nullable NSObject<HJTaskProtocol> *)upload
                 video:(nullable PHAsset *)video
              progress:(nullable HJTaskProgressBlock)progress
            completion:(nullable HJTaskCompletionBlock)completion;

@end

NS_ASSUME_NONNULL_END
