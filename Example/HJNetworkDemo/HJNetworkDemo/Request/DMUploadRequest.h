//
//  DMUploadRequest.h
//  HJNetworkDemo
//
//  Created by navy on 2022/7/27.
//

#import "DMBasicRequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface DMUploadRequest : DMBasicRequest

- (instancetype)initWithPath:(nullable NSString *)path;

@end

NS_ASSUME_NONNULL_END
