//
//  HJHTTPDefault.h
//  HJNetwork
//
//  Created by navy on 2022/5/18.
//  Copyright © 2022 HJNetwork. All rights reserved.
//

#ifndef HJHTTPDefault_h
#define HJHTTPDefault_h

#if __has_include(<HJNetwork/HJHTTPDefault.h>)
#import <HJNetwork/HJHTTPSessionManager.h>
#import <HJNetwork/HJHTTPOperationManager.h>
#elif __has_include("HJHTTPDefault.h")
#import "HJHTTPSessionManager.h"
#import "HJHTTPOperationManager.h"
#endif

#endif /* HJHTTPDefault_h */
