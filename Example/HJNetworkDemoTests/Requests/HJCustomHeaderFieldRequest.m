//
//  HJCustomHeaderFieldRequest.m
//  HJNetworkDemo
//
//  Created by navy on 18/8/30.
//  Copyright © 2018 HJNetwork. All rights reserved.
//

#import "HJCustomHeaderFieldRequest.h"

@interface HJCustomHeaderFieldRequest ()

@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *headers;
@property (nonatomic, strong) NSString *url;

@end

@implementation HJCustomHeaderFieldRequest

- (instancetype)initWithCustomHeaderField:(NSDictionary<NSString *, NSString *> *)headers requestUrl:(NSString *)requestUrl {
    self = [super init];
    if (self) {
        _headers = headers;
        _url = requestUrl;
    }
    return self;
}

- (NSString *)requestUrl {
    return _url;
}

- (NSDictionary<NSString *, NSString *> *)requestHeaderFieldValueDictionary {
    return _headers;
}
@end
