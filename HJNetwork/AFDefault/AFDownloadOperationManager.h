//
//  AFDownloadOperationManager.h
//  HJNetwork
//
//  Created by navy on 2022/6/20.
//

#import "AFHTTPRequestOperationManager.h"
#import "AFDownloadOperation.h"

#if __has_include(<HJNetwork/HJNetworkPublic.h>)
#import <HJNetwork/HJNetworkPublic.h>
#elif __has_include("HJNetworkPublic.h")
#import "HJNetworkPublic.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@interface AFDownloadOperationManager : AFHTTPRequestOperationManager

+ (instancetype)manager:(nullable HJNetworkConfig *)config;

- (nullable AFDownloadOperation *)Download:(NSString *)URLString
                            fileIdentifier:(NSString *)fileIdentifier
                                targetPath:(NSString *)targetPath
                              shouldResume:(BOOL)shouldResume
                                parameters:(nullable id)parameters
                                   success:(nullable void (^)(AFHTTPRequestOperation *operation, id __nullable responseObject))success
                                   failure:(nullable void (^)(AFHTTPRequestOperation * __nullable operation, NSError *error))failure;

@end

NS_ASSUME_NONNULL_END
