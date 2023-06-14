//
//  HJNetworkAgent.m
//  HJNetwork
//
//  Created by navy on 2018/7/4.
//  Copyright © 2018 HJNetwork. All rights reserved.
//

#import "HJNetworkAgent.h"
#import "HJNetworkConfig.h"
#import "HJNetworkPrivate.h"
#import <pthread/pthread.h>

#if __has_include(<AFNetworking/AFHTTPSessionManager.h>)
#import <AFNetworking/AFHTTPSessionManager.h>
#elif __has_include("AFHTTPSessionManager.h")
#import "AFHTTPSessionManager.h"
#endif

#if __has_include(<HJNetwork/HJNetworkCommon.h>)
#import <HJNetwork/HJNetworkCommon.h>
#elif __has_include("HJNetworkCommon.h")
#import "HJNetworkCommon.h"
#endif

#define Lock() pthread_mutex_lock(&_lock)
#define Unlock() pthread_mutex_unlock(&_lock)

#define kHJNetworkIncompleteDownloadFolderName @"HJNetworkIncomplete"

@implementation HJNetworkAgent {
    AFHTTPSessionManager *_manager;
    HJNetworkConfig *_config;
    AFJSONResponseSerializer *_jsonResponseSerializer;
    AFXMLParserResponseSerializer *_xmlParserResponseSerialzier;
    NSMutableDictionary<NSNumber *, HJCoreRequest *> *_requestsRecord;
    
    dispatch_queue_t _processingQueue;
    pthread_mutex_t _lock;
    NSIndexSet *_allStatusCodes;
}

+ (HJNetworkAgent *)sharedAgent {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _config = [HJNetworkConfig sharedConfig];
        _manager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:_config.sessionConfiguration];
        _requestsRecord = [NSMutableDictionary dictionary];
        _processingQueue = dispatch_queue_create("com.hj.networkagent.processing", DISPATCH_QUEUE_CONCURRENT);
        _allStatusCodes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(100, 500)];
        pthread_mutex_init(&_lock, NULL);
        
        _manager.completionQueue = _processingQueue;
        _manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        _manager.responseSerializer.acceptableStatusCodes = _allStatusCodes;
        _manager.securityPolicy = _config.securityPolicy;
        [_manager setAuthenticationChallengeHandler:_config.sessionAuthenticationChallengeHandler];
        [_manager setTaskDidFinishCollectingMetricsBlock:_config.collectingMetricsBlock];
    }
    return self;
}

- (AFJSONResponseSerializer *)jsonResponseSerializer {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _jsonResponseSerializer = [AFJSONResponseSerializer serializer];
        _jsonResponseSerializer.acceptableStatusCodes = _allStatusCodes;
        if (_config.jsonResponseContentTypes.count) {
            NSMutableSet *set = [[NSMutableSet alloc] initWithSet:_jsonResponseSerializer.acceptableContentTypes];
            [set addObjectsFromArray:_config.jsonResponseContentTypes];
            _jsonResponseSerializer.acceptableContentTypes = [set copy];
        }
    });
    return _jsonResponseSerializer;
}

- (AFXMLParserResponseSerializer *)xmlParserResponseSerialzier {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _xmlParserResponseSerialzier = [AFXMLParserResponseSerializer serializer];
        _xmlParserResponseSerialzier.acceptableStatusCodes = _allStatusCodes;
        if (_config.xmlResponseContentTypes.count) {
            NSMutableSet *set = [[NSMutableSet alloc] initWithSet:_xmlParserResponseSerialzier.acceptableContentTypes];
            [set addObjectsFromArray:_config.xmlResponseContentTypes];
            _xmlParserResponseSerialzier.acceptableContentTypes = [set copy];
        }
    });
    return _xmlParserResponseSerialzier;
}

#pragma mark -

