//
//  HJURLProtocol.m
//  HJNetwork
//
//  Created by navy on 2022/5/27.
//  Copyright © 2022 HJNetwork. All rights reserved.
//

#import "HJURLProtocol.h"
#import "HJNetworkCommon.h"
#import "HJCanonicalRequest.h"
#import "HJCacheStoragePolicy.h"
#import "HJURLSessionDemux.h"
#import "HJCustomScheme.h"

typedef void (^HJChallengeCompletionHandler)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * credential);

@interface HJURLProtocol () <NSURLSessionDataDelegate>

@property (atomic, strong, readwrite) NSThread *clientThread;   ///< The thread on which we should call the client.
@property (atomic, copy,   readwrite) NSArray *modes;
@property (atomic, assign, readwrite) NSTimeInterval startTime; ///< The start time of the request; written by client thread only; read by any thread.
@property (atomic, strong, readwrite) NSURLSessionDataTask *task;   ///< The NSURLSession task for that request; client thread only.
@property (atomic, strong, readwrite) NSURLAuthenticationChallenge *pendingChallenge;
@property (atomic, copy,   readwrite) HJChallengeCompletionHandler pendingChallengeCompletionHandler; ///< The completion handler that matches pendingChallenge; main thread only.

@end


@implementation HJURLProtocol

#pragma mark * Subclass specific additions

/*! The backing store for the class delegate.  This is protected by @synchronized on the class.
 */
static id<HJURLProtocolDelegate> sDelegate;
static NSURLSessionConfiguration *sSessionConfig;
static NSDictionary *sRequestHeaderField;

+ (void)registerProtocol {
    [NSURLProtocol registerClass:self];
}

+ (void)unregisterProtocol {
    [NSURLProtocol unregisterClass:self];
}

+ (void)setDelegate:(id<HJURLProtocolDelegate>)newValue {
    @synchronized (self) {
        sDelegate = newValue;
    }
}

+ (void)setSessionConfiguration:(NSURLSessionConfiguration *)config {
    @synchronized (self) {
        static dispatch_once_t once;
        dispatch_once(&once, ^ {
            sSessionConfig = config;
        });
    }
}

+ (void)setRequestHeaderField:(NSDictionary *)field {
    @synchronized (self) {
        sRequestHeaderField = field;
    }
}

+ (id<HJURLProtocolDelegate>)delegate {
    id<HJURLProtocolDelegate> result;
    @synchronized (self) {
        result = sDelegate;
    }
    return result;
}

+ (NSURLSessionConfiguration *)sessionConfiguration {
    NSURLSessionConfiguration *result;
    @synchronized (self) {
        result = sSessionConfig;
    }
    return result;
}

+ (NSDictionary *)requestHeaderField {
    NSDictionary *result;
    @synchronized (self) {
        result = sRequestHeaderField;
    }
    return result;
}

+ (void)registerCustomScheme:(NSString *)scheme selector:(SEL)selector {
    [HJCustomScheme registerScheme:scheme selector:selector];
}

+ (void)unregisterCustomScheme:(NSString *)scheme {
    [HJCustomScheme unregisterScheme:scheme];
}

/*! Returns the session demux object used by all the protocol instances.
 *  \details This object allows us to have a single NSURLSession, with a session delegate,
 *  and have its delegate callbacks routed to the correct protocol instance on the correct
 *  thread in the correct modes.  Can be called on any thread.
 */
+ (HJURLSessionDemux *)sharedDemux {
    static dispatch_once_t sOnceToken;
    static HJURLSessionDemux *sDemux;
    dispatch_once(&sOnceToken, ^{
        NSURLSessionConfiguration *config = [self sessionConfiguration];
        if (!config) {
            config = [NSURLSessionConfiguration defaultSessionConfiguration];
        }
        NSMutableArray *classes = [[NSMutableArray alloc] initWithArray:config.protocolClasses];
        if ([config.protocolClasses containsObject:self]) {
            [classes removeObject:self];
        }
        [classes insertObject:self atIndex:0];
        
        // You have to explicitly configure the session to use your own protocol subclass here otherwise you don't see redirects <rdar://problem/17384498>.
        config.protocolClasses = [classes copy];
        sDemux = [[HJURLSessionDemux alloc] initWithConfiguration:config];
    });
    return sDemux;
}

/*! Called by by both class code and instance code to log various bits of information. Can be called on any thread.
 *  \param protocol The protocol instance; nil if it's the class doing the logging.
 *  \param format A standard NSString-style format string; will not be nil.
 */
