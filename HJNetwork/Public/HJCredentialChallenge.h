//
//  HJCredentialChallenge.h
//  HJNetwork
//
//  Created by navy on 2022/10/27.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HJCredentialChallenge : NSObject

+ (BOOL)isIPAddress:(NSString *)address;

+ (void)challenge:(NSURLAuthenticationChallenge *)challenge host:(nullable NSString *)host
completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *_Nullable credential))completionHandler;

+ (nullable NSURLCredential *)challenge:(NSURLAuthenticationChallenge *)challenge host:(NSString *)host;

@end

NS_ASSUME_NONNULL_END
