//
//  DMBasicUrlFilter.h
//  HJNetworkDemo
//
//  Created by navy on 2020/12/25.
//

#import <Foundation/Foundation.h>
#import <HJNetwork/HJNetwork.h>

NS_ASSUME_NONNULL_BEGIN

@interface DMBasicUrlFilter : NSObject <HJUrlFilterProtocol>

+ (NSString *)baseUrl;
+ (instancetype)filterWithArguments:(NSDictionary<NSString *, NSString *> *)arguments;

@end

NS_ASSUME_NONNULL_END
