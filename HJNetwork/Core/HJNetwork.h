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

#if __has_include(<HJNetwork/HJNetworkPublic.h>)
#import <HJNetwork/HJNetworkPublic.h>
#elif __has_include("HJNetworkPublic.h")
#import "HJNetworkPublic.h"
#endif

#if __has_include(<HJNetwork/HJNetwork.h>)
#import <HJNetwork/HJRequest.h>
#import <HJNetwork/HJBatchRequest.h>
#import <HJNetwork/HJChainRequest.h>
#elif __has_include("HJNetwork.h")
#import "HJRequest.h"
#import "HJBatchRequest.h"
#import "HJChainRequest.h"
#endif

#if __has_include(<HJNetwork/HJNetworkAccessory.h>)
#import <HJNetwork/HJNetworkAccessory.h>
#elif __has_include("HJNetworkAccessory.h")
#import "HJNetworkAccessory.h"
#endif

#if __has_include(<HJNetwork/HJProtocol.h>)
#import <HJNetwork/HJProtocol.h>
#elif __has_include("HJProtocol.h")
#import "HJProtocol.h"
#endif

#if __has_include(<HJNetwork/AFURLConnection.h>)
#import <HJNetwork/AFURLConnection.h>
#elif __has_include("AFURLConnection.h")
#import "AFURLConnection.h"
#endif

#if __has_include(<HJNetwork/AFDefault.h>)
#import <HJNetwork/AFDefault.h>
#elif __has_include("AFDefault.h")
#import "AFDefault.h"
#endif

#endif /* _HJNetwork_ */
