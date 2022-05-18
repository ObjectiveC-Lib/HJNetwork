//
//  AFDownloadOperationManager.h
//  HJNetwork
//
//  Created by navy on 2022/6/20.
//

#import "AFHTTPRequestOperationManager.h"
#import "AFDownloadOperation.h"

NS_ASSUME_NONNULL_BEGIN

@interface AFDownloadOperationManager : AFHTTPRequestOperationManager

@property (nonatomic, assign) BOOL dnsEnabled;

+ (instancetype)manager;

- (nullable AFDownloadOperation *)Download:(NSString *)URLString
                            fileIdentifier:(NSString *)fileIdentifier
                                targetPath:(NSString *)targetPath
                              shouldResume:(BOOL)shouldResume
                                parameters:(nullable id)parameters
                                   success:(nullable void (^)(AFHTTPRequestOperation *operation, id __nullable responseObject))success
                                   failure:(nullable void (^)(AFHTTPRequestOperation * __nullable operation, NSError *error))failure;

@end

NS_ASSUME_NONNULL_END
