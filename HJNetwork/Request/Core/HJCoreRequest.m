//
//  HJCoreRequest.m
//  HJNetwork
//
//  Created by navy on 2018/7/4.
//  Copyright © 2018 HJNetwork. All rights reserved.
//

#import "HJCoreRequest.h"
#import "HJNetworkAgent.h"
#import "HJNetworkPrivate.h"

NSString *const HJRequestValidationErrorDomain = @"com.hj.request.validation";

@interface HJCoreRequest ()
@property (nonatomic, strong, readwrite) NSURLSessionTask *requestTask;
@property (nonatomic, strong, readwrite) NSData *responseData;
@property (nonatomic, strong, readwrite) id responseJSONObject;
@property (nonatomic, strong, readwrite) id responseObject;
@property (nonatomic, strong, readwrite) NSString *responseString;
@property (nonatomic, strong, readwrite) NSError *error;
@end

@implementation HJCoreRequest

#pragma mark - Request and Response Information

- (void)dealloc {
    HJLog(@"%@ dealloc", [self class]);
}

- (NSHTTPURLResponse *)response {
    return (NSHTTPURLResponse *)self.requestTask.response;
}

- (NSInteger)responseStatusCode {
    return self.response.statusCode;
}

- (NSDictionary *)responseHeaders {
    return self.response.allHeaderFields;
}

- (NSURLRequest *)currentRequest {
    return self.requestTask.currentRequest;
}

- (NSURLRequest *)originalRequest {
    return self.requestTask.originalRequest;
}

- (BOOL)isCancelled {
    if (!self.requestTask) {
        return NO;
    }
    return self.requestTask.state == NSURLSessionTaskStateCanceling;
}

- (BOOL)isExecuting {
    if (!self.requestTask) {
        return NO;
    }
    return self.requestTask.state == NSURLSessionTaskStateRunning;
}

#pragma mark - Request Configuration

- (void)setCompletionBlockWithSuccess:(HJRequestCompletionBlock)success
                              failure:(HJRequestCompletionBlock)failure {
    self.successCompletionBlock = success;
    self.failureCompletionBlock = failure;
}

- (void)clearCompletionBlock {
    // nil out to break the retain cycle.
    self.successCompletionBlock = nil;
    self.failureCompletionBlock = nil;
    self.uploadProgressBlock = nil;
}

- (void)addAccessory:(id<HJRequestAccessory>)accessory {
    if (!self.requestAccessories) {
        self.requestAccessories = [NSMutableArray array];
    }
    [self.requestAccessories addObject:accessory];
}

#pragma mark - Request Action

- (void)start {
    [self toggleAccessoriesWillStartCallBack];
    [[HJNetworkAgent sharedAgent] addRequest:self];
}

- (void)stop {
    [self toggleAccessoriesWillStopCallBack];
    self.loadMore = NO;
    self.delegate = nil;
    [[HJNetworkAgent sharedAgent] cancelRequest:self];
    [self toggleAccessoriesDidStopCallBack];
}

- (void)startWithCompletionBlockWithSuccess:(HJRequestCompletionBlock)success
                                    failure:(HJRequestCompletionBlock)failure {
    [self startWithCompletionBlockWithSuccess:success failure:failure loadMore:NO];
}

- (void)startWithCompletionBlockWithSuccess:(HJRequestCompletionBlock)success
                                    failure:(HJRequestCompletionBlock)failure
                                   loadMore:(BOOL)loadMore {
    self.loadMore = loadMore;
    [self setCompletionBlockWithSuccess:success failure:failure];
    [self start];
}

#pragma mark - Subclass Override

- (void)requestCompletePreprocessor {
}

- (void)requestCompleteFilter {
}

- (void)requestFailedPreprocessor {
}

- (void)requestFailedFilter {
}

- (NSString *)requestUrl {
    return @"";
}

- (NSString *)cdnUrl {
    return @"";
}

- (HJDNSNode *)dnsNode {
    return nil;
}

- (NSString *)baseUrl {
    return @"";
}

- (NSTimeInterval)requestTimeoutInterval {
    return 60;
}

- (NSURLRequestCachePolicy)requestCachePolicy {
    return NSURLRequestUseProtocolCachePolicy;
}

- (id)requestArgument {
    return nil;
}

- (id)cacheFileNameFilterForRequestArgument:(id)argument {
    return argument;
}

- (HJRequestMethod)requestMethod {
    return HJRequestMethodGET;
}

- (HJRequestSerializerType)requestSerializerType {
    return HJRequestSerializerTypeHTTP;
}

- (HJResponseSerializerType)responseSerializerType {
    return HJResponseSerializerTypeJSON;
}

- (NSArray *)requestAuthorizationHeaderFieldArray {
    return nil;
}

- (NSDictionary *)requestHeaderFieldValueDictionary {
    return nil;
}

- (NSURLRequest *)buildCustomUrlRequest {
    return nil;
}

- (BOOL)useCDN {
    return NO;
}

- (BOOL)useDNS {
    return NO;
}

- (BOOL)allowsCellularAccess {
    return YES;
}

- (BOOL)HTTPShouldHandleCookies {
    return YES;
}

- (BOOL)removesKeysWithNullValues {
    return NO;
}

- (id)jsonValidator {
    return nil;
}

- (BOOL)statusCodeValidator {
    NSInteger statusCode = [self responseStatusCode];
    return (statusCode >= 200 && statusCode <= 299);
}

/// Custom
- (BOOL)customErrorValidator:(NSError * _Nullable __autoreleasing *)error {
    *error = nil;
    return NO;
}

#pragma mark - NSObject

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p>{ URL: %@ } { method: %@ } { arguments: %@ }",
            NSStringFromClass([self class]), self,
            self.currentRequest.URL, self.currentRequest.HTTPMethod, self.requestArgument];
}

@end
