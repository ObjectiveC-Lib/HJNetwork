//
//  DMCommonRequest.h
//  HJNetworkDemo
//
//  Created by navy on 2023/1/4.
//

#import "DMBaseRequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface DMCommonRequest : DMBaseRequest

- (instancetype)initWithUrl:(NSString *)requestUrl
            requestArgument:(nullable id)requestArgument
                headerField:(nullable NSDictionary *)headerField
              requestMethod:(HJRequestMethod)requestMethod
      requestSerializerType:(HJRequestSerializerType)requestSerializerType
     responseSerializerType:(HJResponseSerializerType)responseSerializerType;

@end

NS_ASSUME_NONNULL_END
