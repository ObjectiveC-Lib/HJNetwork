//
//  HJChainRequest.m
//  HJNetwork
//
//  Created by navy on 2018/7/5.
//  Copyright © 2018 HJNetwork. All rights reserved.
//

#import "HJChainRequest.h"
#import "HJChainRequestAgent.h"
#import "HJNetworkPrivate.h"
#import "HJBaseRequest.h"

@interface HJChainRequest()<HJRequestDelegate>
@property (nonatomic, strong) NSMutableArray<HJBaseRequest *> *requestArray;
@property (nonatomic, assign) NSMutableArray<HJChainCallback> *requestCallbackArray;
@property (nonatomic, assign) NSUInteger nextRequestIndex;
@property (nonatomic, assign) HJChainCallback emptyCallback;
@end


@implementation HJChainRequest

- (instancetype)init {
    self = [super init];
    if (self) {
        _nextRequestIndex = 0;
        _requestArray = [NSMutableArray array];
        _requestCallbackArray = [NSMutableArray array];
        _emptyCallback = ^(HJChainRequest *chainRequest, HJBaseRequest *baseRequest) {
        };
    }
    return self;
}

- (void)start {
    if (_nextRequestIndex > 0) {
        HJLog(@"Error! Chain request has already started.");
        return;
    }
    
    if ([_requestArray count] > 0) {
        [self toggleAccessoriesWillStartCallBack];
        [self startNextRequest];
        [[HJChainRequestAgent sharedAgent] addChainRequest:self];
    } else {
        HJLog(@"Error! Chain request array is empty.");
    }
}

- (void)stop {
    [self toggleAccessoriesWillStopCallBack];
    [self clearRequest];
    [[HJChainRequestAgent sharedAgent] removeChainRequest:self];
    [self toggleAccessoriesDidStopCallBack];
}

- (void)addRequest:(HJBaseRequest *)request callback:(HJChainCallback)callback {
    [_requestArray addObject:request];
    if (callback != nil) {
        [_requestCallbackArray addObject:callback];
    } else {
        [_requestCallbackArray addObject:_emptyCallback];
    }
}

- (BOOL)startNextRequest {
    if (_nextRequestIndex < [_requestArray count]) {
        HJBaseRequest *request = _requestArray[_nextRequestIndex];
        _nextRequestIndex++;
        request.delegate = self;
        [request clearCompletionBlock];
        [request start];
        return YES;
    } else {
        return NO;
    }
}

#pragma mark - Network Request Delegate

- (void)requestFinished:(HJBaseRequest *)request {
    NSUInteger currentRequestIndex = _nextRequestIndex - 1;
    HJChainCallback callback = _requestCallbackArray[currentRequestIndex];
    callback(self, request);
    if (![self startNextRequest]) {
        [self toggleAccessoriesWillStopCallBack];
        if ([_delegate respondsToSelector:@selector(chainRequestFinished:)]) {
            [_delegate chainRequestFinished:self];
            [[HJChainRequestAgent sharedAgent] removeChainRequest:self];
        }
        [self toggleAccessoriesDidStopCallBack];
    }
}

- (void)requestFailed:(HJBaseRequest *)request {
    [self toggleAccessoriesWillStopCallBack];
    if ([_delegate respondsToSelector:@selector(chainRequestFailed:failedBaseRequest:)]) {
        [_delegate chainRequestFailed:self failedBaseRequest:request];
        [[HJChainRequestAgent sharedAgent] removeChainRequest:self];
    }
    [self toggleAccessoriesDidStopCallBack];
}

- (void)clearRequest {
    NSUInteger currentRequestIndex = _nextRequestIndex - 1;
    if (currentRequestIndex < [_requestArray count]) {
        HJBaseRequest *request = _requestArray[currentRequestIndex];
        [request stop];
    }
    [_requestArray removeAllObjects];
    [_requestCallbackArray removeAllObjects];
}

#pragma mark - Request Accessoies

- (void)addAccessory:(id<HJRequestAccessory>)accessory {
    if (!self.requestAccessories) {
        self.requestAccessories = [NSMutableArray array];
    }
    [self.requestAccessories addObject:accessory];
}

@end
