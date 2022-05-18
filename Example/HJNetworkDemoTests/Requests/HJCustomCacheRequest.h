//
//  HJCustomCacheRequest.h
//  HJNetworkDemo
//
//  Created by navy on 18/8/12.
//  Copyright © 2018 HJNetwork. All rights reserved.
//

#import "HJBasicHTTPRequest.h"

@interface HJCustomCacheRequest : HJBasicHTTPRequest

- (instancetype)initWithRequestUrl:(NSString *)url cacheTimeInSeconds:(NSInteger)time;

- (instancetype)initWithRequestUrl:(NSString *)url cacheTimeInSeconds:(NSInteger)time cacheVersion:(long long)version cacheSensitiveData:(id)sensitiveData;

@end
