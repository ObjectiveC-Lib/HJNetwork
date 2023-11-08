//
//  HJHTTPOperationManager.h
//  HJNetwork
//
//  Created by navy on 2022/8/18.
//  Copyright © 2022 HJNetwork. All rights reserved.
//

#import "AFHTTPRequestOperationManager.h"
#import "HJNetworkCommon.h"
#import "AFURLConnection.h"

NS_ASSUME_NONNULL_BEGIN

@interface HJHTTPOperationManager : AFHTTPRequestOperationManager

+ (instancetype)manager:(nullable HJNetworkConfig *)config;
- (void)setupDefaultConfig;

@end

NS_ASSUME_NONNULL_END
