//
//  HJProtocolManager.h
//  HJNetwork
//
//  Created by navy on 2022/5/30.
//  Copyright © 2022 HJNetwork. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HJURLProtocol.h"

#if __has_include(<AFNetworking/AFSecurityPolicy.h>)
#import <AFNetworking/AFSecurityPolicy.h>
#elif __has_include("AFSecurityPolicy.h")
#import "AFSecurityPolicy.h"
#endif

@class HJDNSNode;

NS_ASSUME_NONNULL_BEGIN

typedef HJDNSNode  *_Nullable (^HJDNSNodeBlock)(NSString *originalURLString);

typedef id _Nullable (^HJSessionAuthenticationChallengeBlock)(NSURLSession *session,
                                                              NSURLSessionTask *task,
                                                              NSURLAuthenticationChallenge *challenge,
                                                              void (^completionHandler)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *_Nullable credential));

typedef void (^HJSessionTaskDidFinishCollectingMetricsBlock)(NSURLSession *session,
                                                             NSURLSessionTask *task,
                                                             NSURLSessionTaskMetrics *metrics) API_AVAILABLE(macosx(10.12), ios(10.0), watchos(3.0), tvos(10.0));

@interface HJProtocolManager : NSObject

@property (nonatomic,   copy, nullable) HJDNSNodeBlock dnsNodeBlock;
@property (nonatomic, strong, nullable) NSDictionary <NSString *, NSString *>*requestHeaderField;
@property (nonatomic, strong, nullable) AFSecurityPolicy *securityPolicy;
@property (nonatomic, strong, nullable) NSURLSessionConfiguration *sessionConfiguration;
@property (nonatomic,   copy, nullable) HJSessionAuthenticationChallengeBlock sessionAuthenticationChallengeHandler;
@property (nonatomic,   copy, nullable) HJSessionTaskDidFinishCollectingMetricsBlock collectingMetricsBlock API_AVAILABLE(macosx(10.12), ios(10.0), watchos(3.0), tvos(10.0));
@property (nonatomic, assign) BOOL useDNS;
@property (nonatomic, assign) BOOL debugLogEnabled;

+ (instancetype)sharedManager;

+ (void)registerProtocol:(Class)protocol;
+ (void)unregisterProtocol:(Class)protocol;

+ (void)registerCustomScheme:(NSString *)scheme selector:(nullable SEL)selector;
+ (void)unregisterCustomScheme:(NSString *)scheme;

@end

NS_ASSUME_NONNULL_END