- (void)addRequest:(HJCoreRequest *)request {
    NSParameterAssert(request != nil);
    
    NSError * __autoreleasing requestSerializationError = nil;
    
    NSURLRequest *customUrlRequest= [request buildCustomUrlRequest];
    if (customUrlRequest) {
        __block NSURLSessionDataTask *dataTask = nil;
        dataTask = [_manager dataTaskWithRequest:customUrlRequest
                                  uploadProgress:nil
                                downloadProgress:nil
                               completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
            [self handleRequestResult:dataTask responseObject:responseObject error:error];
        }];
        request.requestTask = dataTask;
    } else {
        request.requestTask = [self sessionTaskForRequest:request error:&requestSerializationError];
    }
    
    if (requestSerializationError) {
        [self requestDidFailWithRequest:request error:requestSerializationError];
        return;
    }
    
    NSAssert(request.requestTask != nil, @"requestTask should not be nil");
    
    if ([request.requestTask respondsToSelector:@selector(priority)]) {
        switch (request.requestPriority) {
            case HJRequestPriorityHigh:
                request.requestTask.priority = NSURLSessionTaskPriorityHigh;
                break;
            case HJRequestPriorityLow:
                request.requestTask.priority = NSURLSessionTaskPriorityLow;
                break;
            case HJRequestPriorityDefault:
            default:
                request.requestTask.priority = NSURLSessionTaskPriorityDefault;
                break;
        }
    }
    
    HJLog(@"Start Request: %@", NSStringFromClass([request class]));
    
    // Retain request
    [self addRequestToRecord:request];
    [request.requestTask resume];
}

- (void)cancelRequest:(HJCoreRequest *)request {
    NSParameterAssert(request != nil);
    
    if (request.resumableDownloadPath && [self incompleteDownloadTempPathForDownloadPath:request.resumableDownloadPath] != nil) {
        NSURLSessionDownloadTask *requestTask = (NSURLSessionDownloadTask *)request.requestTask;
        if ([requestTask respondsToSelector:@selector(cancelByProducingResumeData:)]) {
            [requestTask cancelByProducingResumeData:^(NSData *resumeData) {
                NSURL *localUrl = [self incompleteDownloadTempPathForDownloadPath:request.resumableDownloadPath];
                if (!request.ignoreResumableData) {
                    [resumeData writeToURL:localUrl atomically:YES];
                }
            }];
        }
    } else {
        [request.requestTask cancel];
    }
    
    //    [self removeRequestFromRecord:request];
    //    [request clearCompletionBlock];
}

- (void)cancelAllRequests {
    Lock();
    NSArray *allKeys = [_requestsRecord allKeys];
    Unlock();
    if (allKeys && allKeys.count > 0) {
        NSArray *copiedKeys = [allKeys copy];
        for (NSNumber *key in copiedKeys) {
            Lock();
            HJCoreRequest *request = _requestsRecord[key];
            Unlock();
            [request stop];
        }
    }
}

- (void)addRequestToRecord:(HJCoreRequest *)request {
    Lock();
    _requestsRecord[@(request.requestTask.taskIdentifier)] = request;
    Unlock();
}

- (void)removeRequestFromRecord:(HJCoreRequest *)request {
    Lock();
    [_requestsRecord removeObjectForKey:@(request.requestTask.taskIdentifier)];
    Unlock();
}

- (NSString *)buildRequestUrl:(HJCoreRequest *)request {
    NSParameterAssert(request != nil);
    
    NSString *detailUrl = [request requestUrl];
    NSURL *temp = [NSURL URLWithString:detailUrl];
    if (temp && temp.host && temp.scheme) {
        return detailUrl;
    }
    
    NSArray *filters = [_config urlFilters];
    for (id<HJUrlFilterProtocol> filter in filters) {
        detailUrl = [filter filterUrl:detailUrl withRequest:request];
    }
    
    NSString *baseUrl;
    if ([request useCDN]) {
        if ([request cdnUrl].length > 0) {
            baseUrl = [request cdnUrl];
        } else {
            baseUrl = [_config cdnUrl];
        }
    } else {
        if ([request baseUrl].length > 0) {
            baseUrl = [request baseUrl];
        } else {
            baseUrl = [_config baseUrl];
        }
    }
    
    // URL slash compatibility
    NSURL *url = [NSURL URLWithString:baseUrl];
    if (baseUrl.length > 0 && ![baseUrl hasSuffix:@"/"]) {
        url = [url URLByAppendingPathComponent:@""];
    }
    
    NSString *resultUrl = [NSURL URLWithString:detailUrl relativeToURL:url].absoluteString;
    
    return resultUrl;
}

