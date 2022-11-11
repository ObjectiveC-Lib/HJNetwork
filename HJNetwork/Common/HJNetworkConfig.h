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
FOUNDATION_EXPORT void HJLog(NSString *format, ...) NS_FORMAT_FUNCTION(1,2);

@class HJCoreRequest;
@class AFSecurityPolicy;
@class HJDNSNode;

typedef void (^HJURLSessionTaskDidFinishCollectingMetricsBlock)(NSURLSession *session,
                                                                NSURLSessionTask *task,
                                                                NSURLSessionTaskMetrics *metrics) API_AVAILABLE(macosx(10.12), ios(10.0), watchos(3.0), tvos(10.0));

/// Custom
typedef HJDNSNode  *_Nullable (^HJDNSNodeBlock)(NSString *originalURLString);

typedef id _Nullable (^HJURLSessionTaskAuthenticationChallengeBlock)(NSURLSession *session,
                                                                     NSURLSessionTask *task,
                                                                     NSURLAuthenticationChallenge *challenge,
                                                                     void (^completionHandler)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *_Nullable credential));

typedef void (^HJURLConnectionAuthenticationChallengeBlock)(NSURLConnection *connection,
                                                            NSURLAuthenticationChallenge *challenge);

///  Can be used to append common parameters to requests before sending them.
@protocol HJUrlFilterProtocol <NSObject>
- (NSString *)filterUrl:(NSString *)originUrl withRequest:(HJCoreRequest *)request;
@end


@interface HJNetworkConfig : NSObject

@property (nonatomic, strong) NSString *baseUrl;
@property (nonatomic, strong) NSString *cdnUrl;
@property (nonatomic, strong) AFSecurityPolicy *securityPolicy;
@property (nonatomic, strong, nullable) NSURLSessionConfiguration *sessionConfiguration;
@property (nonatomic, strong, readonly) NSArray<id<HJUrlFilterProtocol>> *urlFilters;
@property (nonatomic, copy) HJURLConnectionAuthenticationChallengeBlock connectionAuthenticationChallengeHandler;
@property (nonatomic, copy) HJURLSessionTaskAuthenticationChallengeBlock sessionAuthenticationChallengeHandler;
@property (nonatomic, copy) HJURLSessionTaskDidFinishCollectingMetricsBlock collectingMetricsBlock API_AVAILABLE(macosx(10.12), ios(10.0), watchos(3.0), tvos(10.0));
@property (nonatomic, copy, nullable) NSArray <NSString *> *jsonResponseContentTypes;
@property (nonatomic, copy, nullable) NSArray <NSString *> *xmlResponseContentTypes;
@property (nonatomic, copy, nullable) HJDNSNodeBlock dnsNodeBlock;
@property (nonatomic, assign) BOOL useDNS;
@property (nonatomic, assign) BOOL debugLogEnabled;

+ (HJNetworkConfig *)sharedConfig;

- (void)addUrlFilter:(id<HJUrlFilterProtocol>)filter;
- (void)clearUrlFilter;

@end

NS_ASSUME_NONNULL_END
