//
//  HJRetryCommonRequest.m
//  HJNetwork
//
//  Created by navy on 2023/6/14.
//  Copyright © 2023 HJNetwork. All rights reserved.

#import "HJRetryCommonRequest.h"

@implementation HJRetryCommonRequest {
    NSString *_requestUrl;
    id _requestArgument;
    NSDictionary *_headerField;
    HJRequestMethod _requestMethod;
    HJRequestSerializerType _requestSerializerType;
    HJResponseSerializerType _responseSerializerType;
}
@synthesize taskKey = _taskKey;

- (instancetype)initWithUrl:(NSString *)requestUrl
            requestArgument:(id)requestArgument
                headerField:(NSDictionary *)headerField
              requestMethod:(HJRequestMethod)requestMethod
      requestSerializerType:(HJRequestSerializerType)requestSerializerType
     responseSerializerType:(HJResponseSerializerType)responseSerializerType {
    self = [super init];
    if (self) {
        _requestUrl = requestUrl;
        _requestMethod = requestMethod;
        _requestSerializerType = requestSerializerType;
        _responseSerializerType = responseSerializerType;
    }
    return self;
}

- (HJRequestMethod)requestMethod {
    return _requestMethod;
}

- (HJRequestSerializerType)requestSerializerType {
    return _requestSerializerType;
}

- (HJResponseSerializerType)responseSerializerType {
    return _responseSerializerType;
}

- (NSString *)requestUrl {
    return _requestUrl;
}

- (nullable id)requestArgument {
    return _requestArgument;
}

- (NSDictionary *)requestHeaderFieldValueDictionary {
    NSMutableDictionary *tmpDict = [NSMutableDictionary new];
    NSDictionary *dict = [super requestHeaderFieldValueDictionary];
    if (dict && dict.count) {
        [tmpDict addEntriesFromDictionary:dict];
    }
    if (_headerField && _headerField.count) {
        [tmpDict addEntriesFromDictionary:_headerField];
    }
    return tmpDict.copy;
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
    __weak typeof(self) _self = self;
    
    self.resumableDownloadProgressBlock = ^(NSProgress * _Nonnull progress) {
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
