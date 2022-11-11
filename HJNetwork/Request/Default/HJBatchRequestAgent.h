//
//  HJBatchRequestAgent.h
//  HJNetwork
//
//  Created by navy on 2018/7/5.
//  Copyright © 2018 HJNetwork. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class HJBatchRequest;

@interface HJBatchRequestAgent : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

+ (HJBatchRequestAgent *)sharedAgent;

- (void)addBatchRequest:(HJBatchRequest *)request;
- (void)removeBatchRequest:(HJBatchRequest *)request;

@end

NS_ASSUME_NONNULL_END
