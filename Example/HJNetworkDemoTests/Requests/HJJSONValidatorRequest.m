//
//  HJJSONValidatorRequest.m
//  HJNetworkDemo
//
//  Created by navy on 18/8/30.
//  Copyright © 2018 HJNetwork. All rights reserved.
//

#import "HJJSONValidatorRequest.h"

@interface HJJSONValidatorRequest ()

@property (nonatomic, strong) id validator;
@property (nonatomic, strong) NSString *url;

@end

@implementation HJJSONValidatorRequest

- (instancetype)initWithJSONValidator:(id)validator requestUrl:(NSString *)requestUrl {
    self = [super init];
    if (self) {
        _validator = validator;
        _url = requestUrl;
    }
    return self;
}

- (id)jsonValidator {
    return _validator;
}

- (NSString *)requestUrl {
    return _url;
}
@end