+ (void)HJURLProtocol:(HJURLProtocol *)protocol logWithFormat:(NSString *)format, ... NS_FORMAT_FUNCTION(2, 3) {
    // All internal logging calls this routine, which routes the log message to the delegate.
    // protocol may be nil
    id<HJURLProtocolDelegate> strongDelegate = [self delegate];
    if ([strongDelegate respondsToSelector:@selector(HJURLProtocol:logWithFormat:arguments:)]) {
        va_list arguments;
        va_start(arguments, format);
        [strongDelegate HJURLProtocol:protocol logWithFormat:format arguments:arguments];
        va_end(arguments);
    }
}

#pragma mark * NSURLProtocol overrides

/*! Used to mark our recursive requests so that we don't try to handle them (and thereby suffer an infinite recursive death).
 */
static NSString * kOurRecursiveRequestFlagProperty = @"com.apple.dts.HJURLProtocol";
static NSString * kOurCustomSchemeFlagProperty = @"com.apple.domain.HJURLProtocol";

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    // Check the basics.  This routine is extremely defensive because experience has shown that
    // it can be called with some very odd requests <rdar://problem/15197355>.
    
    NSURL *url;
    NSString *scheme;
    
    BOOL shouldAccept = (request != nil);
    if (shouldAccept) {
        url = [request URL];
        shouldAccept = (url != nil);
    }
    if (!shouldAccept) {
        [self HJURLProtocol:self logWithFormat:@"decline request (malformed)"];
    }
    
    // Decline our recursive requests.
    if (shouldAccept) {
        shouldAccept = ([self propertyForKey:kOurRecursiveRequestFlagProperty inRequest:request] == nil);
        if (!shouldAccept) {
            [self HJURLProtocol:self logWithFormat:@"decline request %@ (recursive)", url];
        }
    }
    
    // Get the scheme.
    if (shouldAccept) {
        scheme = [[url scheme] lowercaseString];
        shouldAccept = (scheme != nil);
        
        if (!shouldAccept) {
            [self HJURLProtocol:self logWithFormat:@"decline request %@ (no scheme)", url];
        }
    }
    
    // Look for "http" , "https" or custom scheme.
    // Flip either or both of the following to YESes to control which schemes go through this custom
    // NSURLProtocol subclass.
    if (shouldAccept) {
        shouldAccept = ([scheme isEqual:@"http"] || [scheme isEqual:@"https"] || [HJCustomScheme containsScheme:[url absoluteString]]);
        if (!shouldAccept) {
            [self HJURLProtocol:self logWithFormat:@"decline request %@ (scheme mismatch)", url];
        } else {
            [self HJURLProtocol:self logWithFormat:@"accept request %@", url];
        }
    }
    
    return shouldAccept;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    assert(request != nil);
    // can be called on any thread
    // Canonicalising a request is quite complex, so all the heavy lifting has
    // been shuffled off to a separate module.
    NSURLRequest *result = HJCanonicalRequestForRequest(request);
    result = HJGetMutablePostRequestIncludeBodyForRequest(result);
    NSMutableURLRequest *newRequest = result.mutableCopy;
    
    // DNS
    HJDNSNode *node = nil;
    id<HJURLProtocolDelegate> strongeDelegate = [[self class] delegate];
    if ([strongeDelegate respondsToSelector:@selector(HJURLProtocol:generateDNSNodeWithOriginalURL:)]) {
        node = [strongeDelegate HJURLProtocol:self generateDNSNodeWithOriginalURL:result.URL];
    }
    if (node) {
        if (node.url != nil && [node.url length] > 0) {
            newRequest.URL = [NSURL URLWithString:node.url];
        }
        
        if (node.host != nil && [node.host length] > 0) {
            [newRequest setValue:node.host forHTTPHeaderField:@"host"];
        }
    }
    
    // Custom Scheme
    HJSchemeItem *item = [HJCustomScheme objectSchemeForKey:[[result URL] absoluteString]];
    if (item) {
        [NSURLProtocol setProperty:item forKey:kOurCustomSchemeFlagProperty inRequest:newRequest];
    }
    
    // Request Header Field
    NSDictionary *headers = [self requestHeaderField];
    [headers enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull field, id  _Nonnull value, BOOL * _Nonnull stop) {
        if (![result valueForHTTPHeaderField:field]) {
            [newRequest setValue:value forHTTPHeaderField:field];
        }
    }];
    
    [self HJURLProtocol:self logWithFormat:@"canonicalized %@ to %@", [request URL], [newRequest URL]];
    
    return [newRequest copy];
}

