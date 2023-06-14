//
//  HJRetryRequestSource.m
//  HJNetwork
//
//  Created by navy on 2023/6/13.
//  Copyright © 2023 HJNetwork. All rights reserved.

#import "HJRetryRequestSource.h"
#import <HJNetwork/HJNetworkCommon.h>
#import "HJRetryRequestConfig.h"
#import "HJRetryRequestSourceManager.h"

@interface HJRetryRequestSource ()
@property (nonatomic, strong) NSString *requestUrl;
@property (nonatomic, strong) HJRetryRequestConfig *config;
@property (nonatomic, assign) NSUInteger failureRetryCount;
@property (nonatomic,   copy) void (^startBlock)(HJRetryRequestSource *source);
@property (nonatomic,   copy) void (^requestProgress)(NSProgress * _Nullable progress);
@property (nonatomic,   copy) void (^requestCompletion)(NSDictionary<NSString *,id> * _Nullable callbackInfo, NSError * _Nullable error);
@end

@implementation HJRetryRequestSource

- (void)dealloc {
    HJLog(@"HJRetryRequestSource_%@: dealloc", self.sourceId);
}

- (instancetype)initWithRequestUrl:(NSString *)requestUrl
                            config:(HJRetryRequestConfig *)config
                   requestProgress:(void (^)(NSProgress * _Nullable progress))requestProgress
                 requestCompletion:(void (^)(NSDictionary<NSString *,id> * _Nullable callbackInfo, NSError * _Nullable error))requestCompletion {
    self = [super init];
    if (self) {
        self.config = config;
        self.requestUrl = requestUrl;
        self.status = HJRetryRequestStatusWaiting;
        self.sourceId = HJRetryRequestCreateId(requestUrl);
        self.failureRetryCount = config.retryCount;
        self.requestProgress = requestProgress;
        self.requestCompletion = requestCompletion;
        __weak typeof(self) weakself = self;
        self.progress = ^(NSProgress * _Nullable progress) {
            [weakself setupProgress:progress];
        };
        self.completion = ^(HJRetryRequestStatus status, NSDictionary<NSString *,id> * _Nullable callbackInfo, NSError * _Nullable error) {
            [weakself setupCompletion:status callbackInfo:callbackInfo error:error];
        };
    }
    return self;
}

- (void)startWithBlock:(void (^)(HJRetryRequestSource *source))block {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[HJRetryRequestSourceManager sharedManager] addSource:self];
        
        self.startBlock = block;
        self.status = HJRetryRequestStatusProcessing;
        if (self.startBlock) {
            self.startBlock(self);
        }
    });
}

- (void)retry {
    if (self.status == HJRetryRequestStatusFailure) {
        self.status = HJRetryRequestStatusProcessing;
        self.error = nil;
        if (self.startBlock) {
            self.startBlock(self);
        }
    }
}

- (void)cancelWithBlock:(void (^)(HJRetryRequestSource *source))cancelBlock {
    if (self.status == HJRetryRequestStatusProcessing) {
        if (cancelBlock) {
            cancelBlock(self);
        }
    }
}

+ (void)cancelWithKey:(HJRetryRequestKey)key block:(void (^)(HJRetryRequestSource *source))block {
    HJRetryRequestSource *source = [[HJRetryRequestSourceManager sharedManager] getSource:key];
    if (source) {
        [source cancelWithBlock:block];
    }
}

- (void)setupProgress:(NSProgress *)progress {
    dispatch_request_main_async_safe(^{
        if (self.requestProgress) {
            self.requestProgress(progress);
        }
    });
}

- (void)setupCompletion:(HJRetryRequestStatus)status callbackInfo:(NSDictionary<NSString *,id> * _Nullable)callbackInfo error:(NSError * _Nullable)error {
    self.status = status;
    self.error = error;
    self.callbackInfo = callbackInfo.mutableCopy;
    
    if (self.error) {
        if (self.failureRetryCount == self.config.retryCount) {
            HJLog(@"HJRetryRequestSource_Original_result = callbackInfo = %@, error = %@ \n", self.callbackInfo, self.error);
        } else {
            HJLog(@"HJRetryRequestSource_Retry_result = callbackInfo = %@, error = %@ \n", self.callbackInfo, self.error);
        }
    }
    
    if (self.config.retryEnable && self.error) {
        if (self.failureRetryCount > 0 && self.status == HJRetryRequestStatusFailure) {
            if (self.config.retryInterval) {
                __weak typeof(self) _self = self;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.config.retryInterval * NSEC_PER_SEC)), dispatch_get_global_queue(0, 0), ^{
                    __strong typeof(_self) self = _self;
                    if (!self) return;
                    [self retry];
                    self.failureRetryCount -= 1;
                    HJLog(@"HJRetryRequestSource_retryCount = %lu", (self.config.retryCount - self.failureRetryCount));
                });
            } else {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [self retry];
                    self.failureRetryCount -= 1;
                    HJLog(@"HJRetryRequestSource_retryCount = %lu", (self.config.retryCount - self.failureRetryCount));
                });
            }
            return;
        }
    }
    
    dispatch_request_main_async_safe(^{
        if (self.requestCompletion) {
            self.requestCompletion(self.callbackInfo, self.error);
        }
    });
    [[HJRetryRequestSourceManager sharedManager] removeSource:self];
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super init]) {
        self.sourceId = [coder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(sourceId))];
        self.status = [[coder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(status))] unsignedIntegerValue];
        self.callbackInfo = [coder decodeObjectOfClass:[NSMutableDictionary class] forKey:NSStringFromSelector(@selector(callbackInfo))];
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
