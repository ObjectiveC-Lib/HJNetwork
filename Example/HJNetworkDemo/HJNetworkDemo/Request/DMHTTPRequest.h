//
//  DMHTTPRequest.h
//  HJNetworkDemo
//
//  Created by navy on 2022/7/27.
//

#import "DMBaseRequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface DMHTTPRequest : DMBaseRequest

- (instancetype)initWithRequestUrl:(NSString *)url;
- (instancetype)initWithRequestUrl:(NSString *)url method:(HJRequestMethod)method;

@end

NS_ASSUME_NONNULL_END
