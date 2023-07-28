//
//  HJBatchRequest.m
//  HJNetwork
//
//  Created by navy on 2018/7/5.
//  Copyright © 2018 HJNetwork. All rights reserved.
//

#import "HJBatchRequest.h"
#import "HJNetworkPrivate.h"
#import "HJBatchRequestAgent.h"
#import "HJBaseRequest.h"

@interface HJBatchRequest() <HJRequestDelegate>
@property (nonatomic) NSInteger finishedCount;
@property (nonatomic, strong, readwrite) NSMutableArray<HJBaseRequest *> *failedRequestArray;
@end


@implementation HJBatchRequest

- (instancetype)initWithRequestArray:(NSArray<HJBaseRequest *> *)requestArray {
    self = [super init];
    if (self) {
        _requestArray = [requestArray copy];
        _failedRequestArray = @[].mutableCopy;
        _finishedCount = 0;
        for (HJBaseRequest * req in _requestArray) {
            if (![req isKindOfClass:[HJBaseRequest class]]) {
                HJLog(nil, @"Error, request item must be HJBaseRequest instance.");
                return nil;
            }
        }
    }
    return self;
}

- (void)start {
    if (_finishedCount > 0) {
        HJLog(nil, @"Error! Batch request has already started.");
        return;
    }
    _failedRequest = nil;
    [[HJBatchRequestAgent sharedAgent] addBatchRequest:self];
    [self toggleAccessoriesWillStartCallBack];
    
    for (HJBaseRequest * req in _requestArray) {
        req.delegate = self;
        req.loadMore = self.loadMore;
        [req clearCompletionBlock];
        [req start];
    }
}

- (void)stop {
    [self toggleAccessoriesWillStopCallBack];
    _delegate = nil;
    self.loadMore = NO;
    [self clearRequest];
    [self toggleAccessoriesDidStopCallBack];
    [[HJBatchRequestAgent sharedAgent] removeBatchRequest:self];
}

- (void)startWithCompletionBlockWithSuccess:(void (^)(HJBatchRequest *batchRequest))success
                                    failure:(void (^)(HJBatchRequest *batchRequest))failure {
    [self startWithCompletionBlockWithSuccess:success
                                      failure:failure
                                     loadMore:NO];
}

- (void)startWithCompletionBlockWithSuccess:(void (^)(HJBatchRequest *batchRequest))success
                                    failure:(void (^)(HJBatchRequest *batchRequest))failure
                                   loadMore:(BOOL)loadMore {
    self.loadMore = loadMore;
    [self setCompletionBlockWithSuccess:success failure:failure];
    [self start];
}

- (void)setCompletionBlockWithSuccess:(void (^)(HJBatchRequest *batchRequest))success
                              failure:(void (^)(HJBatchRequest *batchRequest))failure {
    self.successCompletionBlock = success;
    self.failureCompletionBlock = failure;
}

- (void)clearCompletionBlock {
    // nil out to break the retain cycle.
    self.successCompletionBlock = nil;
    self.failureCompletionBlock = nil;
}

- (BOOL)isDataFromCache {
    BOOL result = YES;
    for (HJBaseRequest *request in _requestArray) {
        if (!request.isDataFromCache) {
            result = NO;
        }
    }
    return result;
}

- (void)dealloc {
    [self clearRequest];
}

#pragma mark - Network Request Delegate

- (void)requestFinished:(HJBaseRequest *)request {
    _finishedCount++;
    if (_finishedCount == _requestArray.count) {
        if (_failedRequestArray.count) {
            [self handleFailedRequest];
        } else {
            [self toggleAccessoriesWillStopCallBack];
            if ([_delegate respondsToSelector:@selector(batchRequestFinished:)]) {
                [_delegate batchRequestFinished:self];
            }
            if (_successCompletionBlock) {
                _successCompletionBlock(self);
            }
            [self clearCompletionBlock];
            [self toggleAccessoriesDidStopCallBack];
            [[HJBatchRequestAgent sharedAgent] removeBatchRequest:self];
        }
    }
}

- (void)requestFailed:(HJBaseRequest *)request {
    _finishedCount++;
    [_failedRequestArray addObject:request];
    if (!_failedRequest) {
        _failedRequest = request;
    }
    
    if (_finishedCount == _requestArray.count) {
        [self handleFailedRequest];
    }
}

- (void)clearRequest {
    for (HJBaseRequest * req in _requestArray) {
        [req stop];
    }
    [_failedRequestArray removeAllObjects];
    [self clearCompletionBlock];
}

#pragma mark - Request Accessoies

- (void)addAccessory:(id<HJRequestAccessory>)accessory {
    if (!self.requestAccessories) {
        self.requestAccessories = [NSMutableArray array];
    }
    [self.requestAccessories addObject:accessory];
}

#pragma mark - Private

- (void)handleFailedRequest {
    [self toggleAccessoriesWillStopCallBack];
    
    // Callback
    if ([_delegate respondsToSelector:@selector(batchRequestFailed:)]) {
        [_delegate batchRequestFailed:self];
    }
    if (_failureCompletionBlock) {
        _failureCompletionBlock(self);
    }
    
    // Clear
    [self clearCompletionBlock];
    
    [self toggleAccessoriesDidStopCallBack];
    [[HJBatchRequestAgent sharedAgent] removeBatchRequest:self];
}

@end
