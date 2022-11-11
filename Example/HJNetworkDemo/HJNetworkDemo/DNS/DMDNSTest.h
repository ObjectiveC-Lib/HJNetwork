//
//  DMDNSTest.h
//  HJNetworkDemo
//
//  Created by navy on 2022/11/15.
//

#import <Foundation/Foundation.h>
#import <HJNetwork/HJNetwork.h>

NS_ASSUME_NONNULL_BEGIN

@interface DMDNSTest : NSObject

+ (void)setDefaultDNS;
+ (void)resolveURL;
+ (void)negative;
+ (void)positive;

@end

NS_ASSUME_NONNULL_END
