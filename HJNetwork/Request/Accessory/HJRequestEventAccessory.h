//
//  HJRequestEventAccessory.h
//  HJNetwork
//
//  Created by navy on 2020/12/25.
//  Copyright © 2020 HJNetwork. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HJCoreRequest.h"
#import "HJBatchRequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface HJRequestEventAccessory : NSObject <HJRequestAccessory>

@property (nonatomic, copy, nullable) void (^willStartBlock)(id);
@property (nonatomic, copy, nullable) void (^willStopBlock)(id);
@property (nonatomic, copy, nullable) void (^didStopBlock)(id);

@end

@interface HJCoreRequest (HJRequestEventAccessory)

- (void)startWithWillStart:(nullable HJRequestCompletionBlock)willStart
                  willStop:(nullable HJRequestCompletionBlock)willStop
                   success:(nullable HJRequestCompletionBlock)success
                   failure:(nullable HJRequestCompletionBlock)failure
                   didStop:(nullable HJRequestCompletionBlock)didStop;

@end

@interface HJBatchRequest (HJRequestEventAccessory)

- (void)startWithWillStart:(nullable void (^)(HJBatchRequest *batchRequest))willStart
                  willStop:(nullable void (^)(HJBatchRequest *batchRequest))willStop
                   success:(nullable void (^)(HJBatchRequest *batchRequest))success
                   failure:(nullable void (^)(HJBatchRequest *batchRequest))failure
                   didStop:(nullable void (^)(HJBatchRequest *batchRequest))didStop;

@end

NS_ASSUME_NONNULL_END
