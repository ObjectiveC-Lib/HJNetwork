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

- (id)initWithName:(NSString *)name image:(UIImage *)image;

- (NSString *)responseImageId;

@end

NS_ASSUME_NONNULL_END