- (id)initWithRequest:(NSURLRequest *)request cachedResponse:(NSCachedURLResponse *)cachedResponse client:(id <NSURLProtocolClient>)client {
    assert(request != nil);
    assert(client != nil);
    
    // can be called on any thread
    self = [super initWithRequest:request cachedResponse:cachedResponse client:client];
    if (self != nil) {
        // All we do here is log the call.
        [[self class] HJURLProtocol:self logWithFormat:@"init for %@ from <%@ %p>", [request URL], [client class], client];
    }
    return self;
}

- (void)dealloc {
    // can be called on any thread
    [[self class] HJURLProtocol:self logWithFormat:@"dealloc"];
    assert(self->_task == nil);                     // we should have cleared it by now
    assert(self->_pendingChallenge == nil);         // we should have cancelled it by now
    assert(self->_pendingChallengeCompletionHandler == nil);    // we should have cancelled it by now
}

- (void)startLoading {
    // At this point we kick off the process of loading the URL via NSURLSession.
    // The thread that calls this method becomes the client thread.
    assert(self.clientThread == nil); // you can't call -startLoading twice
    assert(self.task == nil);
    
    // Calculate our effective run loop modes.  In some circumstances (yes I'm looking at
    // you UIWebView!) we can be called from a non-standard thread which then runs a
    // non-standard run loop mode waiting for the request to finish.  We detect this
    // non-standard mode and add it to the list of run loop modes we use when scheduling
    // our callbacks.  Exciting huh?
    //
    // For debugging purposes the non-standard mode is "WebCoreSynchronousLoaderRunLoopMode"
    // but it's better not to hard-code that here.
    assert(self.modes == nil);
    
    NSMutableArray *calculatedModes = [NSMutableArray array];
    [calculatedModes addObject:NSDefaultRunLoopMode];
    
    NSString *currentMode = [[NSRunLoop currentRunLoop] currentMode];
    if ((currentMode != nil) && ! [currentMode isEqual:NSDefaultRunLoopMode] ) {
        [calculatedModes addObject:currentMode];
    }
    
    self.modes = calculatedModes;
    assert([self.modes count] > 0);
    
    // Create new request that's a clone of the request we were initialised with,
    // except that it has our 'recursive request flag' property set on it.
    NSMutableURLRequest *recursiveRequest = [[self request] mutableCopy];
    assert(recursiveRequest != nil);
    
    [[self class] setProperty:@YES forKey:kOurRecursiveRequestFlagProperty inRequest:recursiveRequest];
    
    self.startTime = [NSDate timeIntervalSinceReferenceDate];
    if (currentMode == nil) {
        [[self class] HJURLProtocol:self logWithFormat:@"start %@", [recursiveRequest URL]];
    } else {
        [[self class] HJURLProtocol:self logWithFormat:@"start %@ (mode %@)", [recursiveRequest URL], currentMode];
    }
    
    // Latch the thread we were called on, primarily for debugging purposes.
    self.clientThread = [NSThread currentThread];
    
    HJSchemeItem *item = [NSURLProtocol propertyForKey:kOurCustomSchemeFlagProperty inRequest:recursiveRequest];
    if (item.selector != nil && [self respondsToSelector:item.selector]) {
        // Custom Scheme Selector
        ((void (*)(id, SEL))[self methodForSelector:item.selector])(self, item.selector);
    } else {
        // Once everything is ready to go, create a data task with the new request.
        self.task = [[[self class] sharedDemux] dataTaskWithRequest:recursiveRequest delegate:self modes:self.modes];
        assert(self.task != nil);
        [self.task resume];
    }
}

