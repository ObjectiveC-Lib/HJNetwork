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

#if __has_include(<AFNetworking/AFNetworking.h>)
#import <AFNetworking/AFNetworking.h>
#else
#import "AFNetworking.h"
#endif

#define Lock() pthread_mutex_lock(&_lock)
#define Unlock() pthread_mutex_unlock(&_lock)

#define kHJNetworkIncompleteDownloadFolderName @"Incomplete"

@implementation HJNetworkAgent
{
    AFHTTPSessionManager *_manager;
    HJNetworkConfig *_config;
    AFJSONResponseSerializer *_jsonResponseSerializer;
    AFXMLParserResponseSerializer *_xmlParserResponseSerialzier;
    NSMutableDictionary<NSNumber *, HJBaseRequest *> *_requestsRecord;
    
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
        
        _manager.securityPolicy = _config.securityPolicy;
        _manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        // Take over the status code validation
        _manager.responseSerializer.acceptableStatusCodes = _allStatusCodes;
        _manager.completionQueue = _processingQueue;
    }
    return self;
}

- (AFJSONResponseSerializer *)jsonResponseSerializer {
    if (!_jsonResponseSerializer) {
        _jsonResponseSerializer = [AFJSONResponseSerializer serializer];
        _jsonResponseSerializer.acceptableStatusCodes = _allStatusCodes;
    }
    return _jsonResponseSerializer;
}

- (AFXMLParserResponseSerializer *)xmlParserResponseSerialzier {
    if (!_xmlParserResponseSerialzier) {
        _xmlParserResponseSerialzier = [AFXMLParserResponseSerializer serializer];
        _xmlParserResponseSerialzier.acceptableStatusCodes = _allStatusCodes;
    }
    return _xmlParserResponseSerialzier;
}

- (void)setAcceptableContentTypes:(HJBaseRequest *)request {
    NSString *type = [request acceptableContentType];
    if (type.length) {
        NSMutableSet *tmpSet = [NSMutableSet setWithSet:self.jsonResponseSerializer.acceptableContentTypes];
        [tmpSet addObject:type];
        self.jsonResponseSerializer.acceptableContentTypes = tmpSet;
    }
}

- (void)resetAcceptableContentTypes:(HJBaseRequest *)request {
    NSString *type = [request acceptableContentType];
    if (type.length) {
        NSMutableSet *tmpSet = [NSMutableSet setWithSet:self.jsonResponseSerializer.acceptableContentTypes];
        [tmpSet removeObject:type];
        self.jsonResponseSerializer.acceptableContentTypes = tmpSet;
    }
}

#pragma mark -

