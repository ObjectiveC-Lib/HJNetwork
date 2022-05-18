//
//  DMCredentialChallenge.h
//  HJNetworkDemo
//
//  Created by navy on 2022/6/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DMCredentialChallenge : NSObject

+ (BOOL)isIPAddress:(NSString *)address;

+ (void)challenge:(NSURLAuthenticationChallenge *)challenge host:(nullable NSString *)host
completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *_Nullable credential))completionHandler;

+ (nullable NSURLCredential *)challenge:(NSURLAuthenticationChallenge *)challenge host:(NSString *)host;

@end

NS_ASSUME_NONNULL_END
