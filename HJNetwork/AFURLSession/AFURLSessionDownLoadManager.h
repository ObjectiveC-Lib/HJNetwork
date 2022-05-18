//
//  AFURLSessionDownLoadManager.h
//  BJEducation_student
//
//  Created by Mrlu-bjhl on 2016/11/9.
//  Copyright © 2016年 Baijiahulian. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>

typedef NS_ENUM(NSUInteger, AFURLSessionDownloadTaskError) {
    AFURLSessionDownloadTaskErrorNoSpace = 3,
    AFURLSessionDownloadTaskErrorOther
};

@interface AFURLSessionDownloadTask : NSObject
/**
 A String value that defines the target path or directory.
 
 We try to be clever here and understand both a directory or a filename.
 The target directory should already be create, or the download fill fail.
 
 If the target is a directory, we use the last part of the URL as a default file name.
 targetPath is the responseObject if operation succeeds
 */
@property (strong) NSString *targetPath;

/**
 A String value that defines the cache path.
 */
@property (copy) NSString *cachePath;

/**
 A Boolean value that indicates if we should allow a downloaded file to overwrite
 a previously downloaded file of the same name. Default is `NO`.
 */
@property (assign) BOOL shouldOverwrite;

/**
 A Boolean value that indicates if we should try to resume the download. Defaults is `YES`.
 
 Can only be set while creating the request.
 */
@property (assign, readonly) BOOL shouldResume;

/**
 Deletes the temporary file if operations is cancelled. Defaults to `NO`.
 */
@property (assign, getter=isDeletingTempFileOnCancel) BOOL deleteTempFileOnCancel;

/**
 Expected total length. This is different than expectedContentLength if the file is resumed.
 
 Note: this can also be zero if the file size is not sent (*)
 */
@property (assign, readonly) long long totalContentLength;

/**
 Indicator for the file offset on partial downloads. This is greater than zero if the file download is resumed.
 */
@property (assign, readonly) long long offsetContentLength;

/**
 The callback dispatch queue on progressive download. If `NULL` (default), the main queue is used.
 */
@property (nonatomic, assign) dispatch_queue_t progressiveDownloadCallbackQueue;

@property (nonatomic, assign) NSURLSessionDataTask *task;

///----------------------------------
/// @name Creating Request Operations
///----------------------------------

/**
 Creates and returns an `AFDownloadRequestOperation`
 @param task The request object to be loaded asynchronously during execution of the operation
 @param targetPath The target path (with or without file name)
 @param cachePath The cache path
 @param shouldResume If YES, tries to resume a partial download if found.
 @return A new download request operation
 */
- (instancetype)initWithTask:(NSURLSessionDataTask *)task
                  targetPath:(NSString *)targetPath
                   cachePath:(NSString *)cachePath
                shouldResume:(BOOL)shouldResume
                  isResuming:(BOOL)isResuming;

/**
 Deletes the temporary file.
 
 Returns `NO` if an error happened, `YES` if the file is removed or did not exist in the first place.
 */
- (BOOL)deleteTempFileWithError:(NSError **)error;

///**
// Sets a callback to be called when an undetermined number of bytes have been downloaded from the server. This is a variant of setDownloadProgressBlock that adds support for progressive downloads and adds the
// 
// @param block A block object to be called when an undetermined number of bytes have been downloaded from the server. This block has no return value and takes five arguments: the number of bytes read since the last time the download progress block was called, the bytes expected to be read during the request, the bytes already read during this request, the total bytes read (including from previous partial downloads), and the total bytes expected to be read for the file. This block may be called multiple times.
// 
// @see setDownloadProgressBlock
// */
- (void)setProgressiveDownloadProgressBlock:(void (^)(AFURLSessionDownloadTask *task,
                                                      NSInteger bytes,
                                                      long long totalBytes,
                                                      long long totalBytesExpected,
                                                      long long totalBytesReadForFile,
                                                      long long totalBytesExpectedToReadForFile)) block;

- (void)resume;
@end

@interface AFURLSessionDownLoadManager : AFHTTPSessionManager

/**
 The download tasks currently run by the managed session.
 */
@property (nonatomic, strong) NSMutableArray *afDownloadTasks;

- (AFURLSessionDownloadTask *)downloadTaskBreakPointsWithRequest:(NSURLRequest *)request
                                                      targetPath:(NSString *)targetPath
                                                       cachePath:(NSString *)cachePath
                                                    shouldResume:(BOOL)shouldResume
                                               completionHandler:(void (^)(NSURLResponse *response, id responseObject, NSError *error))completionHandler;

+ (instancetype)manager;

@end

