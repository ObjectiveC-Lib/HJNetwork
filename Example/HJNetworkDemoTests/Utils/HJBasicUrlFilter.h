//
//  HJBasicUrlFilter.h
//  HJNetworkDemo
//
//  Created by navy on 18/8/30.
//  Copyright © 2018 HJNetwork. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HJNetworkConfig.h"

@protocol HJUrlFilterProtocol;

@interface HJBasicUrlFilter : NSObject<HJUrlFilterProtocol>

+ (instancetype)filterWithArguments:(NSDictionary<NSString *, NSString *> *)arguments;

@end
