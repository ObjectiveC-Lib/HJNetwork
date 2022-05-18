//
//  HJChainRequestAgent.h
//  HJNetwork
//
//  Created by navy on 2018/7/5.
//  Copyright © 2018 HJNetwork. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class HJChainRequest;

@interface HJChainRequestAgent : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

+ (HJChainRequestAgent *)sharedAgent;

- (void)addChainRequest:(HJChainRequest *)request;
- (void)removeChainRequest:(HJChainRequest *)request;

@end

NS_ASSUME_NONNULL_END
