//
//  HJUploadConfig.h
//  HJNetworkDemo
//
//  Created by navy on 2022/9/5.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HJUploadConfig : NSObject

@property (nonatomic, assign) NSUInteger fragmentMaxSize;   // default: 512k=512*1024;
@property (nonatomic, assign) NSUInteger failureRetryCount; // default: 0;

+ (instancetype)defaultConfig;

@end

NS_ASSUME_NONNULL_END
