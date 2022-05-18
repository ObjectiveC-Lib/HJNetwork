//
//  HJBasicAuthRequest.h
//  HJNetworkDemo
//
//  Created by navy on 18/8/30.
//  Copyright © 2018 HJNetwork. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <HJNetwork/HJNetwork.h>

@interface HJBasicAuthRequest : HJRequest

- (instancetype)initWithUsername:(NSString *)username password:(NSString *)password requestUrl:(NSString *)requestUrl;

@end
