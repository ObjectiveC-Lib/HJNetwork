//
//  DMNetworkManage.h
//  HJNetworkDemo
//
//  Created by navy on 2020/12/25.
//

#import <Foundation/Foundation.h>
#import <HJNetwork/HJNetwork.h>

NS_ASSUME_NONNULL_BEGIN

@interface DMNetworkManage : NSObject <HJUrlFilterProtocol>

+ (DMNetworkManage *)urlFilter;
+ (NSString *)serverHost;

@end

NS_ASSUME_NONNULL_END
