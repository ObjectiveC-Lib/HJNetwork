//
//  HJUploadRequest.m
//  HJNetworkDemo
//
//  Created by navy on 2022/9/6.
//

#import "HJUploadRequest.h"

#if TARGET_OS_IOS || TARGET_OS_WATCH || TARGET_OS_TV
#import <MobileCoreServices/MobileCoreServices.h>
#else
#import <CoreServices/CoreServices.h>
#endif

static inline NSString * DMContentTypeForPathExtension(NSString *extension) {
    NSString *UTI = (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)extension, NULL);
    NSString *contentType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)UTI, kUTTagClassMIMEType);
    if (!contentType) {
        return @"application/octet-stream";
    } else {
        return contentType;
    }
}

@implementation HJUploadRequest {
    HJUploadFileFragment *_fragment;
}

- (instancetype)initWithFragment:(nullable HJUploadFileFragment *)fragment {
    self = [super init];
    if (self) {
        _fragment = fragment;
    }
    return self;
}

- (HJRequestMethod)requestMethod {
    return HJRequestMethodPOST;
}

- (NSString *)requestUrl {
    return @"anything";
}

- (AFConstructingBlock)constructingBodyBlock {
    return ^(id<AFMultipartFormData> formData) {
        NSData *data = [self->_fragment fetchData];
        NSString *name = self->_fragment.block.name;
        [formData appendPartWithFileData:data
                                    name:name
                                fileName:name
                                mimeType:DMContentTypeForPathExtension(self->_fragment.block.absolutePath)];
    };
}

#pragma mark - HJTaskProtocol

- (BOOL)allowBackground {
    return YES;
}

- (HJTaskKey)taskKey {
    return _fragment.fragmentId;
}

- (void)startTask {
    __weak typeof(self) _self = self;
    
    self.uploadProgressBlock = ^(NSProgress * _Nonnull progress) {
        __strong typeof(_self) self = _self;
        if (self.taskProgress) {
            self.taskProgress(self.taskKey, progress);
        }
    };
    
    [self startWithCompletionBlockWithSuccess:^(__kindof HJCoreRequest * _Nonnull request) {
        __strong typeof(_self) self = _self;
        if (self.taskCompletion) {
            self.taskCompletion(self.taskKey, HJTaskStageFinished, request.responseJSONObject, nil);
        }
    } failure:^(__kindof HJCoreRequest * _Nonnull request) {
        __strong typeof(_self) self = _self;
        if (self.taskCompletion) {
            self.taskCompletion(self.taskKey, HJTaskStageFinished, request.responseJSONObject, request.error);
        }
    }];
}

- (void)cancelTask {
    [self stop];
}

@end
