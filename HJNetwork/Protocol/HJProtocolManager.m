//
//  HJProtocolManager.m
//  HJNetwork
//
//  Created by navy on 2022/5/30.
//  Copyright © 2022 HJNetwork. All rights reserved.
//

#import "HJProtocolManager.h"
#include <pthread.h>

#if __has_include(<HJNetwork/HJNetworkCommon.h>)
#import <HJNetwork/HJNetworkCommon.h>
#elif __has_include("HJNetworkCommon.h")
#import "HJNetworkCommon.h"
#endif

@interface HJThreadInfo : NSObject
@property (atomic, assign, readonly) uint64_t tid;             ///< The globally unique thread ID.
@property (atomic, assign, readonly) NSUInteger number;        ///< The thread number inside this app.
@property (atomic, copy,   readonly) NSString *name;           ///< The name of the thread; will not be nil.

/*! Initialises the object with the specified values.
 *  \param tid The globally unique thread ID.
 *  \param number The thread number inside this app.
 *  \param name The name of the thread; must not be nil.
 *  \returns An initialised instance.
 */
- (instancetype)initWithThreadID:(uint64_t)tid number:(NSUInteger)number name:(NSString *)name;
@end

@implementation HJThreadInfo
- (instancetype)initWithThreadID:(uint64_t)tid number:(NSUInteger)number name:(NSString *)name {
    assert(name != nil);
    self = [super init];
    if (self != nil) {
        self->_tid = tid;
        self->_number = number;
        self->_name = [name copy];
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %zu %#llx %@", [self class], (size_t) self->_number, self->_tid, self->_name];
}
@end


@interface HJProtocolManager() <HJURLProtocolDelegate>
@property (atomic, assign, readwrite) NSUInteger nextThreadNumber;
@property (atomic, strong, readwrite) NSMutableDictionary *threadInfoByThreadID;
@end

static NSTimeInterval sAppStartTime; // since reference date

@implementation HJProtocolManager

+ (instancetype)sharedManager {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        sAppStartTime = [NSDate timeIntervalSinceReferenceDate];
        
        self.threadInfoByThreadID = [[NSMutableDictionary alloc] init];
        (void)[self threadInfoForCurrentThread];
        
        [HJURLProtocol setDelegate:self];
    }
    return self;
}

- (AFSecurityPolicy *)securityPolicy {
    if (!_securityPolicy) {
        _securityPolicy = [AFSecurityPolicy defaultPolicy];
        _securityPolicy.validatesDomainName = YES;
        _securityPolicy.allowInvalidCertificates = NO;
    }
    return _securityPolicy;
}

- (void)registerProtocol:(Class)protocol {
    if ([protocol respondsToSelector:@selector(registerProtocol)]) {
        [protocol registerProtocol];
    }
}

- (void)unregisterProtocol:(Class)protocol {
    if ([protocol respondsToSelector:@selector(unregisterProtocol)]) {
        [protocol unregisterProtocol];
    }
}

- (NSURLSessionConfiguration *)sessionConfiguration {
    return [HJURLProtocol sessionConfiguration];
}

- (void)setSessionConfiguration:(NSURLSessionConfiguration *)sessionConfiguration {
    [HJURLProtocol setSessionConfiguration:sessionConfiguration];
}

- (void)setRequestHeaderField:(NSDictionary *)requestHeaderField {
    [HJURLProtocol setRequestHeaderField:requestHeaderField];
}

- (void)registerCustomScheme:(NSString *)scheme selector:(SEL)selector {
    [HJURLProtocol registerCustomScheme:scheme selector:selector];
}

- (void)unregisterCustomScheme:(NSString *)scheme {
    [HJURLProtocol unregisterCustomScheme:scheme];
}

+ (void)registerProtocol:(Class)protocol {
    [[HJProtocolManager sharedManager] registerProtocol:protocol];
}

+ (void)unregisterProtocol:(Class)protocol {
    [[HJProtocolManager sharedManager] unregisterProtocol:protocol];
}

+ (void)registerCustomScheme:(NSString *)scheme selector:(SEL)selector {
    [[HJProtocolManager sharedManager] registerCustomScheme:scheme selector:selector];
}

