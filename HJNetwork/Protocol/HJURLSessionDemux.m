//
//  HJURLSessionDemux.m
//  HJNetwork
//
//  Created by navy on 2022/5/27.
//  Copyright © 2022 HJNetwork. All rights reserved.
//

#import "HJURLSessionDemux.h"

@interface HJURLSessionDemuxTaskInfo : NSObject

@property (atomic, strong, readonly) NSURLSessionDataTask *task;
@property (atomic, strong, readonly) id<NSURLSessionDataDelegate> delegate;
@property (atomic, strong, readonly) NSThread *thread;
@property (atomic, copy,   readonly) NSArray *modes;

- (instancetype)initWithTask:(NSURLSessionDataTask *)task delegate:(id<NSURLSessionDataDelegate>)delegate modes:(NSArray *)modes;
- (void)performBlock:(dispatch_block_t)block;
- (void)invalidate;

@end

@interface HJURLSessionDemuxTaskInfo ()

@property (atomic, strong, readwrite) id<NSURLSessionDataDelegate> delegate;
@property (atomic, strong, readwrite) NSThread *thread;

@end

@implementation HJURLSessionDemuxTaskInfo

- (instancetype)initWithTask:(NSURLSessionDataTask *)task delegate:(id<NSURLSessionDataDelegate>)delegate modes:(NSArray *)modes {
    assert(task != nil);
    assert(delegate != nil);
    assert(modes != nil);
    
    self = [super init];
    if (self != nil) {
        self->_task = task;
        self->_delegate = delegate;
        self->_thread = [NSThread currentThread];
        self->_modes = [modes copy];
    }
    return self;
}

- (void)performBlock:(dispatch_block_t)block {
    assert(self.delegate != nil);
    assert(self.thread != nil);
    [self performSelector:@selector(performBlockOnClientThread:)
                 onThread:self.thread
               withObject:[block copy]
            waitUntilDone:NO
                    modes:self.modes];
}

- (void)performBlockOnClientThread:(dispatch_block_t)block {
    assert([NSThread currentThread] == self.thread);
    block();
}

- (void)invalidate {
    self.delegate = nil;
    self.thread = nil;
}

@end


@interface HJURLSessionDemux () <NSURLSessionDataDelegate>

@property (atomic, strong, readonly) NSMutableDictionary *taskInfoByTaskID; /// keys NSURLSessionTask taskIdentifier, values are SessionManager
@property (atomic, strong, readonly) NSOperationQueue *sessionDelegateQueue;

@end


@implementation HJURLSessionDemux

- (instancetype)init {
    return [self initWithConfiguration:nil];
}

- (instancetype)initWithConfiguration:(NSURLSessionConfiguration *)configuration {
    self = [super init];
    if (self != nil) {
        if (configuration == nil) {
            configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        }
        self->_configuration = [configuration copy];
        self->_taskInfoByTaskID = [[NSMutableDictionary alloc] init];
        self->_sessionDelegateQueue = [[NSOperationQueue alloc] init];
        [self->_sessionDelegateQueue setMaxConcurrentOperationCount:1];
        [self->_sessionDelegateQueue setName:@"HJURLSessionDemux"];
        
        self->_session = [NSURLSession sessionWithConfiguration:self->_configuration
                                                       delegate:self
                                                  delegateQueue:self->_sessionDelegateQueue];
        self->_session.sessionDescription = @"HJURLSessionDemux";
    }
    return self;
}

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request delegate:(id<NSURLSessionDataDelegate>)delegate modes:(NSArray *)modes {
    NSURLSessionDataTask *task;
    HJURLSessionDemuxTaskInfo *taskInfo;
    
    assert(request != nil);
    assert(delegate != nil);
    
    if ([modes count] == 0) {
        modes = @[ NSDefaultRunLoopMode ];
    }
    
    task = [self.session dataTaskWithRequest:request];
    assert(task != nil);
    
    taskInfo = [[HJURLSessionDemuxTaskInfo alloc] initWithTask:task delegate:delegate modes:modes];
    
    @synchronized (self) {
        self.taskInfoByTaskID[@(task.taskIdentifier)] = taskInfo;
    }
    
    return task;
}

