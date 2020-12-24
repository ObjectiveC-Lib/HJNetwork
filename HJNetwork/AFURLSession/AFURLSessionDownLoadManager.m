//
//  AFURLSessionDownLoadManager.m
//  BJEducation_student
//
//  Created by Mrlu-bjhl on 2016/11/9.
//  Copyright © 2016年 Baijiahulian. All rights reserved.
//

#import "AFURLSessionDownLoadManager.h"
#import <CommonCrypto/CommonDigest.h>
#include <fcntl.h>
#include <unistd.h>

static NSString *const AFURLSessionDownloaderCacheFolderName = @"Incomplete";

typedef void (^AFURLSessionProgressiveOperationProgressBlock)(AFURLSessionDownloadTask *task, NSInteger bytes,
                                                              long long totalBytes,
                                                              long long totalBytesExpected,
                                                              long long totalBytesReadForFile,
                                                              long long totalBytesExpectedToReadForFile);

@interface AFURLSessionDownloadTask () {
}

@property (nonatomic, strong) NSError *fileError;
@property (nonatomic, strong) NSError *responseSerializationError;
@property (nonatomic, strong) id responseObject;

@property (nonatomic, strong) NSOutputStream *outputStream;

@property (nonatomic, strong) NSString *tempPath;
@property (nonatomic, assign) long long totalContentLength;
@property (nonatomic, assign) long long offsetContentLength;
@property (nonatomic, assign) long long totalBytesReadPerDownload;
@property (nonatomic, copy) AFURLSessionProgressiveOperationProgressBlock progressiveDownloadProgress;

@end


@implementation AFURLSessionDownloadTask

- (instancetype)initWithTask:(NSURLSessionDataTask *)task
                  targetPath:(NSString *)targetPath
                   cachePath:(NSString *)cachePath
                shouldResume:(BOOL)shouldResume
                  isResuming:(BOOL)isResuming {
    self = [super init];
    if (self) {
        _task = task;
        _shouldResume = shouldResume;
        
        // Ee assume that at least the directory has to exist on the targetPath
        BOOL isDirectory;
        if(![[NSFileManager defaultManager] fileExistsAtPath:targetPath isDirectory:&isDirectory]) {
            isDirectory = NO;
        }
        // If targetPath is a directory, use the file name we got from the urlRequest.
        if (isDirectory) {
            NSString *fileName = [self.task.currentRequest.URL lastPathComponent];
            _targetPath = [NSString pathWithComponents:@[targetPath, fileName]];
        }else {
            _targetPath = targetPath;
        }
        
        _cachePath = cachePath;
        
        // Download is saved into a temorary file and renamed upon completion.
        NSString *tempPath = [self tempPath];
        
        // Try to create/open a file at the target location
        if (!isResuming) {
            int fileDescriptor = open([tempPath UTF8String], O_CREAT | O_EXCL | O_RDWR, 0666);
            if (fileDescriptor > 0) close(fileDescriptor);
        }
        
        self.outputStream = [NSOutputStream outputStreamToFileAtPath:tempPath append:isResuming];
        // If the output stream can't be created, instantly destroy the object.
        if (!self.outputStream) {
            NSLog(@"%@ outputStream",NSStringFromClass(self.class));
        }
    }
    return self;
}

- (void)setProgressiveDownloadProgressBlock:(void (^)(AFURLSessionDownloadTask *task,
                                                      NSInteger bytesRead,
                                                      long long totalBytesRead,
                                                      long long totalBytesExpected,
                                                      long long totalBytesReadForFile,
                                                      long long totalBytesExpectedToReadForFile)) block {
    self.progressiveDownloadProgress = block;
}

- (void)setProgressiveDownloadCallbackQueue:(dispatch_queue_t)progressiveDownloadCallbackQueue {
    if (progressiveDownloadCallbackQueue != _progressiveDownloadCallbackQueue) {
        if (_progressiveDownloadCallbackQueue) {
#if !OS_OBJECT_USE_OBJC
            dispatch_release(_progressiveDownloadCallbackQueue);
#endif
            _progressiveDownloadCallbackQueue = NULL;
        }
        
        if (progressiveDownloadCallbackQueue) {
#if !OS_OBJECT_USE_OBJC
            dispatch_retain(progressiveDownloadCallbackQueue);
#endif
            _progressiveDownloadCallbackQueue = progressiveDownloadCallbackQueue;
        }
    }
}

#pragma mark - Private

- (unsigned long long)fileSizeForPath:(NSString *)path {
    signed long long fileSize = 0;
    NSFileManager *fileManager = [NSFileManager new]; // default is not thread safe
    if ([fileManager fileExistsAtPath:path]) {
        NSError *error = nil;
        NSDictionary *fileDict = [fileManager attributesOfItemAtPath:path error:&error];
        if (!error && fileDict) {
            fileSize = [fileDict fileSize];
        }
    }
    return fileSize;
}

