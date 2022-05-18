//
//  HJUploadRequest.h
//  HJNetworkDemo
//
//  Created by navy on 2022/9/6.
//

#import "DMBasicRequest.h"
#import "HJFileSource.h"


NS_ASSUME_NONNULL_BEGIN

@interface HJUploadRequest : DMBasicRequest

- (instancetype)initWithFragment:(nullable HJFileFragment *)fragment;

@end

NS_ASSUME_NONNULL_END
