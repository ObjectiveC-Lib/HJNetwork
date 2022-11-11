//
//  DMUploadRequest.h
//  HJNetworkDemo
//
//  Created by navy on 2022/7/27.
//

#import "DMBaseRequest.h"
#import <HJTask/HJTask.h>

NS_ASSUME_NONNULL_BEGIN

@interface DMUploadRequest : DMBaseRequest <HJTaskProtocol>

- (instancetype)initWithPath:(nullable NSString *)path;

@end

NS_ASSUME_NONNULL_END
