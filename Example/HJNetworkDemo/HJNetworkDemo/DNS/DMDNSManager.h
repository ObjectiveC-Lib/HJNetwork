//
//  DMDNSManager.h
//  HJNetworkDemo
//
//  Created by navy on 2024/9/9.
//

#import <HJNetwork/HJNetwork.h>

NS_ASSUME_NONNULL_BEGIN

@interface DMDNSManager : HJDNSResolveManager

+ (instancetype)sharedManager;

@end

NS_ASSUME_NONNULL_END
