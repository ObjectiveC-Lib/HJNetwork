//
//  DMSDWebImageOperation.m
//  HJNetworkDemo
//
//  Created by navy on 2022/8/4.
//

#import "DMSDWebImageOperation.h"
#import "HJCredentialChallenge.h"

@implementation DMSDWebImageOperation

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {
    __block NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    __block NSURLCredential *credential = nil;
    
    NSString *host = task.currentRequest.allHTTPHeaderFields[@"host"];;
    if (!host || [HJCredentialChallenge isIPAddress:host]) {
        host = task.currentRequest.URL.host;
    }
    
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        if (!(self.options & SDWebImageDownloaderAllowInvalidSSLCertificates)) {
            [HJCredentialChallenge challenge:challenge
                                        host:host
                           completionHandler:^(NSURLSessionAuthChallengeDisposition dis, NSURLCredential * _Nullable cred) {
                disposition = dis;
                credential = cred;
            }];
        } else {
            credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
            disposition = NSURLSessionAuthChallengeUseCredential;
        }
    } else {
        if (challenge.previousFailureCount == 0) {
            if (self.credential) {
                credential = self.credential;
                disposition = NSURLSessionAuthChallengeUseCredential;
            } else {
                disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
            }
        } else {
            disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
        }
    }
    
    if (completionHandler) {
        completionHandler(disposition, credential);
    }
}

@end