#pragma mark - Public

- (BOOL)deleteTempFileWithError:(NSError *__autoreleasing*)error {
    NSFileManager *fileManager = [NSFileManager new];
    BOOL success = YES;
    @synchronized(self) {
        NSString *tempPath = [self tempPath];
        if ([fileManager fileExistsAtPath:tempPath]) {
            success = [fileManager removeItemAtPath:[self tempPath] error:error];
        }
    }
    return success;
}

- (NSString *)tempPath {
    NSString *tempPath = self.cachePath;
    if (!tempPath) {
        if (self.targetPath) {
            NSString *md5URLString = [[self class] md5StringForString:self.targetPath];
            tempPath = [[[self class] cacheFolder] stringByAppendingPathComponent:md5URLString];
        }
    }
    
    return tempPath;
}

#pragma mark - Static

+ (NSString *)cacheFolder {
    NSFileManager *filemgr = [NSFileManager new];
    static NSString *cacheFolder;
    
    if (!cacheFolder) {
        NSString *cacheDir = NSTemporaryDirectory();
        cacheFolder = [cacheDir stringByAppendingPathComponent:AFURLSessionDownloaderCacheFolderName];
    }
    
    // ensure all cache directories are there
    NSError *error = nil;
    if(![filemgr createDirectoryAtPath:cacheFolder withIntermediateDirectories:YES attributes:nil error:&error]) {
        NSLog(@"Failed to create cache directory at %@", cacheFolder);
        cacheFolder = nil;
    }
    return cacheFolder;
}

// calculates the MD5 hash of a key
+ (NSString *)md5StringForString:(NSString *)string {
    const char *str = [string UTF8String];
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (uint32_t)strlen(str), r);
    return [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10], r[11], r[12], r[13], r[14], r[15]];
}

- (void)resume {
    [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [self.outputStream open];
    [self.task resume];
}

@end

@implementation AFURLSessionDownLoadManager

+ (instancetype)manager {
    return [[AFURLSessionDownLoadManager alloc] initWithBaseURL:nil];
}

- (instancetype)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (self) {
        self.afDownloadTasks = [NSMutableArray array];
    }
    return self;
}

