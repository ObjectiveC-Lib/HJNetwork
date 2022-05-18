//
//  HJFileSourceManager.h
//  HJNetworkDemo
//
//  Created by navy on 2022/9/5.
//

#import <Foundation/Foundation.h>

@class HJFileSource;

NS_ASSUME_NONNULL_BEGIN

@interface HJFileSourceManager : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

+ (instancetype)sharedManager;

- (void)addSource:(HJFileSource *)source;
- (void)removeSource:(HJFileSource *)source;

@end

NS_ASSUME_NONNULL_END
