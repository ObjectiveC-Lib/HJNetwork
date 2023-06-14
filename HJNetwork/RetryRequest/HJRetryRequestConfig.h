//
//  HJRetryRequestConfig.h
//  HJNetwork
//
//  Created by navy on 2023/6/13.
//  Copyright © 2023 HJNetwork. All rights reserved.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HJRetryRequestConfig : NSObject <NSSecureCoding, NSCopying>

@property (nonatomic, assign) BOOL retryEnable;         // default: YES;
@property (nonatomic, assign) NSUInteger retryCount;    // default: 3;
@property (nonatomic, assign) NSUInteger retryInterval; // default: 1s;

+ (instancetype)defaultConfig;

@end

NS_ASSUME_NONNULL_END
