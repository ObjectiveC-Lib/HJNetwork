//
//  AFSessionManager.h
//  HJNetwork
//
//  Created by navy on 2022/8/9.
//

#import <AFNetworking/AFNetworking.h>

#if __has_include(<HJNetwork/HJNetworkPublic.h>)
#import <HJNetwork/HJNetworkPublic.h>
#elif __has_include("HJNetworkPublic.h")
#import "HJNetworkPublic.h"
#endif

#if __has_include(<HJNetwork/HJProtocol.h>)
#import <HJNetwork/HJProtocol.h>
#elif __has_include("HJProtocol.h")
#import "HJProtocol.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@interface AFSessionManager : AFHTTPSessionManager

+ (instancetype)manager:(nullable HJNetworkConfig *)config;
+ (instancetype)protocolManager;

@end

NS_ASSUME_NONNULL_END