- (NSString *)buildRequestUrlWithDNS:(HJCoreRequest *)request {
    NSString *requestUrl = [self buildRequestUrl:request];
    
    if ([request useDNS]) {
        HJDNSNode *node = [request dnsNode];
        if (!node) {
            if (_config.dnsNodeBlock) {
                node = _config.dnsNodeBlock(requestUrl);
            }
        }
        
        if (node) {
            if (node.url != nil && [node.url length] > 0) {
                requestUrl = node.url;
            }
        }
    }
    
    return requestUrl;
}

/*
 - (NSString *)buildRequestUrl:(HJCoreRequest *)request {
 NSParameterAssert(request != nil);
 
 NSURL *tempUrl = [self handleRequestURL:request urlEncode:YES];
 
 if (tempUrl && tempUrl.host && tempUrl.scheme) {
 if (request.requestMethod == HJRequestMethodGET ||
 request.requestMethod == HJRequestMethodHEAD ||
 request.requestMethod == HJRequestMethodDELETE) return tempUrl.absoluteString;
 } else {
 NSString *baseUrl;
 if ([request useCDN]) {
 if ([request cdnUrl].length > 0) {
 baseUrl = [request cdnUrl];
 } else {
 baseUrl = [_config cdnUrl];
 }
 } else {
 if ([request baseUrl].length > 0) {
 baseUrl = [request baseUrl];
 } else {
 baseUrl = [_config baseUrl];
 }
 }
 // URL slash compability
 NSURL *url = [NSURL URLWithString:baseUrl];
 if (baseUrl.length > 0 && ![baseUrl hasSuffix:@"/"]) {
 url = [url URLByAppendingPathComponent:@""];
 }
 tempUrl = [NSURL URLWithString:tempUrl.absoluteString relativeToURL:url];
 if (request.requestMethod == HJRequestMethodGET ||
 request.requestMethod == HJRequestMethodHEAD ||
 request.requestMethod == HJRequestMethodDELETE) return tempUrl.absoluteString;
 }
 return [[tempUrl.absoluteString componentsSeparatedByString:@"?"] objectAtIndex:0]?:@"";
 }
 
 - (id)buildRequestArgument:(HJCoreRequest *)request {
 NSParameterAssert(request != nil);
 if (request.requestMethod == HJRequestMethodGET ||
 request.requestMethod == HJRequestMethodHEAD ||
 request.requestMethod == HJRequestMethodDELETE) return @{};
 return [self handleRequestArgument:request urlEncode:YES];
 }
 
 - (NSURL *)handleRequestURL:(HJCoreRequest *)request urlEncode:(BOOL)urlEncode {
 NSString *detailUrl = [request requestUrl];
 NSArray *filters = [_config urlFilters];
 for (id<HJUrlFilterProtocol> f in filters) {
 detailUrl = [f filterUrl:detailUrl urlEncode:urlEncode withRequest:request];
 }
 return [NSURL URLWithString:detailUrl?:@""];
 }
 
 - (NSDictionary *)handleRequestArgument:(HJCoreRequest *)request urlEncode:(BOOL)urlEncode {
 NSURL *url = [self handleRequestURL:request urlEncode:urlEncode];
 NSString *queryString = url.query;
 NSArray *queryArray = [queryString componentsSeparatedByString:@"&"];
 NSMutableArray *keys = @[].mutableCopy;
 NSMutableArray *values = @[].mutableCopy;
 for (NSString *obj in queryArray) {
 if ([HJNetworkUtils containsOfString:@"=" originalStr:obj]) {
 NSArray *objs = [obj componentsSeparatedByString:@"="];
 [keys addObject:[objs objectAtIndex:0]];
 if (objs.count > 1) {
 NSString *value = [HJNetworkUtils stringByURLDecode:[objs objectAtIndex:1]];
 [values addObject:HJNSStringAvailable(value)?value:@""];
 } else {
 [values addObject:@""];
 }
 }
 }
 NSMutableDictionary *queryDict = [NSMutableDictionary dictionaryWithObjects:values forKeys:keys];
 if (request.requestArgument) {
 [queryDict addEntriesFromDictionary:request.requestArgument];
 }
 return queryDict;
 }
 */

