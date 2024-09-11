//
//  HJNetworkAgent.h
//  HJNetwork
//
//  Created by navy on 2018/7/4.
//  Copyright © 2018 HJNetwork. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HJNetworkConfig.h"

NS_ASSUME_NONNULL_BEGIN

@class HJCoreRequest;

@protocol HJNetworkAgent <NSObject>
@optional
+ (instancetype)sharedAgent;
@end

@interface HJNetworkAgent : NSObject <HJNetworkAgent>

@property (nonatomic, strong, readonly) HJNetworkConfig *config;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
+ (instancetype)agentWithConfig:(HJNetworkConfig *_Nullable)config;

- (void)addRequest:(HJCoreRequest *)request;
- (void)cancelRequest:(HJCoreRequest *)request;
- (void)cancelAllRequests;

- (NSString *)buildRequestUrl:(HJCoreRequest *)request;

@end

NS_ASSUME_NONNULL_END
