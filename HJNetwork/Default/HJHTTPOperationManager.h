//
//  HJHTTPOperationManager.h
//  HJNetwork
//
//  Created by navy on 2022/8/18.
//  Copyright © 2022 HJNetwork. All rights reserved.
//

#import "AFHTTPRequestOperationManager.h"

#if __has_include(<HJNetwork/AFURLConnection.h>)
#import <HJNetwork/AFURLConnection.h>
#elif __has_include("AFURLConnection.h")
#import "AFURLConnection.h"
#endif

#if __has_include(<HJNetwork/HJNetworkCommon.h>)
#import <HJNetwork/HJNetworkCommon.h>
#elif __has_include("HJNetworkCommon.h")
#import "HJNetworkCommon.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@interface HJHTTPOperationManager : AFHTTPRequestOperationManager

+ (instancetype)manager:(nullable HJNetworkConfig *)config;

@end

NS_ASSUME_NONNULL_END
