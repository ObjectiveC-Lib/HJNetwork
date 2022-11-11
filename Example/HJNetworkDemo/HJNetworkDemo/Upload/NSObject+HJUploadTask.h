//
//  NSObject+HJUploadTask.h
//  HJUpload
//
//  Created by navy on 2019/3/13.
//  Copyright © 2019 navy. All rights reserved.
//

#import <HJTask/HJTask.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (HJUploadTask)

- (void)hj_cancelUploadWithKey:(HJTaskKey)key;

- (HJTaskKey)hj_upload:(nullable NSObject<HJTaskProtocol> *)upload
                  path:(nullable NSString *)path
              progress:(nullable HJTaskProgressBlock)progress
            completion:(nullable HJTaskCompletionBlock)completion;

@end

NS_ASSUME_NONNULL_END
