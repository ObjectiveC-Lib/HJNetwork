//
//  HJUploadRequest.h
//  HJNetworkDemo
//
//  Created by navy on 2022/9/6.
//

#import "DMBaseRequest.h"
#import <HJTask/HJTask.h>
#import <HJNetwork/HJUpload.h>

NS_ASSUME_NONNULL_BEGIN

@interface HJUploadRequest : DMBaseRequest <HJTaskProtocol>

- (instancetype)initWithFragment:(nullable HJUploadFileFragment *)fragment;

@end

NS_ASSUME_NONNULL_END
