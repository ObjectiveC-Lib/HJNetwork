//
//  NSObject+HJUpload.m
//  HJUpload
//
//  Created by navy on 2019/3/13.
//  Copyright © 2019 navy. All rights reserved.
//

#import "NSObject+HJUpload.h"
#import "DMUploadRequest.h"

// Use dummy class for category in static library.
// 减少 -all_load 或者 -force_load xxx在编译期间的耗时.
@interface NSObject_HJUpload : NSObject @end
@implementation NSObject_HJUpload @end

@implementation NSObject (HJUpload)

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
