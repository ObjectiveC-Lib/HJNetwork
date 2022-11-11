//
//  HJNetworkAccessory.h
//  HJNetwork
//
//  Created by navy on 2022/5/18.
//  Copyright © 2022 HJNetwork. All rights reserved.
//

#ifndef HJNetworkAccessory_h
#define HJNetworkAccessory_h

#if __has_include(<HJNetwork/HJNetworkAccessory.h>)
#import <HJNetwork/HJRequestAccessory.h>
#import <HJNetwork/HJCoreRequest+Accessory.h>
#import <HJNetwork/HJBatchRequest+Accessory.h>
#import <HJNetwork/HJChainRequest+Accessory.h>
#import <HJNetwork/HJRequestEventAccessory.h>
#elif __has_include("HJNetworkAccessory.h")
#import "HJRequestAccessory.h"
#import "HJCoreRequest+Accessory.h"
#import "HJBatchRequest+Accessory.h"
#import "HJChainRequest+Accessory.h"
#import "HJRequestEventAccessory.h"
#endif

#endif /* HJNetworkAccessory_h */