- (AFURLSessionDownloadTask *)downloadTaskBreakPointsWithRequest:(NSURLRequest *)request
                                                      targetPath:(NSString *)targetPath
                                                       cachePath:(NSString *)cachePath
                                                    shouldResume:(BOOL)shouldResume
                                               completionHandler:(void (^)(NSURLResponse *response, id responseObject, NSError *error))completionHandler {
    // Ee assume that at least the directory has to exist on the targetPath
    BOOL isDirectory;
    if(![[NSFileManager defaultManager] fileExistsAtPath:targetPath isDirectory:&isDirectory]) {
        isDirectory = NO;
    }
    // If targetPath is a directory, use the file name we got from the urlRequest.
    if (isDirectory) {
        NSString *fileName = [request.URL lastPathComponent];
        targetPath = [NSString pathWithComponents:@[targetPath, fileName]];
    }
    
    // Download is saved into a temorary file and renamed upon completion.
    NSString *tempPath = cachePath;
    if (!tempPath) {
        if (targetPath) {
            NSString *md5URLString = [[self class] md5StringForString:targetPath];
            tempPath = [[[self class] cacheFolder] stringByAppendingPathComponent:md5URLString];
        }
    }
    
    NSMutableURLRequest *mutableRequest = [request mutableCopy];
    // Do we need to resume the file?
    BOOL isResuming = [self updateByteStartRangeForRequestWithRequest:mutableRequest shouldResume:shouldResume tempPath:tempPath];
    
    NSURLSessionDataTask *task = [self dataTaskWithRequest:mutableRequest
                                            uploadProgress:nil
                                          downloadProgress:nil
                                         completionHandler:completionHandler];
    AFURLSessionDownloadTask *afTask = [[AFURLSessionDownloadTask alloc]initWithTask:task
                                                                          targetPath:targetPath
                                                                           cachePath:cachePath
                                                                        shouldResume:shouldResume
                                                                          isResuming:isResuming];
    [self.afDownloadTasks addObject:afTask];
    return afTask;
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    AFURLSessionDownloadTask *downloadTask = [self getAFDownloadTaskForDataTask:dataTask];
    if (downloadTask) {
        // check if we have the correct response
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (![httpResponse isKindOfClass:[NSHTTPURLResponse class]]) return;
        
        // check for valid response to resume the download if possible
        long long totalContentLength = downloadTask.task.response.expectedContentLength;
        long long fileOffset = 0;
        if(httpResponse.statusCode == 206) {
            NSString *contentRange = [httpResponse.allHeaderFields valueForKey:@"Content-Range"];
            if ([contentRange hasPrefix:@"bytes"]) {
                NSArray *bytes = [contentRange componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" -/"]];
                if ([bytes count] == 4) {
                    fileOffset = [bytes[1] longLongValue];
                    totalContentLength = [bytes[3] longLongValue]; // if this is *, it's converted to 0
                }
            }
        }
        
        downloadTask.totalBytesReadPerDownload = 0;
        downloadTask.offsetContentLength = MAX(fileOffset, 0);
        downloadTask.totalContentLength = totalContentLength;
        
        // Truncate cache file to offset provided by server.
        // Using self.outputStream setProperty:@(_offsetContentLength) forKey:NSStreamFileCurrentOffsetKey]; will not work (in contrary to the documentation)
        NSString *tempPath = [downloadTask tempPath];
        if ([self fileSizeForPath:tempPath] != downloadTask.offsetContentLength) {
            [downloadTask.outputStream close];
            BOOL isResuming = downloadTask.offsetContentLength > 0;
            NSError *error = nil;
            if (isResuming) {
                //manager 在准备写入文件时，应为空间不足导致崩溃
                NSFileHandle *file = [NSFileHandle fileHandleForWritingAtPath:tempPath];
                if (file) { // maybe nil init error
                    @try {
                        [file truncateFileAtOffset:downloadTask.offsetContentLength];
                    } @catch (NSException *exception) {
                        error = [NSError errorWithDomain:exception.reason
                                                    code:AFURLSessionDownloadTaskErrorNoSpace
                                                userInfo:exception.userInfo];
                        downloadTask.fileError = error;
                        downloadTask.responseObject = nil;
                    } @finally {
                        [file closeFile];
                    }
                } else {
                    error = [NSError errorWithDomain:[NSString stringWithFormat:@"%@",NSStringFromClass([self class])] code:AFURLSessionDownloadTaskErrorNoSpace userInfo:@{NSLocalizedFailureReasonErrorKey:@"no space"}];
                    downloadTask.fileError = error;
                    downloadTask.responseObject = nil;
                }
            }
            if (!error) {
                downloadTask.outputStream = [NSOutputStream outputStreamToFileAtPath:tempPath append:isResuming];
                [downloadTask.outputStream open];
            } else {
                completionHandler(NSURLSessionResponseCancel); //设置取消
                return;
            }
        }
    }
    
    [super URLSession:session dataTask:dataTask didReceiveResponse:response completionHandler:completionHandler];
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    AFURLSessionDownloadTask *downloadTask = [self getAFDownloadTaskForDataTask:dataTask];
    if (downloadTask) {
        NSUInteger length = [data length];
        while (YES) {
            NSInteger totalNumberOfBytesWritten = 0;
            if ([downloadTask.outputStream hasSpaceAvailable]) {
                const uint8_t *dataBuffer = (uint8_t *)[data bytes];
                
                NSInteger numberOfBytesWritten = 0;
                while (totalNumberOfBytesWritten < (NSInteger)length) {
                    numberOfBytesWritten = [downloadTask.outputStream write:&dataBuffer[(NSUInteger)totalNumberOfBytesWritten] maxLength:(length - (NSUInteger)totalNumberOfBytesWritten)];
                    if (numberOfBytesWritten == -1) {
                        break;
                    }
                    
                    totalNumberOfBytesWritten += numberOfBytesWritten;
                }
                
                break;
            }
            
            if (downloadTask.outputStream.streamError) {
                [dataTask cancel];
                [self URLSession:session task:dataTask didCompleteWithError:downloadTask.outputStream.streamError];
                return;
            }
        }
        
        // track custom bytes read because totalBytesRead persists between pause/resume.
        downloadTask.totalBytesReadPerDownload += [data length];
        
        if (downloadTask.progressiveDownloadProgress) {
            dispatch_async(downloadTask.progressiveDownloadCallbackQueue ?: dispatch_get_main_queue(), ^{
                downloadTask.progressiveDownloadProgress(downloadTask,(NSInteger)[data length], downloadTask.totalBytesReadPerDownload, downloadTask.task.response.expectedContentLength,downloadTask.totalBytesReadPerDownload + downloadTask.offsetContentLength, downloadTask.totalContentLength);
            });
        }
    }
}

