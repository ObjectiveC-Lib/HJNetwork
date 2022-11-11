//
//  HJChainRequest.h
//  HJNetwork
//
//  Created by navy on 2018/7/5.
//  Copyright © 2018 HJNetwork. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class HJChainRequest;
@class HJCoreRequest;
@protocol HJRequestAccessory;

typedef void (^HJChainCallback)(HJChainRequest *chainRequest, HJCoreRequest *coreRequest);

@protocol HJChainRequestDelegate <NSObject>
@optional
- (void)chainRequestFinished:(HJChainRequest *)chainRequest;
- (void)chainRequestFailed:(HJChainRequest *)chainRequest failedCoreRequest:(HJCoreRequest*)request;
@end


@interface HJChainRequest : NSObject

@property (nonatomic,   weak, nullable) id<HJChainRequestDelegate> delegate;
@property (nonatomic, strong, nullable) NSMutableArray<id<HJRequestAccessory>> *requestAccessories;
@property (nonatomic, strong, nullable, readonly) NSArray<HJCoreRequest *> *requestArray;

- (void)addAccessory:(id<HJRequestAccessory>)accessory;
- (void)addRequest:(HJCoreRequest *)request callback:(nullable HJChainCallback)callback;

- (void)start;
- (void)stop;

@end

NS_ASSUME_NONNULL_END
