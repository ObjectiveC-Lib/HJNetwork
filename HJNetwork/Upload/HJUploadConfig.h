//
//  HJUploadConfig.h
//  HJNetwork
//
//  Created by navy on 2022/9/5.
//  Copyright © 2022 HJNetwork. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HJUploadConfig : NSObject <NSSecureCoding, NSCopying>

@property (nonatomic, assign) BOOL fragmentEnable;          // default: NO;
@property (nonatomic, assign) NSUInteger fragmentMaxSize;   // default: 512k=512*1024;

@property (nonatomic, assign) BOOL retryEnable;             // default: YES;
@property (nonatomic, assign) NSUInteger retryCount;        // default: 3;
@property (nonatomic, assign) NSUInteger retryInterval;     // default: 1s;

+ (instancetype)defaultConfig;

@end

NS_ASSUME_NONNULL_END