- (AFHTTPRequestSerializer *)requestSerializerForRequest:(HJCoreRequest *)request {
    AFHTTPRequestSerializer *requestSerializer = nil;
    if (request.requestSerializerType == HJRequestSerializerTypeHTTP) {
        requestSerializer = [AFHTTPRequestSerializer serializer];
    } else if (request.requestSerializerType == HJRequestSerializerTypeJSON) {
        requestSerializer = [AFJSONRequestSerializer serializer];
    }
    
    requestSerializer.allowsCellularAccess = [request allowsCellularAccess];
    requestSerializer.HTTPShouldHandleCookies = [request HTTPShouldHandleCookies];
    requestSerializer.timeoutInterval = [request requestTimeoutInterval];
    requestSerializer.cachePolicy = [request requestCachePolicy];
    
    // If api needs server username and password
    NSArray<NSString *> *authorizationHeaderFieldArray = [request requestAuthorizationHeaderFieldArray];
    if (authorizationHeaderFieldArray != nil) {
        [requestSerializer setAuthorizationHeaderFieldWithUsername:authorizationHeaderFieldArray.firstObject
                                                          password:authorizationHeaderFieldArray.lastObject];
    }
    
    // If api needs to add custom value to HTTPHeaderField
    NSDictionary<NSString *, NSString *> *headerFieldValueDictionary = [request requestHeaderFieldValueDictionary];
    if (headerFieldValueDictionary != nil) {
        for (NSString *httpHeaderField in headerFieldValueDictionary.allKeys) {
            NSString *value = headerFieldValueDictionary[httpHeaderField];
            [requestSerializer setValue:value forHTTPHeaderField:httpHeaderField];
        }
    }
    
    // If api needs to add Host to HTTPHeaderField
    if ([request useDNS]) {
        HJDNSNode *node = [request dnsNode];
        if (!node) {
            if (_config.dnsNodeBlock) {
                NSString *requestUrl = [self buildRequestUrl:request];
                node = _config.dnsNodeBlock(requestUrl);
            }
        }
        
        if (node) {
            if (node.host != nil && [node.host length] > 0) {
                [requestSerializer setValue:node.host forHTTPHeaderField:@"host"];
            }
        }
    }
    
    return requestSerializer;
}

- (NSURLSessionTask *)sessionTaskForRequest:(HJCoreRequest *)request error:(NSError * _Nullable __autoreleasing *)error {
    HJRequestMethod method = [request requestMethod];
    NSString *url = [self buildRequestUrlWithDNS:request];
    id param = request.requestArgument;
    AFConstructingBlock constructingBlock = [request constructingBodyBlock];
    AFURLSessionTaskProgressBlock uploadProgressBlock = [request uploadProgressBlock];
    AFHTTPRequestSerializer *requestSerializer = [self requestSerializerForRequest:request];
    
    switch (method) {
        case HJRequestMethodGET: {
            if (request.resumableDownloadPath) {
                return [self downloadTaskWithDownloadPath:request.resumableDownloadPath
                                      ignoreResumableData:request.ignoreResumableData
                                        requestSerializer:requestSerializer
                                                URLString:url
                                               parameters:param
                                                 progress:request.resumableDownloadProgressBlock
                                                    error:error];
            } else {
                return [self dataTaskWithHTTPMethod:@"GET"
                                  requestSerializer:requestSerializer
                                          URLString:url
                                         parameters:param
                                              error:error];
            }
        }
        case HJRequestMethodPOST: {
            return [self dataTaskWithHTTPMethod:@"POST"
                              requestSerializer:requestSerializer
                                      URLString:url
                                     parameters:param
                                 uploadProgress:uploadProgressBlock
                      constructingBodyWithBlock:constructingBlock
                                          error:error];
        }
        case HJRequestMethodPUT: {
            return [self dataTaskWithHTTPMethod:@"PUT"
                              requestSerializer:requestSerializer
                                      URLString:url
                                     parameters:param
                                 uploadProgress:uploadProgressBlock
                      constructingBodyWithBlock:constructingBlock
                                          error:error];
        }
        case HJRequestMethodHEAD: {
            return [self dataTaskWithHTTPMethod:@"HEAD"
                              requestSerializer:requestSerializer
                                      URLString:url
                                     parameters:param
                                          error:error];
        }
        case HJRequestMethodDELETE: {
            return [self dataTaskWithHTTPMethod:@"DELETE"
                              requestSerializer:requestSerializer
                                      URLString:url
                                     parameters:param
                                          error:error];
        }
        case HJRequestMethodPATCH: {
            return [self dataTaskWithHTTPMethod:@"PATCH"
                              requestSerializer:requestSerializer
                                      URLString:url
                                     parameters:param
                                          error:error];
        }
    }
}

