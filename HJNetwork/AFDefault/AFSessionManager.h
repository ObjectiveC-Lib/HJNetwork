//
//  AFSessionManager.h
//  HJNetwork
//
//  Created by navy on 2022/8/9.
//

#import <AFNetworking/AFNetworking.h>

NS_ASSUME_NONNULL_BEGIN

@interface AFSessionManager : AFHTTPSessionManager

@property (nonatomic, assign) BOOL dnsEnabled;

+ (instancetype)manager;
+ (instancetype)protocolManager;

@end

NS_ASSUME_NONNULL_END
