//
//  DMHTTPRequest.h
//  HJNetworkDemo
//
//  Created by navy on 2022/7/27.
//

#import "DMBasicRequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface DMHTTPRequest : DMBasicRequest

- (instancetype)initWithRequestUrl:(NSString *)url;
- (instancetype)initWithRequestUrl:(NSString *)url method:(HJRequestMethod)method;

@end

NS_ASSUME_NONNULL_END
