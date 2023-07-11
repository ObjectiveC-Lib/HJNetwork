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

#if __has_include(<HJNetwork/AFURLConnection.h>)
#import <HJNetwork/AFURLConnection.h>
#endif

#if __has_include(<HJNetwork/HJNetworkCommon.h>)
#import <HJNetwork/HJNetworkCommon.h>
#endif

#if __has_include(<HJNetwork/HJDNSResolve.h>)
#import <HJNetwork/HJDNSResolve.h>
#endif

#if __has_include(<HJNetwork/HJProtocol.h>)
#import <HJNetwork/HJProtocol.h>
#endif

#if __has_include(<HJNetwork/HJHTTPDefault.h>)
#import <HJNetwork/HJHTTPDefault.h>
#endif

#if __has_include(<HJNetwork/HJRequest.h>)
#import <HJNetwork/HJRequest.h>
#endif

#if __has_include(<HJNetwork/HJDownload.h>)
#import <HJNetwork/HJDownload.h>
#endif

#if __has_include(<HJNetwork/HJUpload.h>)
#import <HJNetwork/HJUpload.h>
#endif

#if __has_include(<HJNetwork/HJRetryRequest.h>)
#import <HJNetwork/HJRetryRequest.h>
#endif

#endif /* _HJNetwork_ */
