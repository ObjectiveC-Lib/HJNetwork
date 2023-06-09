//
//  HJHTTPSessionManager.h
//  HJNetwork
//
//  Created by navy on 2022/8/9.
//  Copyright © 2022 HJNetwork. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>

#if __has_include(<HJNetwork/HJNetworkCommon.h>)
#import <HJNetwork/HJNetworkCommon.h>
#elif __has_include("HJNetworkCommon.h")
#import "HJNetworkCommon.h"
#endif

#if __has_include(<HJNetwork/HJProtocol.h>)
#import <HJNetwork/HJProtocol.h>
#elif __has_include("HJProtocol.h")
#import "HJProtocol.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@interface HJHTTPSessionManager : AFHTTPSessionManager

+ (instancetype)manager:(nullable HJNetworkConfig *)config;
+ (instancetype)protocolManager;
- (void)setupDefaultConfig;

@end

NS_ASSUME_NONNULL_END
