//
//  DMDownloadImageApi.h
//  HJNetworkDemo
//
//  Created by navy on 2020/12/29.
//

#import <Foundation/Foundation.h>
#import "DMRequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface DMDownloadImageApi : DMRequest

- (id)initWithImageId:(NSString *)imageId;

@end

NS_ASSUME_NONNULL_END
