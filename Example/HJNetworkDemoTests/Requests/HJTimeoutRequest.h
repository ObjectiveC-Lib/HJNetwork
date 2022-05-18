//
//  HJTImeoutRequest.h
//  HJNetworkDemo
//
//  Created by navy on 18/8/30.
//  Copyright © 2018 HJNetwork. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HJNetwork.h"

@interface HJTimeoutRequest : HJRequest

- (instancetype)initWithTimeout:(NSTimeInterval)timeout requestUrl:(NSString *)requestUrl;

@end
