//
//  HJNetworkConfig.h
//  HJNetwork
//
//  Created by navy on 2018/7/5.
//  Copyright © 2018 HJNetwork. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const HJRequestCacheErrorDomain;

@class HJBaseRequest;
@class AFSecurityPolicy;

typedef void (^AFURLSessionTaskDidFinishCollectingMetricsBlock)(NSURLSession *session,
                                                                NSURLSessionTask *task,
                                                                NSURLSessionTaskMetrics * metrics) API_AVAILABLE(ios(10), macosx(10.12), watchos(3), tvos(10));

/// Custom
typedef NSURLSessionAuthChallengeDisposition (^AFURLSessionDidReceiveAuthenticationChallengeBlock)(NSURLSession *session,
                                                                                                   NSURLAuthenticationChallenge *challenge,
                                                                                                   NSURLCredential * _Nonnull __autoreleasing * _Nullable credential);

typedef id _Nullable (^AFURLSessionTaskAuthenticationChallengeBlock)(NSURLSession *session,
                                                                     NSURLSessionTask *task,
                                                                     NSURLAuthenticationChallenge *challenge,
                                                                     void (^completionHandler)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential));

///  Can be used to append common parameters to requests before sending them.
@protocol HJUrlFilterProtocol <NSObject>
- (NSString *)filterUrl:(NSString *)originUrl withRequest:(HJBaseRequest *)request;
@end


@interface HJNetworkConfig : NSObject

@property (nonatomic, strong) NSString *baseUrl;
@property (nonatomic, strong) NSString *cdnUrl;
@property (nonatomic, assign) BOOL debugLogEnabled;
@property (nonatomic, assign) NSUInteger cacheCountLimit;
@property (nonatomic, strong) AFSecurityPolicy *securityPolicy;
@property (nonatomic, strong, nullable) NSURLSessionConfiguration *sessionConfiguration;
@property (nonatomic, strong, readonly) NSArray<id<HJUrlFilterProtocol>> *urlFilters;
@property (nonatomic, copy) AFURLSessionTaskDidFinishCollectingMetricsBlock collectingMetricsBlock API_AVAILABLE(ios(10), macosx(10.12), watchos(3), tvos(10));
/// Custom
@property (nonatomic, copy) AFURLSessionDidReceiveAuthenticationChallengeBlock sessionDidReceiveAuthenticationChallenge;
@property (nonatomic, copy) AFURLSessionTaskAuthenticationChallengeBlock authenticationChallengeHandler;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

+ (HJNetworkConfig *)sharedConfig;

- (void)addUrlFilter:(id<HJUrlFilterProtocol>)filter;
- (void)clearUrlFilter;

- (NSInteger)totalCostOfCache;
- (void)removeAllCache;

@end

NS_ASSUME_NONNULL_END
