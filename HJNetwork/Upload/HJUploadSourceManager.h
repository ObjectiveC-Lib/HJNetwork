//
//  HJUploadSourceManager.h
//  HJNetwork
//
//  Created by navy on 2022/9/5.
//  Copyright © 2022 HJNetwork. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HJUploadSource;

NS_ASSUME_NONNULL_BEGIN

@interface HJUploadSourceManager : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

+ (instancetype)sharedManager;

- (void)addSource:(HJUploadSource *)source;
- (void)removeSource:(HJUploadSource *)source;
- (nullable HJUploadSource *)getSource:(NSString *)sourceId;

@end

NS_ASSUME_NONNULL_END
