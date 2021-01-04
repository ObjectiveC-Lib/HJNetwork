//
//  DMUploadImageApi.h
//  HJNetworkDemo
//
//  Created by navy on 2020/12/29.
//

#import <Foundation/Foundation.h>
#import "DMRequest.h"
#import <HJUpload/HJUploadHeader.h>

NS_ASSUME_NONNULL_BEGIN

@interface DMUploadImageApi : DMRequest <HJUploadProtocol>

- (id)initWithKey:(nullable NSString *)key image:(nullable UIImage *)image;

@end

NS_ASSUME_NONNULL_END