- (void)stopLoading {
    // The implementation just cancels the current load (if it's still running).
    [[self class] HJURLProtocol:self logWithFormat:@"stop (elapsed %.1f)", [NSDate timeIntervalSinceReferenceDate] - self.startTime];
    
    assert(self.clientThread != nil); // someone must have called -startLoading
    
    // Check that we're being stopped on the same thread that we were started
    // on.  Without this invariant things are going to go badly (for example,
    // run loop sources that got attached during -startLoading may not get
    // detached here).
    //
    // I originally had code here to bounce over to the client thread but that
    // actually gets complex when you consider run loop modes, so I've nixed it.
    // Rather, I rely on our client calling us on the right thread, which is what
    // the following assert is about.
    assert([NSThread currentThread] == self.clientThread);
    
    [self cancelPendingChallenge];
    if (self.task != nil) {
        [self.task cancel];
        self.task = nil;
        // The following ends up calling -URLSession:task:didCompleteWithError: with NSURLErrorDomain / NSURLErrorCancelled,
        // which specificallys traps and ignores the error.
    }
    // Don't nil out self.modes; see property declaration comments for a a discussion of this.
}

#pragma mark * Authentication challenge handling

/*! Performs the block on the specified thread in one of specified modes.
 *  \param thread The thread to target; nil implies the main thread.
 *  \param modes The modes to target; nil or an empty array gets you the default run loop mode.
 *  \param block The block to run.
 */
- (void)performOnThread:(NSThread *)thread modes:(NSArray *)modes block:(dispatch_block_t)block {
    assert(block != nil);
    
    if (thread == nil) {
        thread = [NSThread mainThread];
    }
    if ([modes count] == 0) {
        modes = @[ NSDefaultRunLoopMode ];
    }
    [self performSelector:@selector(onThreadPerformBlock:) onThread:thread withObject:[block copy] waitUntilDone:NO modes:modes];
}

/*! A helper method used by -performOnThread:modes:block:. Runs in the specified context
 *  and simply calls the block.
 *  \param block The block to run.
 */
- (void)onThreadPerformBlock:(dispatch_block_t)block {
    assert(block != nil);
    block();
}

/*! Called by our NSURLSession delegate callback to pass the challenge to our delegate.
 *  \description This simply passes the challenge over to the main thread.
 *  We do this so that all accesses to pendingChallenge are done from the main thread,
 *  which avoids the need for extra synchronisation.
 *
 *  By the time this runes, the NSURLSession delegate callback has already confirmed with
 *  the delegate that it wants the challenge.
 *
 *  Note that we use the default run loop mode here, not the common modes.  We don't want
 *  an authorisation dialog showing up on top of an active menu (-:
 *
 *  Also, we implement our own 'perform block' infrastructure because Cocoa doesn't have
 *  one <rdar://problem/17232344> and CFRunLoopPerformBlock is inadequate for the
 *  return case (where we need to pass in an array of modes; CFRunLoopPerformBlock only takes
 *  one mode).
 *  \param challenge The authentication challenge to process; must not be nil.
 *  \param completionHandler The associated completion handler; must not be nil.
 */
- (void)didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
                                  session:(NSURLSession *)session
                                     task:(NSURLSessionTask *)task
                        completionHandler:(HJChallengeCompletionHandler)completionHandler {
    assert(challenge != nil);
    assert(completionHandler != nil);
    assert([NSThread currentThread] == self.clientThread);
    
    [[self class] HJURLProtocol:self logWithFormat:@"challenge %@ received", [[challenge protectionSpace] authenticationMethod]];
    
    [self performOnThread:self.clientThread
                    modes:self.modes
                    block:^{
        [self mainThreadDidReceiveAuthenticationChallenge:challenge
                                                  session:session
                                                     task:task
                                        completionHandler:completionHandler];
    }];
}

/*! The main thread side of authentication challenge processing.
 *  \details If there's already a pending challenge, something has gone wrong and
 *  the routine simply cancels the new challenge.  If our delegate doesn't implement
 *  the -HJURLProtocol:canAuthenticateAgainstProtectionSpace: delegate callback,
 *  we also cancel the challenge.  OTOH, if all goes well we simply call our delegate
 *  with the challenge.
 *  \param challenge The authentication challenge to process; must not be nil.
 *  \param completionHandler The associated completion handler; must not be nil.
 */
