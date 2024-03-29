//
//  NSURLSessionConfiguration+URLProtocol.h
//  HJNetwork
//
//  Created by navy on 2022/8/9.
//  Copyright © 2022 HJNetwork. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSURLSessionConfiguration (URLProtocol)

+ (instancetype)sharedProtocolConfig:(Class)protocol;

@end

NS_ASSUME_NONNULL_END
