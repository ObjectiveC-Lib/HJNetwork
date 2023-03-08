//
//  HJDNSResolveManager.h
//  HJNetwork
//
//  Created by navy on 2022/11/10.
//  Copyright © 2022 HJNetwork. All rights reserved.
//

#import <Foundation/Foundation.h>

#if __has_include(<HJNetwork/HJNetworkCommon.h>)
#import <HJNetwork/HJNetworkCommon.h>
#elif __has_include("HJNetworkCommon.h")
#import "HJNetworkCommon.h"
#endif

typedef NSDictionary <NSString*, NSArray*> HJDNSDictionary;
typedef void(^HJDNSDictBlock)(HJDNSDictionary * _Nullable dictionary);
typedef void(^HJDNSRemoteDictBlock)(NSString *_Nullable dnsRemoteUrl, HJDNSDictBlock _Nullable dnsDict);

NS_ASSUME_NONNULL_BEGIN

@interface HJDNSResolveManager : NSObject

@property (nonatomic, assign) BOOL ignoreNegative;              // default NO
@property (nonatomic, assign) NSUInteger negativeCount;         // default 1
@property (nonatomic, assign) NSTimeInterval autoFetchInterval; // default 1 hours
@property (nonatomic, strong, nullable) NSString *dnsRemoteUrl;
@property (nonatomic,   copy, nullable) HJDNSRemoteDictBlock dnsRemoteDictBlock;

+ (instancetype)sharedManager;

- (void)fetchRemoteDNS;
- (void)setDefaultDNS:(HJDNSDictionary *)dict;

- (nullable HJDNSNode *)resolveURL:(NSURL *)originalURL;

- (void)setNegativeUrl:(NSString *)url host:(NSString *)host;
- (void)setPositiveUrl:(NSString *)url host:(NSString *)host;

@end

NS_ASSUME_NONNULL_END