- (void)mainThreadDidReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
                                            session:(NSURLSession *)session
                                               task:(NSURLSessionTask *)task
                                  completionHandler:(HJChallengeCompletionHandler)completionHandler {
    assert(challenge != nil);
    assert(completionHandler != nil);
    // assert([NSThread isMainThread]);
    
    if (self.pendingChallenge != nil) {
        // Our delegate is not expecting a second authentication challenge before resolving the
        // first.  Likewise, NSURLSession shouldn't send us a second authentication challenge
        // before we resolve the first.  If this happens, assert, log, and cancel the challenge.
        //
        // Note that we have to cancel the challenge on the thread on which we received it,
        // namely, the client thread.
        [[self class] HJURLProtocol:self logWithFormat:@"challenge %@ cancelled; other challenge pending", [[challenge protectionSpace] authenticationMethod]];
        assert(NO);
        [self clientThreadCancelAuthenticationChallenge:challenge completionHandler:completionHandler];
    } else {
        id<HJURLProtocolDelegate> strongDelegate = [[self class] delegate];
        
        // Tell the delegate about it.  It would be weird if the delegate didn't support this
        // selector (it did return YES from -HJURLProtocol:canAuthenticateAgainstProtectionSpace:
        // after all), but if it doesn't then we just cancel the challenge ourselves (or the client
        // thread, of course).
        if (![strongDelegate respondsToSelector:@selector(HJURLProtocol:canAuthenticateAgainstProtectionSpace:)] ) {
            [[self class] HJURLProtocol:self logWithFormat:@"challenge %@ cancelled; no delegate method", [[challenge protectionSpace] authenticationMethod]];
            assert(NO);
            [self clientThreadCancelAuthenticationChallenge:challenge completionHandler:completionHandler];
        } else {
            // Remember that this challenge is in progress.
            self.pendingChallenge = challenge;
            self.pendingChallengeCompletionHandler = completionHandler;
            
            // Pass the challenge to the delegate.
            [[self class] HJURLProtocol:self logWithFormat:@"challenge %@ passed to delegate", [[challenge protectionSpace] authenticationMethod]];
            [strongDelegate HJURLProtocol:self
                                  session:session
                                     task:task
                      didReceiveChallenge:self.pendingChallenge
                        completionHandler:self.pendingChallengeCompletionHandler];
        }
    }
}

/*! Cancels an authentication challenge that hasn't made it to the pending challenge state.
 *  \details This routine is called as part of various error cases in the challenge handling
 *  code.  It cancels a challenge that, for some reason, we've failed to pass to our delegate.
 *
 *  The routine is always called on the main thread but bounces over to the client thread to
 *  do the actual cancellation.
 *  \param challenge The authentication challenge to cancel; must not be nil.
 *  \param completionHandler The associated completion handler; must not be nil.
 */
- (void)clientThreadCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
                                completionHandler:(HJChallengeCompletionHandler)completionHandler {
#pragma unused(challenge)
    assert(challenge != nil);
    assert(completionHandler != nil);
    // assert([NSThread isMainThread]);
    
    [self performOnThread:self.clientThread
                    modes:self.modes
                    block:^{
        completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
    }];
}

/*! Cancels an authentication challenge that /has/ made to the pending challenge state.
 *  \details This routine is called by -stopLoading to cancel any challenge that might be
 *  pending when the load is cancelled.  It's always called on the client thread but
 *  immediately bounces over to the main thread (because .pendingChallenge is a main
 *  thread only value).
 */
- (void)cancelPendingChallenge {
    assert([NSThread currentThread] == self.clientThread);
    
    // Just pass the work off to the main thread.  We do this so that all accesses
    // to pendingChallenge are done from the main thread, which avoids the need for
    // extra synchronisation.
    [self performOnThread:self.clientThread
                    modes:self.modes
                    block:^{
        if (self.pendingChallenge == nil) {
            // This is not only not unusual, it's actually very typical.  It happens every time you shut down
            // the connection.  Ideally I'd like to not even call -mainThreadCancelPendingChallenge when
            // there's no challenge outstanding, but the synchronisation issues are tricky.  Rather than solve
            // those, I'm just not going to log in this case.
            // [[self class] HJURLProtocol:self logWithFormat:@"challenge not cancelled; no challenge pending"];
        } else {
            id<HJURLProtocolDelegate> strongeDelegate = [[self class] delegate];
            NSURLAuthenticationChallenge *challenge = self.pendingChallenge;
            self.pendingChallenge = nil;
            self.pendingChallengeCompletionHandler = nil;
            
            if ([strongeDelegate respondsToSelector:@selector(HJURLProtocol:didCancelChallenge:)]) {
                [[self class] HJURLProtocol:self logWithFormat:@"challenge %@ cancellation passed to delegate", [[challenge protectionSpace] authenticationMethod]];
                [strongeDelegate HJURLProtocol:self didCancelChallenge:challenge];
            } else {
                [[self class] HJURLProtocol:self logWithFormat:@"challenge %@ cancellation failed; no delegate method", [[challenge protectionSpace] authenticationMethod]];
                // If we managed to send a challenge to the client but can't cancel it, that's bad.
                // There's nothing we can do at this point except log the problem.
                assert(NO);
            }
        }
    }];
}