#pragma mark -

- (NSURLSessionDataTask *)dataTaskWithHTTPMethod:(NSString *)method
                               requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
                                       URLString:(NSString *)URLString
                                      parameters:(id)parameters
                                           error:(NSError * _Nullable __autoreleasing *)error {
    return [self dataTaskWithHTTPMethod:method
                      requestSerializer:requestSerializer
                              URLString:URLString
                             parameters:parameters
                         uploadProgress:nil
              constructingBodyWithBlock:nil
                                  error:error];
}

- (NSURLSessionDataTask *)dataTaskWithHTTPMethod:(NSString *)method
                               requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
                                       URLString:(NSString *)URLString
                                      parameters:(id)parameters
                                  uploadProgress:(AFURLSessionTaskProgressBlock)uploadProgress
                       constructingBodyWithBlock:(nullable void (^)(id <AFMultipartFormData> formData))block
                                           error:(NSError * _Nullable __autoreleasing *)error {
    NSMutableURLRequest *request = nil;
    
    if (block) {
        request = [requestSerializer multipartFormRequestWithMethod:method
                                                          URLString:URLString
                                                         parameters:parameters
                                          constructingBodyWithBlock:block
                                                              error:error];
    } else {
        request = [requestSerializer requestWithMethod:method
                                             URLString:URLString
                                            parameters:parameters
                                                 error:error];
    }
    
    __block NSURLSessionDataTask *dataTask = nil;
    dataTask = [_manager dataTaskWithRequest:request
                              uploadProgress:uploadProgress
                            downloadProgress:nil
                           completionHandler:^(NSURLResponse * __unused response, id responseObject, NSError *_error) {
        [self handleRequestResult:dataTask responseObject:responseObject error:_error];
    }];
    
    return dataTask;
}

- (NSURLSessionDownloadTask *)downloadTaskWithDownloadPath:(NSString *)downloadPath
                                       ignoreResumableData:(BOOL)ignoreResumableData
                                         requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
                                                 URLString:(NSString *)URLString
                                                parameters:(id)parameters
                                                  progress:(nullable void (^)(NSProgress *downloadProgress))downloadProgressBlock
                                                     error:(NSError * _Nullable __autoreleasing *)error {
    // add parameters to URL;
    NSMutableURLRequest *urlRequest = [requestSerializer requestWithMethod:@"GET"
                                                                 URLString:URLString
                                                                parameters:parameters
                                                                     error:error];
    
    NSString *downloadTargetPath;
    BOOL isDirectory;
    if (![[NSFileManager defaultManager] fileExistsAtPath:downloadPath isDirectory:&isDirectory]) {
        isDirectory = NO;
    }
    // If targetPath is a directory, use the file name we got from the urlRequest.
    // Make sure downloadTargetPath is always a file, not directory.
    if (isDirectory) {
        NSString *fileName = [urlRequest.URL lastPathComponent];
        downloadTargetPath = [NSString pathWithComponents:@[downloadPath, fileName]];
    } else {
        downloadTargetPath = downloadPath;
    }
    
    // AFN use `moveItemAtURL` to move downloaded file to target path,
    // this method aborts the move attempt if a file already exist at the path.
    // So remove the exist file before start the download task.
    if ([[NSFileManager defaultManager] fileExistsAtPath:downloadTargetPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:downloadTargetPath error:nil];
    }
    
    BOOL resumeSucceeded = NO;
    __block NSURLSessionDownloadTask *downloadTask = nil;
    
    NSURL *localUrl = [self incompleteDownloadTempPathForDownloadPath:downloadPath];
    if (localUrl != nil) {
        BOOL resumeDataFileExists = [[NSFileManager defaultManager] fileExistsAtPath:localUrl.path];
        NSData *data = [NSData dataWithContentsOfURL:localUrl];
        BOOL resumeDataIsValid = [HJNetworkUtils validateResumeData:data];
        
        BOOL canBeResumed = resumeDataFileExists && resumeDataIsValid && !ignoreResumableData;
        // Try to resume with resumeData.
        // Even though we try to validate the resumeData, this may still fail and raise excecption.
        if (canBeResumed) {
            @try {
                downloadTask = [_manager downloadTaskWithResumeData:data
                                                           progress:downloadProgressBlock
                                                        destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
                    return [NSURL fileURLWithPath:downloadTargetPath isDirectory:NO];
                } completionHandler: ^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
                    [self handleRequestResult:downloadTask responseObject:filePath error:error];
                }];
                resumeSucceeded = YES;
            } @catch (NSException *exception) {
                HJLog(@"Resume download failed, reason = %@", exception.reason);
                resumeSucceeded = NO;
            }
        }
    }
    
    if (!resumeSucceeded) {
        downloadTask = [_manager downloadTaskWithRequest:urlRequest
                                                progress:downloadProgressBlock
                                             destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
            return [NSURL fileURLWithPath:downloadTargetPath isDirectory:NO];
        } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
            [self handleRequestResult:downloadTask responseObject:filePath error:error];
        }];
    }
    
    return downloadTask;
}

