//
//  HJHTTPSessionManager.h
//  HJNetwork
//
//  Created by navy on 2022/8/9.
//  Copyright © 2022 HJNetwork. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import "HJNetworkCommon.h"
#import "HJProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface HJHTTPSessionManager : AFHTTPSessionManager

+ (instancetype)manager:(nullable HJNetworkConfig *)config;
+ (instancetype)protocolManager;
- (void)setupDefaultConfig;

@end

NS_ASSUME_NONNULL_END
