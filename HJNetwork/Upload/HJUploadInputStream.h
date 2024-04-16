//
//  HJUploadInputStream.h
//  HJNetwork
//
//  Created by navy on 2022/9/7.
//  Copyright © 2022 HJNetwork. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class HJUploadFileFragment;

@interface HJUploadInputStream : NSInputStream

- (instancetype)initWithFragment:(nullable HJUploadFileFragment *)fragment;

@end

NS_ASSUME_NONNULL_END
