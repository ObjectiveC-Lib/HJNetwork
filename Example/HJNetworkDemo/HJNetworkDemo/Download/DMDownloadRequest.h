//
//  DMDownloadRequest.h
//  HJNetworkDemo
//
//  Created by navy on 2022/7/27.
//

#import "DMBaseRequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface DMDownloadRequest : DMBaseRequest

- (instancetype)initWithTimeout:(NSTimeInterval)timeout requestUrl:(NSString *)requestUrl;
+ (NSString *)saveBasePath;

@end

NS_ASSUME_NONNULL_END
