//
//  DMAccountLoginApi.h
//  HJNetworkDemo
//
//  Created by navy on 2020/12/28.
//

#import <Foundation/Foundation.h>
#import "DMRequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface DMAccountLoginApi : DMRequest

- (id)initWithAccountName:(NSString *)name pwd:(NSString *)pwd;

@end

NS_ASSUME_NONNULL_END