- (NSString *)buildRequestUrl:(HJBaseRequest *)request {
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

- (id)buildRequestArgument:(HJBaseRequest *)request {
    NSParameterAssert(request != nil);
    if (request.requestMethod == HJRequestMethodGET ||
        request.requestMethod == HJRequestMethodHEAD ||
        request.requestMethod == HJRequestMethodDELETE) return @{};
    return [self handleRequestArgument:request urlEncode:YES];
}

- (NSURL *)handleRequestURL:(HJBaseRequest *)request urlEncode:(BOOL)urlEncode {
    NSString *detailUrl = [request requestUrl];
    NSArray *filters = [_config urlFilters];
    for (id<HJUrlFilterProtocol> f in filters) {
        detailUrl = [f filterUrl:detailUrl urlEncode:urlEncode withRequest:request];
    }
    return [NSURL URLWithString:detailUrl?:@""];
}

- (NSDictionary *)handleRequestArgument:(HJBaseRequest *)request urlEncode:(BOOL)urlEncode {
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

- (AFHTTPRequestSerializer *)requestSerializerForRequest:(HJBaseRequest *)request {
    AFHTTPRequestSerializer *requestSerializer = nil;
    if (request.requestSerializerType == HJRequestSerializerTypeHTTP) {
        requestSerializer = [AFHTTPRequestSerializer serializer];
    } else if (request.requestSerializerType == HJRequestSerializerTypeJSON) {
        requestSerializer = [AFJSONRequestSerializer serializer];
    }
    
    requestSerializer.timeoutInterval = [request requestTimeoutInterval];
    requestSerializer.allowsCellularAccess = [request allowsCellularAccess];
    
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
    return requestSerializer;
}

- (NSURLSessionTask *)sessionTaskForRequest:(HJBaseRequest *)request error:(NSError * _Nullable __autoreleasing *)error {
    HJRequestMethod method = [request requestMethod];
    NSString *url = [self buildRequestUrl:request];
    id param = [self buildRequestArgument:request];
    AFConstructingBlock constructingBlock = [request constructingBodyBlock];
    AFHTTPRequestSerializer *requestSerializer = [self requestSerializerForRequest:request];
    
    switch (method) {
        case HJRequestMethodGET:
            if (request.resumableDownloadPath) {
                return [self downloadTaskWithDownloadPath:request.resumableDownloadPath
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
        case HJRequestMethodPOST:
            return [self dataTaskWithHTTPMethod:@"POST"
                              requestSerializer:requestSerializer
                                      URLString:url
                                     parameters:param
                      constructingBodyWithBlock:constructingBlock
                            uploadProgressBlock:request.uploadProgressBlock
                          downloadProgressBlock:request.downloadProgressBlock
                                          error:error];
        case HJRequestMethodHEAD:
            return [self dataTaskWithHTTPMethod:@"HEAD"
                              requestSerializer:requestSerializer
                                      URLString:url
                                     parameters:param
                                          error:error];
        case HJRequestMethodPUT:
            return [self dataTaskWithHTTPMethod:@"PUT"
                              requestSerializer:requestSerializer
                                      URLString:url
                                     parameters:param
                                          error:error];
        case HJRequestMethodDELETE:
            return [self dataTaskWithHTTPMethod:@"DELETE"
                              requestSerializer:requestSerializer
                                      URLString:url
                                     parameters:param
                                          error:error];
        case HJRequestMethodPATCH:
            return [self dataTaskWithHTTPMethod:@"PATCH"
                              requestSerializer:requestSerializer
                                      URLString:url
                                     parameters:param
                                          error:error];
    }
}

- (void)addRequest:(HJBaseRequest *)request {
    NSParameterAssert(request != nil);
    
    NSError * __autoreleasing requestSerializationError = nil;
    
    NSURLRequest *customUrlRequest= [request buildCustomUrlRequest];
    if (customUrlRequest) {
        __block NSURLSessionDataTask *dataTask = nil;
        dataTask = [_manager dataTaskWithRequest:customUrlRequest
                                  uploadProgress:request.uploadProgressBlock
                                downloadProgress:request.downloadProgressBlock
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
    
    // Set request task priority
    // !!Available on iOS 8 +
    if (@available(iOS 8.0, *)) {
        if ([request.requestTask respondsToSelector:@selector(priority)]) {
            switch (request.requestPriority) {
                case HJRequestPriorityHigh:
                    request.requestTask.priority = NSURLSessionTaskPriorityHigh;
                    break;
                case HJRequestPriorityLow:
                    request.requestTask.priority = NSURLSessionTaskPriorityLow;
                    break;
                case HJRequestPriorityDefault: /*!!fall through*/
                default:
                    request.requestTask.priority = NSURLSessionTaskPriorityDefault;
                    break;
            }
        }
    } else {
        // Fallback on earlier versions
    }
    
    // Retain request
    //    HJLog(@"Add request: %@", NSStringFromClass([request class]));
    [self addRequestToRecord:request];
    [request.requestTask resume];
    request.requestStartTime = [[NSDate date] timeIntervalSince1970];
}

- (void)cancelRequest:(HJBaseRequest *)request {
    NSParameterAssert(request != nil);
    
    if (request.resumableDownloadPath) {
        NSURLSessionDownloadTask *requestTask = (NSURLSessionDownloadTask *)request.requestTask;
        [requestTask cancelByProducingResumeData:^(NSData *resumeData) {
            NSURL *localUrl = [self incompleteDownloadTempPathForDownloadPath:request.resumableDownloadPath];
            [resumeData writeToURL:localUrl atomically:YES];
        }];
    } else {
        [request.requestTask cancel];
    }
    
    [self removeRequestFromRecord:request];
    [request clearCompletionBlock];
}

- (void)cancelAllRequests {
    Lock();
    NSArray *allKeys = [_requestsRecord allKeys];
    Unlock();
    if (allKeys && allKeys.count > 0) {
        NSArray *copiedKeys = [allKeys copy];
        for (NSNumber *key in copiedKeys) {
            Lock();
            HJBaseRequest *request = _requestsRecord[key];
            Unlock();
            // We are using non-recursive lock.
            // Do not lock `stop`, otherwise deadlock may occur.
            [request stop];
        }
    }
}

- (BOOL)validateResult:(HJBaseRequest *)request error:(NSError * _Nullable __autoreleasing *)error {
    BOOL result = [request statusCodeValidator];
    if (!result) {
        if (error) {
            *error = [NSError errorWithDomain:HJRequestValidationErrorDomain
                                         code:HJRequestValidationErrorInvalidStatusCode
                                     userInfo:@{NSLocalizedDescriptionKey:@"Invalid status code"}];
        }
        return result;
    }
    
    BOOL custom = [request customCodeValidator];
    if (!custom) {
        if (error) {
            *error = [NSError errorWithDomain:HJRequestValidationErrorDomain
                                         code:HJRequestValidationErrorInvalidCustomCode
                                     userInfo:@{NSLocalizedDescriptionKey:@"Invalid custom code"}];
        }
        return custom;
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
    return YES;
}

- (void)handleRequestResult:(NSURLSessionTask *)task responseObject:(id)responseObject error:(NSError *)error {
    Lock();
    HJBaseRequest *request = _requestsRecord[@(task.taskIdentifier)];
    Unlock();
    
    // When the request is cancelled and removed from records, the underlying
    // HJNetwork failure callback will still kicks in, resulting in a nil `request`.
    //
    // Here we choose to completely ignore cancelled tasks. Neither success or failure
    // callback will be called.
    if (!request) {
        return;
    }
    request.requestStopTime = [[NSDate date] timeIntervalSince1970];

    HJLog(@"Finished Request: %@", NSStringFromClass([request class]));
    
    NSError * __autoreleasing serializationError = nil;
    NSError * __autoreleasing validationError = nil;
    
    NSError *requestError = nil;
    BOOL succeed = NO;
    
    request.responseObject = responseObject;
    if ([request.responseObject isKindOfClass:[NSData class]]) {
        request.responseData = responseObject;
        request.responseString = [[NSString alloc] initWithData:responseObject encoding:[HJNetworkUtils stringEncodingWithRequest:request]];
        
        switch (request.responseSerializerType) {
            case HJResponseSerializerTypeHTTP: // Default serializer. Do nothing.
                break;
            case HJResponseSerializerTypeJSON:
                [self setAcceptableContentTypes:request];
                request.responseObject = [self.jsonResponseSerializer responseObjectForResponse:task.response data:request.responseData error:&serializationError];
                request.responseJSONObject = request.responseObject;
                [self resetAcceptableContentTypes:request];
                break;
            case HJResponseSerializerTypeXMLParser:
                request.responseObject = [self.xmlParserResponseSerialzier responseObjectForResponse:task.response data:request.responseData error:&serializationError];
                break;
        }
    }
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

- (void)requestDidSucceedWithRequest:(HJBaseRequest *)request {
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

- (void)requestDidFailWithRequest:(HJBaseRequest *)request error:(NSError *)error {
    request.error = error;
    HJLog(@"Request %@ failed, status code = %ld, error = %@",
          NSStringFromClass([request class]), (long)request.responseStatusCode, error.localizedDescription);
    
    // Save incomplete download data.
    NSData *incompleteDownloadData = error.userInfo[NSURLSessionDownloadTaskResumeData];
    if (incompleteDownloadData) {
        [incompleteDownloadData writeToURL:[self incompleteDownloadTempPathForDownloadPath:request.resumableDownloadPath] atomically:YES];
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

- (void)addRequestToRecord:(HJBaseRequest *)request {
    Lock();
    _requestsRecord[@(request.requestTask.taskIdentifier)] = request;
    Unlock();
}

- (void)removeRequestFromRecord:(HJBaseRequest *)request {
    Lock();
    [_requestsRecord removeObjectForKey:@(request.requestTask.taskIdentifier)];
    //    HJLog(@"Request queue size = %zd", [_requestsRecord count]);
    Unlock();
}

#pragma mark -

- (NSURLSessionDataTask *)dataTaskWithHTTPMethod:(NSString *)method
                               requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
                                       URLString:(NSString *)URLString
                                      parameters:(id)parameters
                                           error:(NSError * _Nullable __autoreleasing *)error {
    return [self dataTaskWithHTTPMethod:method requestSerializer:requestSerializer URLString:URLString parameters:parameters constructingBodyWithBlock:nil uploadProgressBlock:nil downloadProgressBlock:nil error:error];
}

- (NSURLSessionDataTask *)dataTaskWithHTTPMethod:(NSString *)method
                               requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
                                       URLString:(NSString *)URLString
                                      parameters:(id)parameters
                       constructingBodyWithBlock:(nullable void (^)(id <AFMultipartFormData> formData))block
                             uploadProgressBlock:(nullable void (^)(NSProgress *uploadProgress))uploadProgressBlock
                           downloadProgressBlock:(nullable void (^)(NSProgress *downloadProgress))downloadProgressBlock
                                           error:(NSError * _Nullable __autoreleasing *)error {
    NSMutableURLRequest *request = nil;
    
    if (block) {
        request = [requestSerializer multipartFormRequestWithMethod:method URLString:URLString parameters:parameters constructingBodyWithBlock:block error:error];
    } else {
        request = [requestSerializer requestWithMethod:method URLString:URLString parameters:parameters error:error];
    }
    
    __block NSURLSessionDataTask *dataTask = nil;
    dataTask = [_manager dataTaskWithRequest:request
                              uploadProgress:uploadProgressBlock
                            downloadProgress:downloadProgressBlock
                           completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
                               [self handleRequestResult:dataTask responseObject:responseObject error:error];
                           }];
    return dataTask;
}

- (NSURLSessionDownloadTask *)downloadTaskWithDownloadPath:(NSString *)downloadPath
                                         requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
                                                 URLString:(NSString *)URLString
                                                parameters:(id)parameters
                                                  progress:(nullable void (^)(NSProgress *downloadProgress))downloadProgressBlock
                                                     error:(NSError * _Nullable __autoreleasing *)error {
    // add parameters to URL;
    NSMutableURLRequest *urlRequest = [requestSerializer requestWithMethod:@"GET" URLString:URLString parameters:parameters error:error];
    
    NSString *downloadTargetPath;
    BOOL isDirectory;
    if(![[NSFileManager defaultManager] fileExistsAtPath:downloadPath isDirectory:&isDirectory]) {
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
    
    BOOL resumeDataFileExists = [[NSFileManager defaultManager] fileExistsAtPath:[self incompleteDownloadTempPathForDownloadPath:downloadPath].path];
    NSData *data = [NSData dataWithContentsOfURL:[self incompleteDownloadTempPathForDownloadPath:downloadPath]];
    BOOL resumeDataIsValid = [HJNetworkUtils validateResumeData:data];
    
    BOOL canBeResumed = resumeDataFileExists && resumeDataIsValid;
    BOOL resumeSucceeded = NO;
    __block NSURLSessionDownloadTask *downloadTask = nil;
    // Try to resume with resumeData.
    // Even though we try to validate the resumeData, this may still fail and raise excecption.
    if (canBeResumed) {
        @try {
            downloadTask = [_manager downloadTaskWithResumeData:data
                                                       progress:downloadProgressBlock
                                                    destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
                                                        return [NSURL fileURLWithPath:downloadTargetPath isDirectory:NO];
                                                    }
                                              completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
                                                  [self handleRequestResult:downloadTask responseObject:filePath error:error];
                                              }];
            resumeSucceeded = YES;
        }
        @catch (NSException *exception) {
            HJLog(@"Resume download failed, reason = %@", exception.reason);
            resumeSucceeded = NO;
        }
    }
    if (!resumeSucceeded) {
        downloadTask = [_manager downloadTaskWithRequest:urlRequest
                                                progress:downloadProgressBlock
                                             destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
                                                 return [NSURL fileURLWithPath:downloadTargetPath isDirectory:NO];
                                             }
                                       completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
                                           [self handleRequestResult:downloadTask responseObject:filePath error:error];
                                       }];
    }
    return downloadTask;
}

#pragma mark - Resumable Download

- (NSString *)incompleteDownloadTempCacheFolder {
    NSFileManager *fileManager = [NSFileManager new];
    static NSString *cacheFolder;
    
    if (!cacheFolder) {
        NSString *cacheDir = NSTemporaryDirectory();
        cacheFolder = [cacheDir stringByAppendingPathComponent:kHJNetworkIncompleteDownloadFolderName];
    }
    
    NSError *error = nil;
    if(![fileManager createDirectoryAtPath:cacheFolder withIntermediateDirectories:YES attributes:nil error:&error]) {
        HJLog(@"Failed to create cache directory at %@", cacheFolder);
        cacheFolder = nil;
    }
    return cacheFolder;
}

- (NSURL *)incompleteDownloadTempPathForDownloadPath:(NSString *)downloadPath {
    NSString *tempPath = nil;
    NSString *md5URLString = [HJNetworkUtils md5StringFromString:downloadPath];
    tempPath = [[self incompleteDownloadTempCacheFolder] stringByAppendingPathComponent:md5URLString];
    return [NSURL fileURLWithPath:tempPath];
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
