//
//  HJRetryRequestSourceManager.h
//  HJNetwork
//
//  Created by navy on 2023/6/13.
//  Copyright © 2023 HJNetwork. All rights reserved.

#import <Foundation/Foundation.h>

@class HJRetryRequestSource;

NS_ASSUME_NONNULL_BEGIN

@interface HJRetryRequestSourceManager : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

+ (instancetype)sharedManager;

- (void)addSource:(HJRetryRequestSource *)source;
- (void)removeSource:(HJRetryRequestSource *)source;
- (nullable HJRetryRequestSource *)getSource:(NSString *)sourceId;

@end

NS_ASSUME_NONNULL_END
