//
//  HJCredentialChallenge.h
//  HJNetwork
//
//  Created by navy on 2022/10/27.
//  Copyright © 2022 HJNetwork. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HJCredentialChallenge : NSObject

+ (BOOL)proxyEnable;
+ (void)setProxyEnable:(BOOL)enable;

+ (void)setCertificatePublicKeys:(NSArray *)keys;

+ (BOOL)isIPAddress:(NSString *)address;

+ (void)challenge:(NSURLAuthenticationChallenge *)challenge host:(nullable NSString *)host
completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *_Nullable credential))completionHandler;

+ (nullable NSURLCredential *)challenge:(NSURLAuthenticationChallenge *)challenge host:(NSString *)host;

@end

NS_ASSUME_NONNULL_END
