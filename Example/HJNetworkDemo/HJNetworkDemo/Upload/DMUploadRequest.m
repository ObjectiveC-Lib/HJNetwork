//
//  DMUploadRequest.m
//  HJNetworkDemo
//
//  Created by navy on 2022/7/27.
//

#import "DMUploadRequest.h"

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

@implementation DMUploadRequest {
    NSString *_path;
}

- (void)dealloc {
    NSLog(@"DMUploadRequest dealloc");
}

- (instancetype)initWithPath:(nullable NSString *)path {
    self = [super init];
    if (self) {
        _path = path;
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
        NSURL *url = [NSURL URLWithString:self->_path];
        NSData *data = [NSData dataWithContentsOfFile:self->_path];
        NSString *name = [[url.lastPathComponent componentsSeparatedByString:@"."] objectAtIndex:0];
        [formData appendPartWithFileData:data
                                    name:name
                                fileName:name
                                mimeType:DMContentTypeForPathExtension(self->_path)];
    };
}

#pragma mark - HJTaskProtocol

- (BOOL)allowBackground {
    return YES;
}

- (HJTaskKey)taskKey {
    NSURL *url = [NSURL URLWithString:_path];
    NSString *name = [[url.lastPathComponent componentsSeparatedByString:@"."] objectAtIndex:0];
    return HJCreateTaskKey(name);
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
            self.taskCompletion(self.taskKey, HJTaskStageFinished, nil, request.error);
        }
    }];
}

- (void)cancelTask {
    [self stop];
}

@end