- (HJURLSessionDemuxTaskInfo *)taskInfoForTask:(NSURLSessionTask *)task {
    HJURLSessionDemuxTaskInfo *taskInfo;
    
    //    assert(task != nil);
    
    @synchronized (self) {
        taskInfo = self.taskInfoByTaskID[@(task.taskIdentifier)];
        //        assert(taskInfo != nil);
    }
    return taskInfo;
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response
        newRequest:(NSURLRequest *)newRequest
 completionHandler:(void (^)(NSURLRequest *))completionHandler {
    HJURLSessionDemuxTaskInfo *taskInfo = [self taskInfoForTask:task];
    if ([taskInfo.delegate respondsToSelector:@selector(URLSession:task:willPerformHTTPRedirection:newRequest:completionHandler:)]) {
        [taskInfo performBlock:^{
            [taskInfo.delegate URLSession:session
                                     task:task
               willPerformHTTPRedirection:response
                               newRequest:newRequest
                        completionHandler:completionHandler];
        }];
    } else {
        completionHandler(newRequest);
    }
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {
    HJURLSessionDemuxTaskInfo *taskInfo = [self taskInfoForTask:task];
    if ([taskInfo.delegate respondsToSelector:@selector(URLSession:task:didReceiveChallenge:completionHandler:)]) {
        [taskInfo performBlock:^{
            [taskInfo.delegate URLSession:session
                                     task:task
                      didReceiveChallenge:challenge
                        completionHandler:completionHandler];
        }];
    } else {
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task needNewBodyStream:(void (^)(NSInputStream *bodyStream))completionHandler {
    HJURLSessionDemuxTaskInfo *taskInfo = [self taskInfoForTask:task];
    if ([taskInfo.delegate respondsToSelector:@selector(URLSession:task:needNewBodyStream:)]) {
        [taskInfo performBlock:^{
            [taskInfo.delegate URLSession:session task:task needNewBodyStream:completionHandler];
        }];
    } else {
        completionHandler(nil);
    }
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
   didSendBodyData:(int64_t)bytesSent
    totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
    HJURLSessionDemuxTaskInfo *taskInfo = [self taskInfoForTask:task];
    if ([taskInfo.delegate respondsToSelector:@selector(URLSession:task:didSendBodyData:totalBytesSent:totalBytesExpectedToSend:)]) {
        [taskInfo performBlock:^{
            [taskInfo.delegate URLSession:session task:task didSendBodyData:bytesSent totalBytesSent:totalBytesSent totalBytesExpectedToSend:totalBytesExpectedToSend];
        }];
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    HJURLSessionDemuxTaskInfo *taskInfo = [self taskInfoForTask:task];
    
    // This is our last delegate callback so we remove our task info record.
    @synchronized (self) {
        [self.taskInfoByTaskID removeObjectForKey:@(taskInfo.task.taskIdentifier)];
    }
    
    if ([taskInfo.delegate respondsToSelector:@selector(URLSession:task:didCompleteWithError:)]) {
        [taskInfo performBlock:^{
            [taskInfo.delegate URLSession:session task:task didCompleteWithError:error];
            [taskInfo invalidate];
        }];
    } else {
        [taskInfo invalidate];
    }
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    HJURLSessionDemuxTaskInfo *taskInfo = [self taskInfoForTask:dataTask];
    if ([taskInfo.delegate respondsToSelector:@selector(URLSession:dataTask:didReceiveResponse:completionHandler:)]) {
        [taskInfo performBlock:^{
            [taskInfo.delegate URLSession:session dataTask:dataTask didReceiveResponse:response completionHandler:completionHandler];
        }];
    } else {
        completionHandler(NSURLSessionResponseAllow);
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didBecomeDownloadTask:(NSURLSessionDownloadTask *)downloadTask {
    HJURLSessionDemuxTaskInfo *taskInfo = [self taskInfoForTask:dataTask];
    if ([taskInfo.delegate respondsToSelector:@selector(URLSession:dataTask:didBecomeDownloadTask:)]) {
        [taskInfo performBlock:^{
            [taskInfo.delegate URLSession:session dataTask:dataTask didBecomeDownloadTask:downloadTask];
        }];
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    HJURLSessionDemuxTaskInfo *taskInfo = [self taskInfoForTask:dataTask];
    if ([taskInfo.delegate respondsToSelector:@selector(URLSession:dataTask:didReceiveData:)]) {
        [taskInfo performBlock:^{
            [taskInfo.delegate URLSession:session dataTask:dataTask didReceiveData:data];
        }];
    }
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
 willCacheResponse:(NSCachedURLResponse *)proposedResponse
 completionHandler:(void (^)(NSCachedURLResponse *cachedResponse))completionHandler {
    HJURLSessionDemuxTaskInfo *taskInfo = [self taskInfoForTask:dataTask];
    if ([taskInfo.delegate respondsToSelector:@selector(URLSession:dataTask:willCacheResponse:completionHandler:)]) {
        [taskInfo performBlock:^{
            [taskInfo.delegate URLSession:session dataTask:dataTask willCacheResponse:proposedResponse completionHandler:completionHandler];
        }];
    } else {
        completionHandler(proposedResponse);
    }
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didFinishCollectingMetrics:(NSURLSessionTaskMetrics *)metrics API_AVAILABLE(macosx(10.12), ios(10.0), watchos(3.0), tvos(10.0)) {
    HJURLSessionDemuxTaskInfo *taskInfo = [self taskInfoForTask:task];
    if ([taskInfo.delegate respondsToSelector:@selector(URLSession:task:didFinishCollectingMetrics:)]) {
        [taskInfo performBlock:^{
            [taskInfo.delegate URLSession:session task:task didFinishCollectingMetrics:metrics];
        }];
    }
}

@end