#pragma mark - NSURLSessionDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    AFURLSessionDownloadTask *downloadTask = [self getAFDownloadTaskForDataTask:task];
    if (downloadTask) {
        [downloadTask.outputStream close];
        NSError *localError = nil;
        if (downloadTask.task.state == NSURLSessionTaskStateCanceling) {
            // should we clean up? most likely we don't.
            if (downloadTask.isDeletingTempFileOnCancel) {
                [downloadTask deleteTempFileWithError:&localError];
                if (localError) {
                    downloadTask.fileError = localError;
                }
            }
            // loss of network connections = error set, but not cancel
        } else if(!error) {
            // move file to final position and capture error
            NSFileManager *fileManager = [NSFileManager new];
            if (downloadTask.shouldOverwrite) {
                [fileManager removeItemAtPath:downloadTask.targetPath error:NULL]; // avoid "File exists" error
            }
            [fileManager moveItemAtPath:[downloadTask tempPath] toPath:downloadTask.targetPath error:&localError];
            if (localError) {
                downloadTask.fileError = localError;
            } else {
                downloadTask.responseObject = downloadTask.targetPath;
            }
        }
        if (downloadTask.fileError) {
            error = downloadTask.fileError;
        }
        [self removeAFDownloadTaskForDataTask:task];
    }
    
    [super URLSession:session task:task didCompleteWithError:error];
}

#pragma mark - Private

- (unsigned long long)fileSizeForPath:(NSString *)path {
    signed long long fileSize = 0;
    NSFileManager *fileManager = [NSFileManager new]; // default is not thread safe
    if ([fileManager fileExistsAtPath:path]) {
        NSError *error = nil;
        NSDictionary *fileDict = [fileManager attributesOfItemAtPath:path error:&error];
        if (!error && fileDict) {
            fileSize = [fileDict fileSize];
        }
    }
    return fileSize;
}

// updates the current request to set the correct start-byte-range.
- (BOOL)updateByteStartRangeForRequestWithRequest:(NSMutableURLRequest *)request
                                     shouldResume:(BOOL)shouldResume
                                         tempPath:(NSString *)tempPath {
    BOOL isResuming = NO;
    if (shouldResume) {
        unsigned long long downloadedBytes = [self fileSizeForPath:tempPath];
        if (downloadedBytes > 1) {
            
            // If the the current download-request's data has been fully downloaded, but other causes of the operation failed (such as the inability of the incomplete temporary file copied to the target location), next, retry this download-request, the starting-value (equal to the incomplete temporary file size) will lead to an HTTP 416 out of range error, unless we subtract one byte here. (We don't know the final size before sending the request)
            downloadedBytes--;
            
            NSString *requestRange = [NSString stringWithFormat:@"bytes=%llu-", downloadedBytes];
            
            NSMutableDictionary *allHTTPHeaderFields = [NSMutableDictionary dictionaryWithDictionary:request.allHTTPHeaderFields];
            [allHTTPHeaderFields setValue:requestRange forKey:@"Range"];
            request.allHTTPHeaderFields = allHTTPHeaderFields;
            isResuming = YES;
        }
    }
    return isResuming;
}

- (AFURLSessionDownloadTask *)getAFDownloadTaskForDataTask:(NSURLSessionTask *)task {
    AFURLSessionDownloadTask *downloadTask = nil;
    for (AFURLSessionDownloadTask *aDownloadTask in self.afDownloadTasks) {
        if ([aDownloadTask.task isEqual:task]) {
            downloadTask = aDownloadTask;
            break;
        }
    }
    return downloadTask;
}

- (BOOL)removeAFDownloadTaskForDataTask:(NSURLSessionTask *)task {
    AFURLSessionDownloadTask *downloadTask = [self getAFDownloadTaskForDataTask:task];
    if (downloadTask) {
        [self.afDownloadTasks removeObject:downloadTask];
        return YES;
    }
    return NO;
}

#pragma mark - Static

+ (NSString *)cacheFolder {
    NSFileManager *filemgr = [NSFileManager new];
    static NSString *cacheFolder;
    
    if (!cacheFolder) {
        NSString *cacheDir = NSTemporaryDirectory();
        cacheFolder = [cacheDir stringByAppendingPathComponent:AFURLSessionDownloaderCacheFolderName];
    }
    
    // ensure all cache directories are there
    NSError *error = nil;
    if(![filemgr createDirectoryAtPath:cacheFolder withIntermediateDirectories:YES attributes:nil error:&error]) {
        NSLog(@"Failed to create cache directory at %@", cacheFolder);
        cacheFolder = nil;
    }
    return cacheFolder;
}

// calculates the MD5 hash of a key
+ (NSString *)md5StringForString:(NSString *)string {
    const char *str = [string UTF8String];
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (uint32_t)strlen(str), r);
    return [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10], r[11], r[12], r[13], r[14], r[15]];
}

@end