+ (void)unregisterCustomScheme:(NSString *)scheme {
    [[HJProtocolManager sharedManager] unregisterCustomScheme:scheme];
}

#pragma mark - HJURLProtocolDelegate

- (BOOL)HJURLProtocol:(HJURLProtocol *)protocol canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
    assert(protocol != nil);
    assert(protectionSpace != nil);
#pragma unused(protocol)
    
    // We accept any server trust authentication challenges.
    return [[protectionSpace authenticationMethod] isEqual:NSURLAuthenticationMethodServerTrust];
}

- (void)HJURLProtocol:(HJURLProtocol *)protocol
              session:(NSURLSession *)session
                 task:(NSURLSessionTask *)task
  didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
    completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {
    // Given our implementation of -HJURLProtocol:canAuthenticateAgainstProtectionSpace:, this method
    // is only called to handle server trust authentication challenges.  It evaluates the trust based on
    // both the global set of trusted anchors and the list of trusted anchors returned by the AFSecurityPolicy.
    
    assert(protocol != nil);
    assert(challenge != nil);
    assert([[[challenge protectionSpace] authenticationMethod] isEqual:NSURLAuthenticationMethodServerTrust]);
    // assert([NSThread isMainThread]);
    
    SecTrustResultType trustResult;
    NSURLCredential *credential = nil;
    OSStatus err;
    NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    
    // Extract the SecTrust object from the challenge, apply our trusted anchors to that
    // object, and then evaluate the trust.  If it's OK, create a credential and use
    // that to resolve the authentication challenge.  If anything goes wrong, resolve
    // the challenge with nil, which continues without a credential, which causes the
    // connection to fail.
    SecTrustRef trust = [[challenge protectionSpace] serverTrust];
    if (trust == NULL) {
        assert(NO);
    } else {
        BOOL evaluateServerTrust = NO;
        
        if (self.sessionAuthenticationChallengeHandler) {
            id result = self.sessionAuthenticationChallengeHandler(session, task, challenge, completionHandler);
            if (result == nil) {
                disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
            } else if ([result isKindOfClass:NSError.class]) {
                disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
            } else if ([result isKindOfClass:NSURLCredential.class]) {
                credential = result;
                disposition = NSURLSessionAuthChallengeUseCredential;
            } else if ([result isKindOfClass:NSNumber.class]) {
                disposition = [result integerValue];
                NSAssert(disposition == NSURLSessionAuthChallengePerformDefaultHandling ||
                         disposition == NSURLSessionAuthChallengeCancelAuthenticationChallenge ||
                         disposition == NSURLSessionAuthChallengeRejectProtectionSpace, @"");
                evaluateServerTrust = (disposition == NSURLSessionAuthChallengePerformDefaultHandling &&
                                       [challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]);
            } else {
                @throw [NSException exceptionWithName:@"Invalid Return Value"
                                               reason:@"The return value from the authentication challenge handler must be nil, an NSError, an NSURLCredential or an NSNumber."
                                             userInfo:nil];
            }
        } else {
            evaluateServerTrust = [challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
        }
        
        if (evaluateServerTrust) {
            if ([self.securityPolicy evaluateServerTrust:challenge.protectionSpace.serverTrust forDomain:challenge.protectionSpace.host]) {
                disposition = NSURLSessionAuthChallengeUseCredential;
                credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
            } else {
                disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
            }
        }
    }
    
    [protocol resolveAuthenticationChallenge:challenge disposition:disposition credential:credential];
}

// We don't need to implement -HJURLProtocol:didCancelChallenge: because we always resolve
// the challenge synchronously within -HJURLProtocol:didReceiveChallenge:.
//- (void)HJURLProtocol:(HJURLProtocol *)protocol didCancelChallenge:(NSURLAuthenticationChallenge *)challenge {
//
//}

- (HJDNSNode *_Nullable)HJURLProtocol:(HJURLProtocol *)protocol generateDNSNodeWithOriginalURL:(NSURL *)originalURL {
    if (self.useDNS) {
        if (self.dnsNodeBlock) {
            return self.dnsNodeBlock([originalURL absoluteString]);
        }
    }
    return nil;
}

- (void)HJURLProtocol:(HJURLProtocol *)protocol
              session:(NSURLSession *)session
                 task:(NSURLSessionTask *)task
didFinishCollectingMetrics:(NSURLSessionTaskMetrics *)metrics API_AVAILABLE(macosx(10.12), ios(10.0), watchos(3.0), tvos(10.0)) {
    if (self.collectingMetricsBlock) {
        self.collectingMetricsBlock(session, task, metrics);
    }
}

- (void)HJURLProtocol:(HJURLProtocol *)protocol logWithFormat:(NSString *)format arguments:(va_list)arguments {
    assert(format != nil);
    
    NSString *prefix;
    if (protocol == nil) {
        prefix = @"HJURLProtocol ";
    } else {
        prefix = [NSString stringWithFormat:@"%@ %p ", [protocol class], protocol];
    }
    
    [self logWithPrefix:prefix format:format arguments:arguments];
}

#pragma mark - Logger

/*! Our logging core, called by various logging routines, each with a unique prefix. May be called
 *  by any thread.
 *  \param prefix A prefix to to insert into the log; must not be nil; if non-empty, should include a trailing space.
 *  \param format A standard NSString-style format string.
 *  \param arguments Arguments for that format string.
 */
- (void)logWithPrefix:(NSString *)prefix format:(NSString *)format arguments:(va_list)arguments {
    assert(prefix != nil);
    assert(format != nil);
    
    if (self.debugLogEnabled) {
        NSString *str = [[NSString alloc] initWithFormat:format arguments:arguments];
        assert(str != nil);
        
        NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
        HJThreadInfo *threadInfo = [self threadInfoForCurrentThread];
        
        char elapsedStr[16];
        snprintf(elapsedStr, sizeof(elapsedStr), "+%.1f", (now - sAppStartTime));
        
        fprintf(stderr, "%3zu %s %s%s\n", (size_t)threadInfo.number, elapsedStr, [prefix UTF8String], [str UTF8String]);
    }
}

- (HJThreadInfo *)threadInfoForCurrentThread {
    // Get the thread ID and box it for use as a dictionary key.
    HJThreadInfo *result;
    uint64_t tid;
    
    int junk = pthread_threadid_np(pthread_self(), &tid);
#pragma unused(junk)    // quietens analyser in the Release build
    assert(junk == 0);
    NSNumber *tidObj = @(tid);
    
    // Look up the thread info using that key.
    @synchronized (self) {
        result = self.threadInfoByThreadID[tidObj];
    }
    
    // If we didn't find one, create it.  We drop the @synchronized while doing this because
    // it might take a while; in theory no one else should be able to add this thread into
    // the dictionary (because threads only add themselves) so we just assert that this
    // hasn't happened.
    //
    // Also note that, because self.nextThreadNumber accesses must be protected by the
    // @synchronized, we actually created the ThreadInfo object inside the @synchronized
    // block.  That shouldn't be a problem because -[HJThreadInfo initXxx] is trivial.
    if (result == nil) {
        HJThreadInfo *newThreadInfo;
        char threadName[256];
        NSString *threadNameObj;
        
        if ( (pthread_getname_np(pthread_self(), threadName, sizeof(threadName)) == 0) && (threadName[0] != 0) ) {
            // We got a name and it's not empty.
            threadNameObj = [[NSString alloc] initWithUTF8String:threadName];
        } else if (pthread_main_np()) {
            threadNameObj = @"-main-";
        } else {
            threadNameObj = @"-unnamed-";
        }
        assert(threadNameObj != nil);
        
        @synchronized (self) {
            assert(self.threadInfoByThreadID[tidObj] == nil);
            
            newThreadInfo = [[HJThreadInfo alloc] initWithThreadID:tid number:self.nextThreadNumber name:threadNameObj];
            self.nextThreadNumber += 1;
            self.threadInfoByThreadID[tidObj] = newThreadInfo;
            result = newThreadInfo;
        }
    }
    
    return result;
}

@end
