//
//  HJBasicHTTPGetRequest.m
//  HJNetworkDemo
//
//  Created by navy on 18/8/29.
//  Copyright © 2018 HJNetwork. All rights reserved.
//

#import "HJBasicHTTPRequest.h"

@interface HJBasicHTTPRequest ()

@property (nonatomic, strong) NSString *url;
@property (nonatomic, assign) HJRequestMethod method;

@end

@implementation HJBasicHTTPRequest

- (instancetype)initWithRequestUrl:(NSString *)url {
    return [self initWithRequestUrl:url method:HJRequestMethodGET];
}

- (instancetype)initWithRequestUrl:(NSString *)url method:(HJRequestMethod)method {
    self = [super init];
    if (self) {
        _url = url;
        _method = method;
    }
    return self;
}

- (NSString *)requestUrl {
    return _url;
}

- (HJRequestMethod)requestMethod {
    return _method;
}

@end
