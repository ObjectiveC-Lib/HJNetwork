//
//  DMAccountLoginApi.m
//  HJNetworkDemo
//
//  Created by navy on 2020/12/28.
//

#import "DMAccountLoginApi.h"

@implementation DMAccountLoginApi {
    NSString *_name;
    NSString *_pwd;
}

- (id)initWithAccountName:(NSString *)name pwd:(NSString *)pwd {
    self = [super init];
    if (self) {
        _name = name;
        _pwd = pwd;
    }
    return self;
}

- (NSString *)requestUrl {
    return @"api/passport/v3_1/login.php";
}

- (id)requestArgument {
    return @{@"phone":@"phone",
             @"pwd":@"pwd",
             @"entry":@"entry",
             @"appkey":@"appkey",
             @"appver":@"appver",
             @"sign":@"sign",
             @"cookie_format":@"1",
             };
}

- (BOOL)customCodeValidator {
    return YES;
    NSString *statusCode = [NSString stringWithFormat:@"%@", [self.responseJSONObject objectForKey:@"err"]];
    return ([statusCode isEqualToString:@"0"]);
}

@end
