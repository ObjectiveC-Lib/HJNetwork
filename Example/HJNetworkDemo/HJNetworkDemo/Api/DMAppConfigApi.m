//
//  DMAppConfigApi.m
//  HJNetworkDemo
//
//  Created by navy on 2020/12/28.
//

#import "DMAppConfigApi.h"

@implementation DMAppConfigApi

- (instancetype)init {
    self = [super init];
    if (self) {
        self.ignoreCache = YES;
    }
    return self;
}

- (NSString *)requestUrl {
    return @"http://xxx/sys/android/config.json";
}

- (NSInteger)cacheTimeInSeconds {
    return 24 * 60 * 60;
}

@end
