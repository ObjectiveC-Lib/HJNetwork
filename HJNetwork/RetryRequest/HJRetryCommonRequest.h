//
//  HJRetryCommonRequest.h
//  HJNetwork
//
//  Created by navy on 2023/6/14.
//  Copyright © 2023 HJNetwork. All rights reserved.

#import <Foundation/Foundation.h>
#import <HJNetwork/HJRequest.h>
#import <HJTask/HJTask.h>

NS_ASSUME_NONNULL_BEGIN

@interface HJRetryCommonRequest : HJBaseRequest <HJTaskProtocol>

- (instancetype)initWithUrl:(NSString *)requestUrl
            requestArgument:(nullable id)requestArgument
                headerField:(nullable NSDictionary *)headerField
              requestMethod:(HJRequestMethod)requestMethod
      requestSerializerType:(HJRequestSerializerType)requestSerializerType
     responseSerializerType:(HJResponseSerializerType)responseSerializerType;

@property (nonatomic, copy, nullable) HJTaskKey taskKey;

@end

NS_ASSUME_NONNULL_END
