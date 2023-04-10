//
//  DMSDWebImageManager.h
//  HJNetworkDemo
//
//  Created by navy on 2023/4/6.
//

#import <Foundation/Foundation.h>
#import <HJCache/HJCache.h>
#import <HJCache/HJCacheSDBridge.h>
#import <SDWebImage/SDWebImage.h>
#import <HJNetwork/HJNetwork.h>

NS_ASSUME_NONNULL_BEGIN

@interface DMSDWebImageManager : NSObject

@property (nonatomic, strong, readonly) SDWebImageManager *imageManager;
@property (nonatomic, strong, readonly) SDWebImagePrefetcher *imagePrefetcher;

+ (instancetype)sharedManager;

@end

NS_ASSUME_NONNULL_END
