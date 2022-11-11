//
//  HJNetworkAgent.h
//  HJNetwork
//
//  Created by navy on 2018/7/4.
//  Copyright © 2018 HJNetwork. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class HJCoreRequest;

@interface HJNetworkAgent : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

+ (HJNetworkAgent *)sharedAgent;

- (void)addRequest:(HJCoreRequest *)request;
- (void)cancelRequest:(HJCoreRequest *)request;
- (void)cancelAllRequests;

- (NSString *)buildRequestUrl:(HJCoreRequest *)request;

@end

NS_ASSUME_NONNULL_END