- (void)resolveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
                           disposition:(NSURLSessionAuthChallengeDisposition)disposition
                            credential:(NSURLCredential *)credential {
    assert(challenge == self.pendingChallenge);
    // assert([NSThread isMainThread]);
    // assert(self.clientThread != nil);
    
    if (challenge != self.pendingChallenge) {
        [[self class] HJURLProtocol:self logWithFormat:@"challenge resolution mismatch (%@ / %@)", challenge, self.pendingChallenge];
        // This should never happen, and we want to know if it does, at least in the debug build.
        assert(NO);
    } else {
        HJChallengeCompletionHandler completionHandler = self.pendingChallengeCompletionHandler;
        
        // We clear out our record of the pending challenge and then pass the real work
        // over to the client thread (which ensures that the challenge is resolved on
        // the same thread we received it on).
        self.pendingChallenge = nil;
        self.pendingChallengeCompletionHandler = nil;
        
        [self performOnThread:self.clientThread
                        modes:self.modes
                        block:^{
            if (credential == nil) {
                [[self class] HJURLProtocol:self logWithFormat:@"challenge %@ resolved without credential", [[challenge protectionSpace] authenticationMethod]];
            } else {
                [[self class] HJURLProtocol:self logWithFormat:@"challenge %@ resolved with <%@ %p>", [[challenge protectionSpace] authenticationMethod], [credential class], credential];
            }
            completionHandler(disposition, credential);
        }];
    }
}

