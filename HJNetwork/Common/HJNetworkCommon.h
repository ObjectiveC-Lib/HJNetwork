//
//  HJNetworkCommon.h
//  HJNetwork
//
//  Created by navy on 2022/7/26.
//  Copyright © 2022 HJNetwork. All rights reserved.
//

#ifndef HJNetworkCommon_h
#define HJNetworkCommon_h

#if __has_include(<HJNetwork/HJNetworkCommon.h>)
#import <HJNetwork/HJCredentialChallenge.h>
#import <HJNetwork/HJDNSNode.h>
#import <HJNetwork/HJNetworkConfig.h>
#import <HJNetwork/HJNetworkMetrics.h>
#import <HJNetwork/HJFileManager.h>
#elif __has_include("HJNetworkCommon.h")
#import "HJCredentialChallenge.h"
#import "HJDNSNode.h"
#import "HJNetworkConfig.h"
#import "HJNetworkMetrics.h"
#import "HJFileManager.h"
#endif

#endif /* HJNetworkCommon_h */