- (void)handleRequestResult:(NSURLSessionTask *)task responseObject:(id)responseObject error:(NSError *)error {
    Lock();
    HJCoreRequest *request = _requestsRecord[@(task.taskIdentifier)];
    Unlock();
    
    if (!request) return;
    
    HJLog(@"Finished Request: %@", NSStringFromClass([request class]));
    
    NSError * __autoreleasing validationError = nil;
    NSError * __autoreleasing serializationError = nil;
    request.responseObject = responseObject;
    if ([request.responseObject isKindOfClass:[NSData class]]) {
        request.responseData = responseObject;
        request.responseString = [[NSString alloc] initWithData:responseObject encoding:[HJNetworkUtils stringEncodingWithRequest:request]];
        switch (request.responseSerializerType) {
            case HJResponseSerializerTypeHTTP: {
            } break;
            case HJResponseSerializerTypeJSON: {
                self.jsonResponseSerializer.removesKeysWithNullValues = request.removesKeysWithNullValues;
                request.responseObject = [self.jsonResponseSerializer responseObjectForResponse:task.response
                                                                                           data:request.responseData
                                                                                          error:&serializationError];
                request.responseJSONObject = request.responseObject;
            } break;
            case HJResponseSerializerTypeXMLParser: {
                request.responseObject = [self.xmlParserResponseSerialzier responseObjectForResponse:task.response
                                                                                                data:request.responseData
                                                                                               error:&serializationError];
            } break;
        }
    }
    
    BOOL succeed = NO;
    NSError *requestError = nil;
    if (error) {
        succeed = NO;
        requestError = error;
    } else if (serializationError) {
        succeed = NO;
        requestError = serializationError;
    } else {
        succeed = [self validateResult:request error:&validationError];
        requestError = validationError;
    }
    
    if (succeed) {
        [self requestDidSucceedWithRequest:request];
    } else {
        [self requestDidFailWithRequest:request error:requestError];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self removeRequestFromRecord:request];
        [request clearCompletionBlock];
    });
}

- (BOOL)validateResult:(HJCoreRequest *)request error:(NSError * _Nullable __autoreleasing *)error {
    BOOL result = [request statusCodeValidator];
    if (!result) {
        if (error) {
            NSString *desc = [NSString stringWithFormat:@"Invalid status code (%ld)", (long)[request responseStatusCode]];
            *error = [NSError errorWithDomain:HJRequestValidationErrorDomain
                                         code:HJRequestValidationErrorInvalidStatusCode
                                     userInfo:@{NSLocalizedDescriptionKey:desc}];
        }
        return result;
    }
    
    id json = [request responseJSONObject];
    id validator = [request jsonValidator];
    if (json && validator) {
        result = [HJNetworkUtils validateJSON:json withValidator:validator];
        if (!result) {
            if (error) {
                *error = [NSError errorWithDomain:HJRequestValidationErrorDomain
                                             code:HJRequestValidationErrorInvalidJSONFormat
                                         userInfo:@{NSLocalizedDescriptionKey:@"Invalid JSON format"}];
            }
            return result;
        }
    }
    
    /// Custom
    NSError * __autoreleasing customError = nil;
    result = [request customErrorValidator:&customError];
    if (result) {
        if (error) {
            if (customError) {
                *error = customError;
            } else {
                *error = [NSError errorWithDomain:HJRequestValidationErrorDomain
                                             code:HJRequestValidationErrorInvalidCustomError
                                         userInfo:@{NSLocalizedDescriptionKey:@"Invalid custom error"}];
            }
        }
        return !result;
    }
    
    return YES;
}

