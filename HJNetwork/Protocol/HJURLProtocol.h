//
//  HJURLProtocol.h
//  HJNetwork
//
//  Created by navy on 2022/5/27.
//  Copyright © 2022 HJNetwork. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class HJDNSNode;

@protocol HJURLProtocolDelegate;

/*! An NSURLProtocol subclass that overrides the built-in HTTP/HTTPS protocol to intercept
 *  authentication challenges for subsystems, like UIWebView, that don't otherwise allow it.
 *  To use this class you should set up your delegate (+setDelegate:) and then call +start.
 *  If you don't call +start the class is completely benign.
 */
@interface HJURLProtocol : NSURLProtocol

+ (void)registerProtocol;
+ (void)unregisterProtocol;

+ (NSURLSessionConfiguration *)sessionConfiguration;

+ (void)setDelegate:(id<HJURLProtocolDelegate>)newValue;
+ (void)setSessionConfiguration:(NSURLSessionConfiguration *)config;
+ (void)setRequestHeaderField:(NSDictionary *)field;

+ (void)registerCustomScheme:(NSString *)scheme selector:(SEL)selector;
+ (void)unregisterCustomScheme:(NSString *)scheme;

///< The current authentication challenge; it's only safe to access this from the main thread.
@property (atomic, strong, readonly) NSURLAuthenticationChallenge *pendingChallenge;

///< Call this method to resolve an authentication challeng.  This must be called on the main thread.
- (void)resolveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
                           disposition:(NSURLSessionAuthChallengeDisposition)disposition
                            credential:(NSURLCredential *)credential;

@end


@protocol HJURLProtocolDelegate <NSObject>

@optional
- (BOOL)HJURLProtocol:(HJURLProtocol *)protocol canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace;
- (void)HJURLProtocol:(HJURLProtocol *)protocol didCancelChallenge:(NSURLAuthenticationChallenge *)challenge;
- (void)HJURLProtocol:(HJURLProtocol *)protocol
              session:(NSURLSession *)session
                 task:(NSURLSessionTask *)task
  didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
    completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler;

- (HJDNSNode *_Nullable)HJURLProtocol:(HJURLProtocol *)protocol generateDNSNodeWithOriginalURL:(NSURL *)originalURL;
- (void)HJURLProtocol:(HJURLProtocol *)protocol
              session:(NSURLSession *)session
                 task:(NSURLSessionTask *)task
didFinishCollectingMetrics:(NSURLSessionTaskMetrics *)metrics API_AVAILABLE(macosx(10.12), ios(10.0), watchos(3.0), tvos(10.0));

- (void)HJURLProtocol:(HJURLProtocol *)protocol logWithFormat:(NSString *)format arguments:(va_list)arguments;
@end

NS_ASSUME_NONNULL_END
