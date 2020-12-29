//
//  HJNetwork.h
//  HJNetwork
//
//  Created by navy on 2018/7/5.
//  Copyright © 2018 HJNetwork. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifndef _HJNetwork_
#define _HJNetwork_

FOUNDATION_EXPORT double HJNetworkVersionNumber;
FOUNDATION_EXPORT const unsigned char HJNetworkVersionString[];

#if __has_include(<AFNetworking/AFNetworking.h>)
#import <AFNetworking/AFNetworking.h>
#elif __has_include("AFNetworking.h")
#import "AFNetworking.h"
#endif

#if __has_include(<HJNetwork/HJNetwork.h>)

#import <HJNetwork/HJRequest.h>
#import <HJNetwork/HJBaseRequest.h>
#import <HJNetwork/HJNetworkAgent.h>
#import <HJNetwork/HJBatchRequest.h>
#import <HJNetwork/HJBatchRequestAgent.h>
#import <HJNetwork/HJChainRequest.h>
#import <HJNetwork/HJChainRequestAgent.h>
#import <HJNetwork/HJNetworkConfig.h>
// Accessory
#import <HJNetwork/HJRequestAccessory.h>
#import <HJNetwork/HJBaseRequest+Accessory.h>
#import <HJNetwork/HJBatchRequest+Accessory.h>
#import <HJNetwork/HJChainRequest+Accessory.h>
#import <HJNetwork/HJRequestEventAccessory.h>

#else /* __has_include */

#import "HJRequest.h"
#import "HJBaseRequest.h"
#import "HJNetworkAgent.h"
#import "HJBatchRequest.h"
#import "HJBatchRequestAgent.h"
#import "HJChainRequest.h"
#import "HJChainRequestAgent.h"
#import "HJNetworkConfig.h"
// Accessory
#import "HJRequestAccessory.h"
#import "HJBaseRequest+Accessory.h"
#import "HJBatchRequest+Accessory.h"
#import "HJChainRequest+Accessory.h"
#import "HJRequestEventAccessory.h"

#endif /* __has_include */

#endif /* _HJNetwork_ */
// 3.0.4