- (void)requestDidSucceedWithRequest:(HJCoreRequest *)request {
    @autoreleasepool {
        [request requestCompletePreprocessor];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [request toggleAccessoriesWillStopCallBack];
        [request requestCompleteFilter];
        
        if (request.delegate != nil) {
            [request.delegate requestFinished:request];
        }
        if (request.successCompletionBlock) {
            request.successCompletionBlock(request);
        }
        [request toggleAccessoriesDidStopCallBack];
    });
}

- (void)requestDidFailWithRequest:(HJCoreRequest *)request error:(NSError *)error {
    request.error = error;
    HJLog(@"Failed Request %@, status code = %ld, error = %@", NSStringFromClass([request class]), (long)request.responseStatusCode, error.localizedDescription);
    
    // Save incomplete download data.
    NSData *incompleteDownloadData = error.userInfo[NSURLSessionDownloadTaskResumeData];
    NSURL *localUrl = nil;
    if (request.resumableDownloadPath) {
        localUrl = [self incompleteDownloadTempPathForDownloadPath:request.resumableDownloadPath];
    }
    if (incompleteDownloadData && localUrl != nil) {
        if (!request.ignoreResumableData) {
            [incompleteDownloadData writeToURL:localUrl atomically:YES];
        }
    }
    
    // Load response from file and clean up if download task failed.
    if ([request.responseObject isKindOfClass:[NSURL class]]) {
        NSURL *url = request.responseObject;
        if (url.isFileURL && [[NSFileManager defaultManager] fileExistsAtPath:url.path]) {
            request.responseData = [NSData dataWithContentsOfURL:url];
            request.responseString = [[NSString alloc] initWithData:request.responseData encoding:[HJNetworkUtils stringEncodingWithRequest:request]];
            
            [[NSFileManager defaultManager] removeItemAtURL:url error:nil];
        }
        request.responseObject = nil;
    }
    
    @autoreleasepool {
        [request requestFailedPreprocessor];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [request toggleAccessoriesWillStopCallBack];
        [request requestFailedFilter];
        
        if (request.delegate != nil) {
            [request.delegate requestFailed:request];
        }
        if (request.failureCompletionBlock) {
            request.failureCompletionBlock(request);
        }
        [request toggleAccessoriesDidStopCallBack];
    });
}

#pragma mark - Resumable Download

- (NSURL *)incompleteDownloadTempPathForDownloadPath:(NSString *)downloadPath {
    if (downloadPath == nil || downloadPath.length == 0) return nil;
    
    NSString *tempPath = nil;
    NSString *md5URLString = [HJNetworkUtils md5StringFromString:downloadPath];
    tempPath = [[self incompleteDownloadTempCacheFolder] stringByAppendingPathComponent:md5URLString];
    return tempPath == nil ? nil : [NSURL fileURLWithPath:tempPath];
}

- (NSString *)incompleteDownloadTempCacheFolder {
    NSFileManager *fileManager = [NSFileManager new];
    NSString *cacheFolder = [NSTemporaryDirectory() stringByAppendingPathComponent:kHJNetworkIncompleteDownloadFolderName];
    
    BOOL isDirectory = NO;
    if ([fileManager fileExistsAtPath:cacheFolder isDirectory:&isDirectory] && isDirectory) {
        return cacheFolder;
    }
    
    NSError *error = nil;
    if ([fileManager createDirectoryAtPath:cacheFolder withIntermediateDirectories:YES attributes:nil error:&error] && error == nil) {
        return cacheFolder;
    }
    
    HJLog(@"Failed to create cache directory at %@ with error: %@", cacheFolder, error != nil ? error.localizedDescription : @"unkown");
    return nil;
}

#pragma mark - Testing

- (AFHTTPSessionManager *)manager {
    return _manager;
}

- (void)resetURLSessionManager {
    _manager = [AFHTTPSessionManager manager];
}

- (void)resetURLSessionManagerWithConfiguration:(NSURLSessionConfiguration *)configuration {
    _manager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:configuration];
}

@end
