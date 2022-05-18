//
//  HJBasicAuthRequest.m
//  HJNetworkDemo
//
//  Created by navy on 18/8/30.
//  Copyright © 2018 HJNetwork. All rights reserved.
//

#import "HJBasicAuthRequest.h"

@interface HJBasicAuthRequest ()

@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *password;
@property (nonatomic, strong) NSString *url;

@end

@implementation HJBasicAuthRequest

- (instancetype)initWithUsername:(NSString *)username password:(NSString *)password requestUrl:(NSString *)requestUrl {
    self = [super init];
    if (self) {
        _username = username;
        _password = password;
        _url = requestUrl;
    }
    return self;
}

- (NSString *)requestUrl {
    return _url;
}

- (NSArray *)requestAuthorizationHeaderFieldArray {
    return @[_username, _password];
}

@end
