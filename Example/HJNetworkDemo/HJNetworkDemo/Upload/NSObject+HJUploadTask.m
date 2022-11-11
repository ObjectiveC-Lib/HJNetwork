//
//  NSObject+HJUploadTask.m
//  HJUpload
//
//  Created by navy on 2019/3/13.
//  Copyright © 2019 navy. All rights reserved.
//

#import "NSObject+HJUploadTask.h"
#import "DMUploadRequest.h"

@interface NSObject_HJUploadTask : NSObject @end
@implementation NSObject_HJUploadTask @end

@implementation NSObject (HJUploadTask)

- (void)hj_cancelUploadWithKey:(HJTaskKey)key {
    if (key == HJTaskKeyInvalid) return;
    
    [[HJTaskManager sharedInstance] cancelWithKey:key];
}

- (HJTaskKey)hj_upload:(nullable NSObject<HJTaskProtocol> *)upload
                  path:(nullable NSString *)path
              progress:(nullable HJTaskProgressBlock)progress
            completion:(nullable HJTaskCompletionBlock)completion {
    if (!path) return HJTaskKeyInvalid;
    
    if (!upload) {
        upload = [[DMUploadRequest alloc] initWithPath:path];
    }
    HJTaskKey key = [[HJTaskManager sharedInstance] executor:upload
                                                    progress:progress
                                                  completion:completion];
    return key;
}

@end