#pragma mark * NSURLSession delegate callbacks

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response
        newRequest:(NSURLRequest *)newRequest
 completionHandler:(void (^)(NSURLRequest *))completionHandler {
#pragma unused(session)
#pragma unused(task)
    //    assert(task == self.task);
    //    assert(response != nil);
    //    assert(newRequest != nil);
#pragma unused(completionHandler)
    //    assert(completionHandler != nil);
    //    assert([NSThread currentThread] == self.clientThread);
    
    [[self class] HJURLProtocol:self logWithFormat:@"will redirect from %@ to %@", [response URL], [newRequest URL]];
    
    // The new request was copied from our old request, so it has our magic property.  We actually
    // have to remove that so that, when the client starts the new request, we see it.  If we
    // don't do this then we never see the new request and thus don't get a chance to change
    // its caching behaviour.
    //
    // We also cancel our current connection because the client is going to start a new request for
    // us anyway.
    assert([[self class] propertyForKey:kOurRecursiveRequestFlagProperty inRequest:newRequest] != nil);
    
    NSMutableURLRequest *redirectRequest = [newRequest mutableCopy];
    [[self class] removePropertyForKey:kOurRecursiveRequestFlagProperty inRequest:redirectRequest];
    
    // Tell the client about the redirect.
    
    [[self client] URLProtocol:self wasRedirectedToRequest:redirectRequest redirectResponse:response];
    
    // Stop our load.  The CFNetwork infrastructure will create a new NSURLProtocol instance to run
    // the load of the redirect.
    [self.task cancel];
    
    // The following ends up calling -URLSession:task:didCompleteWithError: with NSURLErrorDomain / NSURLErrorCancelled,
    // which specificallys traps and ignores the error.
    [[self client] URLProtocol:self didFailWithError:[NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil]];
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler {
#pragma unused(session)
#pragma unused(task)
    //    assert(task == self.task);
    //    assert(challenge != nil);
    //    assert(completionHandler != nil);
    //    assert([NSThread currentThread] == self.clientThread);
    
    // Ask our delegate whether it wants this challenge.  We do this from this thread, not the main thread,
    // to avoid the overload of bouncing to the main thread for challenges that aren't going to be customised
    // anyway.
    
    BOOL result = NO;
    id<HJURLProtocolDelegate> strongeDelegate = [[self class] delegate];
    if ([strongeDelegate respondsToSelector:@selector(HJURLProtocol:canAuthenticateAgainstProtectionSpace:)]) {
        result = [strongeDelegate HJURLProtocol:self canAuthenticateAgainstProtectionSpace:[challenge protectionSpace]];
    }
    
    // If the client wants the challenge, kick off that process.  If not, resolve it by doing the default thing.
    if (result) {
        [[self class] HJURLProtocol:self logWithFormat:@"challenge can authenticate %@", [[challenge protectionSpace] authenticationMethod]];
        [self didReceiveAuthenticationChallenge:challenge session:session task:task completionHandler:completionHandler];
    } else {
        [[self class] HJURLProtocol:self logWithFormat:@"challenge cannot authenticate %@", [[challenge protectionSpace] authenticationMethod]];
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
    }
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
#pragma unused(session)
#pragma unused(dataTask)
    //    assert(dataTask == self.task);
    //    assert(response != nil);
    //    assert(completionHandler != nil);
    //    assert([NSThread currentThread] == self.clientThread);
    
    // Pass the call on to our client.  The only tricky thing is that we have to decide on a
    // cache storage policy, which is based on the actual request we issued, not the request
    // we were given.
    NSURLCacheStoragePolicy cacheStoragePolicy;
    NSInteger statusCode;
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        cacheStoragePolicy = HJCacheStoragePolicyForRequestAndResponse(self.task.originalRequest, (NSHTTPURLResponse *)response);
        statusCode = [((NSHTTPURLResponse *) response) statusCode];
    } else {
        assert(NO);
        cacheStoragePolicy = NSURLCacheStorageNotAllowed;
        statusCode = 42;
    }
    
    [[self class] HJURLProtocol:self logWithFormat:@"received response %zd / %@ with cache storage policy %zu", (ssize_t) statusCode, [response URL], (size_t) cacheStoragePolicy];
    
    [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:cacheStoragePolicy];
    
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
#pragma unused(session)
#pragma unused(dataTask)
    //    assert(dataTask == self.task);
    //    assert(data != nil);
    //    assert([NSThread currentThread] == self.clientThread);
    
    // Just pass the call on to our client.
    [[self class] HJURLProtocol:self logWithFormat:@"received %zu bytes of data", (size_t) [data length]];
    
    [[self client] URLProtocol:self didLoadData:data];
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
 willCacheResponse:(NSCachedURLResponse *)proposedResponse
 completionHandler:(void (^)(NSCachedURLResponse *))completionHandler {
#pragma unused(session)
#pragma unused(dataTask)
    //    assert(dataTask == self.task);
    //    assert(proposedResponse != nil);
    //    assert(completionHandler != nil);
    //    assert([NSThread currentThread] == self.clientThread);
    
    // We implement this delegate callback purely for the purposes of logging.
    [[self class] HJURLProtocol:self logWithFormat:@"will cache response"];
    
    completionHandler(proposedResponse);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
#pragma unused(session)
#pragma unused(task)
    //    assert( (self.task == nil) || (task == self.task) );        // can be nil in the 'cancel from -stopLoading' case
    //    assert([NSThread currentThread] == self.clientThread);
    // An NSURLSession delegate callback.  We pass this on to the client.
    
    // Just log and then, in most cases, pass the call on to our client.
    if (error == nil) {
        [[self class] HJURLProtocol:self logWithFormat:@"success"];
        
        [[self client] URLProtocolDidFinishLoading:self];
    } else if ([[error domain] isEqual:NSURLErrorDomain] && ([error code] == NSURLErrorCancelled) ) {
        // Do nothing.  This happens in two cases:
        //
        // o during a redirect, in which case the redirect code has already told the client about
        //   the failure
        //
        // o if the request is cancelled by a call to -stopLoading, in which case the client doesn't
        //   want to know about the failure
    } else {
        [[self class] HJURLProtocol:self logWithFormat:@"error %@ / %d", [error domain], (int) [error code]];
        
        [[self client] URLProtocol:self didFailWithError:error];
    }
    
    // We don't need to clean up the connection here; the system will call, or has already called,
    // -stopLoading to do that.
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didFinishCollectingMetrics:(NSURLSessionTaskMetrics *)metrics API_AVAILABLE(macosx(10.12), ios(10.0), watchos(3.0), tvos(10.0)) {
#pragma unused(session)
#pragma unused(task)
    //    assert(task == self.task);
    //    assert([NSThread currentThread] == self.clientThread);
    
    id<HJURLProtocolDelegate> strongDelegate = [[self class] delegate];
    if ([strongDelegate respondsToSelector:@selector(HJURLProtocol:session:task:didFinishCollectingMetrics:)]) {
        [strongDelegate HJURLProtocol:self session:session task:task didFinishCollectingMetrics:metrics];
    }
}

@end
