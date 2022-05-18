//
//  DMHTTPRequest.m
//  HJNetworkDemo
//
//  Created by navy on 2022/7/27.
//

#import "DMHTTPRequest.h"

@interface DMHTTPRequest ()

@property (nonatomic, strong) NSString *url;
@property (nonatomic, assign) HJRequestMethod method;

@end

@implementation DMHTTPRequest

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

- (BOOL)customErrorValidator:(NSError * _Nullable __autoreleasing *)error {
    if (error) {
        *error = [NSError errorWithDomain:HJRequestValidationErrorDomain
                                     code:HJRequestValidationErrorInvalidStatusCode
                                 userInfo:@{NSLocalizedDescriptionKey:@"ddddddddddddd"}];
    }
    return NO;
}

@end
