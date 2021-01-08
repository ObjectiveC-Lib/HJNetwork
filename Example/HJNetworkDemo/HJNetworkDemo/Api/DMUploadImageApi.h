//
//  DMUploadImageApi.h
//  HJNetworkDemo
//
//  Created by navy on 2020/12/29.
//

#import <Foundation/Foundation.h>
#import "DMRequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface DMUploadImageApi : DMRequest

- (id)initWithImage:(nullable UIImage *)image;

@end

NS_ASSUME_NONNULL_END
