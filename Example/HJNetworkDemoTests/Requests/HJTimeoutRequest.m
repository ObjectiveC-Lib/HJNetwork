//
//  HJTImeoutRequest.m
//  HJNetworkDemo
//
//  Created by navy on 18/8/30.
//  Copyright © 2018 HJNetwork. All rights reserved.
//

#import "HJTimeoutRequest.h"

@interface HJTimeoutRequest ()

@property (nonatomic, assign) NSTimeInterval timeout;
@property (nonatomic, strong) NSString *url;

@end

@implementation HJTimeoutRequest

- (instancetype)initWithTimeout:(NSTimeInterval)timeout requestUrl:(NSString *)requestUrl {
    self = [super init];
    if (self) {
        _timeout = timeout;
        _url = requestUrl;
    }
    return self;
}

- (NSTimeInterval)requestTimeoutInterval {
    return _timeout;
}

- (NSString *)requestUrl {
    return _url;
}

@end
