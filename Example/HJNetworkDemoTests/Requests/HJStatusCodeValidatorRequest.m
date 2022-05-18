//
//  HJStatusCodeValidatorRequest.m
//  HJNetworkDemo
//
//  Created by navy on 18/8/30.
//  Copyright © 2018 HJNetwork. All rights reserved.
//

#import "HJStatusCodeValidatorRequest.h"

@interface HJStatusCodeValidatorRequest ()

@property (nonatomic, strong) NSString *url;

@end

@implementation HJStatusCodeValidatorRequest

- (instancetype)initWithRequestUrl:(NSString *)requestUrl {
    self = [super init];
    if (self) {
        _url = requestUrl;
    }
    return self;
}

- (NSString *)requestUrl {
    return _url;
}

- (BOOL)statusCodeValidator {
    return [self responseStatusCode] == 418;// 418 I'm a teapot
}

- (HJResponseSerializerType)responseSerializerType {
    return HJResponseSerializerTypeHTTP;
}

@end
