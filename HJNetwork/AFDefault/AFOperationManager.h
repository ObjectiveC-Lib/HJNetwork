//
//  AFOperationManager.h
//  HJNetwork
//
//  Created by navy on 2022/8/18.
//

#import "AFHTTPRequestOperationManager.h"

#if __has_include(<HJNetwork/HJNetworkPublic.h>)
#import <HJNetwork/HJNetworkPublic.h>
#elif __has_include("HJNetworkPublic.h")
#import "HJNetworkPublic.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@interface AFOperationManager : AFHTTPRequestOperationManager

+ (instancetype)manager:(nullable HJNetworkConfig *)config;

@end

NS_ASSUME_NONNULL_END
