//
//  HJBatchRequest.h
//  HJNetwork
//
//  Created by navy on 2018/7/5.
//  Copyright © 2018 HJNetwork. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class HJBaseRequest;
@class HJBatchRequest;
@protocol HJRequestAccessory;

@protocol HJBatchRequestDelegate <NSObject>
@optional
- (void)batchRequestFinished:(HJBatchRequest *)batchRequest;
- (void)batchRequestFailed:(HJBatchRequest *)batchRequest;
@end


@interface HJBatchRequest : NSObject

@property (nonatomic) NSInteger tag;
@property (nonatomic, strong, readonly) NSArray<HJBaseRequest *> *requestArray;
@property (nonatomic, strong, nullable) NSMutableArray<id<HJRequestAccessory>> *requestAccessories;

@property (nonatomic, weak, nullable) id<HJBatchRequestDelegate> delegate;

/// Note this will be called only if all the requests are finished.
@property (nonatomic, copy, nullable) void (^successCompletionBlock)(HJBatchRequest *);

/// Note this will be called if one of the requests fails.
@property (nonatomic, copy, nullable) void (^failureCompletionBlock)(HJBatchRequest *);

///  The first request that failed (and causing the batch request to fail).
@property (nonatomic, strong, readonly, nullable) HJBaseRequest *failedRequest;

@property (nonatomic, strong, readonly, nullable) NSArray<HJBaseRequest *> *failedRequestArray;

@property (nonatomic, readwrite, getter=isLoadMore) BOOL loadMore;


- (instancetype)initWithRequestArray:(NSArray<HJBaseRequest *> *)requestArray;

- (void)addAccessory:(id<HJRequestAccessory>)accessory;

- (void)setCompletionBlockWithSuccess:(nullable void (^)(HJBatchRequest *batchRequest))success
                              failure:(nullable void (^)(HJBatchRequest *batchRequest))failure;

- (void)clearCompletionBlock;

- (void)start;

- (void)stop;

- (void)startWithCompletionBlockWithSuccess:(nullable void (^)(HJBatchRequest *batchRequest))success
                                    failure:(nullable void (^)(HJBatchRequest *batchRequest))failure;

- (void)startWithCompletionBlockWithSuccess:(nullable void (^)(HJBatchRequest *batchRequest))success
                                    failure:(nullable void (^)(HJBatchRequest *batchRequest))failure
                                   loadMore:(BOOL)loadMore;

///  Whether all response data is from local cache.
- (BOOL)isDataFromCache;

@end

NS_ASSUME_NONNULL_END
