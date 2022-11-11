//
//  HJBasicUrlFilter.m
//  HJNetworkDemo
//
//  Created by navy on 18/8/30.
//  Copyright © 2018 HJNetwork. All rights reserved.
//

#import "HJBasicUrlFilter.h"
#import "HJNetworkConfig.h"
#import <AFNetworking/AFNetworking.h>

@interface HJBasicUrlFilter ()
@property (nonatomic, strong) NSDictionary *arguments;
@end

@implementation HJBasicUrlFilter

+ (instancetype)filterWithArguments:(NSDictionary *)arguments {
    return [[self alloc] initWithArguments:arguments];
}

- (instancetype)initWithArguments:(NSDictionary *)arguments {
    self = [super init];
    if (self) {
        _arguments = arguments;
    }
    return self;
}

#pragma mark - HJUrlFilterProtocol

- (NSString *)filterUrl:(NSString *)originUrl withRequest:(HJCoreRequest *)request {
    return [self appendParameters:_arguments originUrl:originUrl request:request];
}

- (NSString *)appendParameters:(NSDictionary *)parameters
                     originUrl:(NSString *)originUrl
                       request:(HJCoreRequest *)request {
    NSString *paraUrlString = AFQueryStringFromParameters(parameters);
    
    if (!(paraUrlString.length > 0)) {
        return originUrl;
    }
    
    BOOL useDummyUrl = NO;
    static NSString *dummyUrl = nil;
    NSURLComponents *components = [NSURLComponents componentsWithString:originUrl];
    if (!components) {
        useDummyUrl = YES;
        if (!dummyUrl) {
            dummyUrl = @"http://www.dummy.com";
        }
        components = [NSURLComponents componentsWithString:dummyUrl];
    }
    
    NSString *queryString = components.query ?: @"";
    NSString *newQueryString = [queryString stringByAppendingFormat:queryString.length > 0 ? @"&%@" : @"%@", paraUrlString];
    
    components.query = newQueryString;
    
    if (useDummyUrl) {
        return [components.URL.absoluteString substringFromIndex:dummyUrl.length - 1];
    } else {
        return components.URL.absoluteString;
    }
}

@end
