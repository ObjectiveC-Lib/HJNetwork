//
//  HJRetryRequestSource.m
//  HJNetwork
//
//  Created by navy on 2023/6/13.
//  Copyright © 2023 HJNetwork. All rights reserved.

#import "HJRetryRequestSource.h"
#import <HJNetwork/HJNetworkCommon.h>
#import "HJRetryRequestSourceManager.h"

@interface HJRetryRequestSource ()
@property (nonatomic, strong) HJCoreRequest *request;
@property (nonatomic, strong) HJRetryRequestConfig *config;
@property (nonatomic, assign) NSUInteger failureRetryCount;
//@property (nonatomic,   copy) void (^startBlock)(HJRetryRequestSource *source);
@end

@implementation HJRetryRequestSource
@synthesize taskKey = _taskKey;

- (void)dealloc {
    HJLog(@"HJRetryRequestSource_%@: dealloc", self.sourceId);
}

- (instancetype)initWithRequest:(HJCoreRequest *)request
                         config:(HJRetryRequestConfig *)config
                requestProgress:(void (^)(NSProgress * _Nullable progress))requestProgress
              requestCompletion:(void (^)(id _Nullable callbackInfo, NSError * _Nullable error))requestCompletion {
    self = [super init];
    if (self) {
        self.config = config;
        self.request = request;
        self.status = HJRetryRequestStatusWaiting;
        self.sourceId = HJRetryRequestCreateId([request requestUrl]);
        self.taskKey = self.sourceId;
        self.failureRetryCount = config.retryCount;
        self.progress = ^(NSProgress * _Nullable progress) {
            dispatch_request_main_async_safe(^{
                if (requestProgress) {
                    requestProgress(progress);
                }
            });
        };
        self.completion = ^(HJRetryRequestStatus status, id _Nullable callbackInfo, NSError * _Nullable error) {
            dispatch_request_main_async_safe(^{
                if (requestCompletion) {
                    requestCompletion(callbackInfo, error);
                }
            });
        };
    }
    return self;
}

- (void)cancelRequest {
    if (self.request.executing) {
        [self.request stop];
    }
}

- (void)retryRequest {
    if (self.status == HJRetryRequestStatusFailure) {
        self.status = HJRetryRequestStatusProcessing;
        self.error = nil;
        [self startRequest];
    }
}

- (void)startRequest {
    __weak typeof(self) _self = self;
    self.request.resumableDownloadProgressBlock = ^(NSProgress * _Nonnull progress) {
        __strong typeof(_self) self = _self;
        if (self.taskProgress) {
            self.taskProgress(self.taskKey, progress);
        }
    };
    
    [self.request startWithCompletionBlockWithSuccess:^(__kindof HJCoreRequest * _Nonnull request) {
        __strong typeof(_self) self = _self;
        id responseObject = request.responseObject;
        [self setupCompletion:HJRetryRequestStatusSuccess callbackInfo:responseObject error:nil];
    } failure:^(__kindof HJCoreRequest * _Nonnull request) {
        __strong typeof(_self) self = _self;
        id responseObject = request.responseObject;
        HJRetryRequestStatus status = HJRetryRequestStatusFailure;
        if (self.status == HJRetryRequestStatusCancel) status = HJRetryRequestStatusCancel;
        [self setupCompletion:status callbackInfo:responseObject error:request.error];
    }];
}

- (void)setupCompletion:(HJRetryRequestStatus)status callbackInfo:(id)callbackInfo error:(NSError * _Nullable)error {
    self.status = status;
    self.error = error;
    self.callbackInfo = callbackInfo;
    
    if (self.error) {
        if (self.failureRetryCount == self.config.retryCount) {
            HJLog(@"HJRetryRequestSource_Original_result:\ncallbackInfo = %@\nerror = %@", self.callbackInfo, self.error);
        } else {
            HJLog(@"HJRetryRequestSource_Retry_result:\ncallbackInfo = %@,\nerror = %@", self.callbackInfo, self.error);
        }
    }
    
    if (self.config.retryEnable && self.error) {
        if (self.failureRetryCount > 0 && self.status == HJRetryRequestStatusFailure) {
            if (self.config.retryInterval) {
                __weak typeof(self) _self = self;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.config.retryInterval * NSEC_PER_SEC)), dispatch_get_global_queue(0, 0), ^{
                    __strong typeof(_self) self = _self;
                    if (!self) return;
                    [self retryRequest];
                    self.failureRetryCount -= 1;
                    HJLog(@"HJRetryRequestSource_retryCount = %lu", (self.config.retryCount - self.failureRetryCount));
                });
            } else {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [self retryRequest];
                    self.failureRetryCount -= 1;
                    HJLog(@"HJRetryRequestSource_retryCount = %lu", (self.config.retryCount - self.failureRetryCount));
                });
            }
            return;
        }
    }
    
    if (self.taskCompletion) {
        self.taskCompletion(self.taskKey, HJTaskStageFinished, self.callbackInfo, self.error);
    }
    [[HJRetryRequestSourceManager sharedManager] removeSource:self];
}

#pragma mark - HJTaskProtocol

- (BOOL)allowBackground {
    return YES;
}

- (void)setTaskKey:(HJTaskKey)taskKey {
    _taskKey = taskKey;
}

- (HJTaskKey)taskKey {
    return _taskKey;
}

- (void)startTask {
    [[HJRetryRequestSourceManager sharedManager] addSource:self];
    self.status = HJRetryRequestStatusProcessing;
    [self startRequest];
}

- (void)cancelTask {
    self.status = HJRetryRequestStatusCancel;
    [self cancelRequest];
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super init]) {
        self.sourceId = [coder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(sourceId))];
        self.status = [[coder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(status))] unsignedIntegerValue];
        self.callbackInfo = [coder decodeObjectOfClass:[NSObject class] forKey:NSStringFromSelector(@selector(callbackInfo))];
        self.error = [coder decodeObjectOfClass:[NSError class] forKey:NSStringFromSelector(@selector(error))];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.sourceId forKey:NSStringFromSelector(@selector(sourceId))];
    [coder encodeObject:[NSNumber numberWithUnsignedInteger:self.status] forKey:NSStringFromSelector(@selector(status))];
    [coder encodeObject:self.callbackInfo forKey:NSStringFromSelector(@selector(callbackInfo))];
    [coder encodeObject:self.error forKey:NSStringFromSelector(@selector(error))];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    HJRetryRequestSource *basic = [[self class] allocWithZone:zone];
    basic.sourceId = self.sourceId;
    basic.status = self.status;
    basic.callbackInfo = self.callbackInfo;
    basic.error = self.error;
    return basic;
}

@end
