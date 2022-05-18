//
//  AFDefault.h
//  HJNetwork
//
//  Created by navy on 2022/5/18.
//

#ifndef AFDefault_h
#define AFDefault_h

#if __has_include(<HJNetwork/AFDefault.h>)
#import <HJNetwork/AFSessionManager.h>
#import <HJNetwork/AFOperationManager.h>
#import <HJNetwork/AFDownloadSessionManager.h>
#import <HJNetwork/AFDownloadOperationManager.h>
#elif __has_include("AFDefault.h")
#import "AFSessionManager.h"
#import "AFOperationManager.h"
#import "AFDownloadSessionManager.h"
#import "AFDownloadOperationManager.h"
#endif

#endif /* AFDefault_h */
