//
//  HJDownloadOperationManager.h
//  HJNetwork
//
//  Created by navy on 2022/6/20.
//  Copyright © 2022 HJNetwork. All rights reserved.
//

#import "AFHTTPRequestOperationManager.h"
#import "HJNetworkCommon.h"
#import "HJDownloadOperation.h"

NS_ASSUME_NONNULL_BEGIN

@interface HJDownloadOperationManager : AFHTTPRequestOperationManager

+ (instancetype)manager:(nullable HJNetworkConfig *)config;

- (nullable HJDownloadOperation *)Download:(NSString *)URLString
                            fileIdentifier:(NSString *)fileIdentifier
                                targetPath:(NSString *)targetPath
                              shouldResume:(BOOL)shouldResume
                                parameters:(nullable id)parameters
                                   success:(nullable void (^)(AFHTTPRequestOperation *operation, id __nullable responseObject))success
                                   failure:(nullable void (^)(AFHTTPRequestOperation * __nullable operation, NSError *error))failure;

@end

NS_ASSUME_NONNULL_END
