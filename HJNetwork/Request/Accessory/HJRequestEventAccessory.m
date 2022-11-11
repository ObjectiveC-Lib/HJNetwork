//
//  HJRequestEventAccessory.m
//  HJNetwork
//
//  Created by navy on 2020/12/25.
//  Copyright © 2020 HJNetwork. All rights reserved.
//

#import "HJRequestEventAccessory.h"

@implementation HJRequestEventAccessory

- (void)requestWillStart:(id)request {
    if (self.willStartBlock != nil) {
        self.willStartBlock(request);
        self.willStartBlock = nil;
    }
}

- (void)requestWillStop:(id)request {
    if (self.willStopBlock != nil) {
        self.willStopBlock(request);
        self.willStopBlock = nil;
    }
}

- (void)requestDidStop:(id)request {
    if (self.didStopBlock != nil) {
        self.didStopBlock(request);
        self.didStopBlock = nil;
    }
}

@end

@implementation HJCoreRequest (HJRequestEventAccessory)

- (void)startWithWillStart:(nullable HJRequestCompletionBlock)willStart
                  willStop:(nullable HJRequestCompletionBlock)willStop
                   success:(nullable HJRequestCompletionBlock)success
                   failure:(nullable HJRequestCompletionBlock)failure
                   didStop:(nullable HJRequestCompletionBlock)didStop {
    HJRequestEventAccessory *accessory = [HJRequestEventAccessory new];
    accessory.willStartBlock = willStart;
    accessory.willStopBlock = willStop;
    accessory.didStopBlock = didStop;
    [self addAccessory:accessory];
    [self startWithCompletionBlockWithSuccess:success
                                      failure:failure];
}

@end

@implementation HJBatchRequest (HJRequestEventAccessory)

- (void)startWithWillStart:(nullable void (^)(HJBatchRequest *batchRequest))willStart
                  willStop:(nullable void (^)(HJBatchRequest *batchRequest))willStop
                   success:(nullable void (^)(HJBatchRequest *batchRequest))success
                   failure:(nullable void (^)(HJBatchRequest *batchRequest))failure
                   didStop:(nullable void (^)(HJBatchRequest *batchRequest))didStop {
    HJRequestEventAccessory *accessory = [HJRequestEventAccessory new];
    accessory.willStartBlock = willStart;
    accessory.willStopBlock = willStop;
    accessory.didStopBlock = didStop;
    [self addAccessory:accessory];
    [self startWithCompletionBlockWithSuccess:success
                                      failure:failure];
}

@end

