//
//  HJBasicHTTPGetRequest.h
//  HJNetworkDemo
//
//  Created by navy on 18/8/29.
//  Copyright © 2018 HJNetwork. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HJNetwork.h"

@interface HJBasicHTTPRequest : HJBaseRequest

- (instancetype)initWithRequestUrl:(NSString *)url;
- (instancetype)initWithRequestUrl:(NSString *)url method:(HJRequestMethod)method;

@end
