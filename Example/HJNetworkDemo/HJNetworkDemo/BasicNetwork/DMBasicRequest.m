//
//  DMBasicRequest.m
//  HJNetworkDemo
//
//  Created by navy on 2020/12/25.
//

#import "DMBasicRequest.h"
#import "DMInlineHeader.h"

@implementation DMBasicRequest

- (void)requestCompletePreprocessor {
    [super requestCompletePreprocessor];
}

- (void)requestCompleteFilter {
    [super requestCompleteFilter];
}

- (void)requestFailedPreprocessor {
    [super requestFailedPreprocessor];
}

- (void)requestFailedFilter {
    [super requestFailedFilter];
    
    NSLog(@"Request %@ failed\n url = %@\n error domain = %@\n error code: %ld\n status code = %ld\n error desc: %@\n error reason: %@\n error info = %@\n underlying error = %@",
          NSStringFromClass([self class]),
          self.originalRequest.URL.description,
          self.error.domain,
          (long)self.error.code,
          (long)self.responseStatusCode,
          self.error.localizedDescription,
          self.error.localizedFailureReason,
          self.error.userInfo,
          self.error.userInfo[NSUnderlyingErrorKey]
          );
    
    if ([self.error.domain isEqualToString:NSURLErrorDomain]) {
        NSLog(@"NSURLErrorDomain");
    } else if ([self.error.domain isEqualToString:AFURLRequestSerializationErrorDomain]) {
        NSLog(@"AFURLRequestSerializationErrorDomain");
        NSString *failureReason = self.error.userInfo[NSLocalizedFailureReasonErrorKey];
        NSLog(@"failure reason: %@",failureReason);
        
        if (self.error.code == NSURLErrorBadURL) {
        } else if (self.error.code == NSURLErrorCannotDecodeContentData) {
        } else {
        }
    } else if ([self.error.domain isEqualToString:AFURLResponseSerializationErrorDomain]) {
        NSLog(@"AFURLResponseSerializationErrorDomain");
        
        NSDictionary *userInfo = self.error.userInfo;
        NSURL *failingURL = userInfo[NSURLErrorFailingURLErrorKey];
        NSString *localizedDesc = userInfo[NSLocalizedDescriptionKey]; // self.error.localizedDescription
        //        NSHTTPURLResponse *response = userInfo[AFNetworkingOperationFailingURLResponseErrorKey]; // self.response
        //        NSData *responseData = userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] ; // self.responseData
        NSLog(@"localized desc: %@,\n failing url: %@,\n",
              localizedDesc,
              failingURL.absoluteString);
        
        if (self.error.code == NSURLErrorBadServerResponse) {
        } else if (self.error.code == NSURLErrorCannotDecodeContentData) {
        } else {
        }
        
        //        NSString *addr = NSStringFromClass([self class]);
        //        NSInteger httpCode = response.statusCode; // self.responseStatusCode
        //        NSString *host = [[failingURL.absoluteString componentsSeparatedByString:@"?"] objectAtIndex:0];
    } else if ([self.error.domain isEqualToString:HJRequestValidationErrorDomain]) {
        NSLog(@"HJRequestValidationErrorDomain");
        NSString *localizedDesc = self.error.userInfo[NSLocalizedDescriptionKey]; // self.error.localizedDescription
        NSLog(@"localized desc: %@",localizedDesc);
        
        if (self.error.code == HJRequestValidationErrorInvalidJSONFormat) {
        } else if (self.error.code == HJRequestValidationErrorInvalidStatusCode) {
        } else if (self.error.code == HJRequestValidationErrorInvalidCustomError) {
            NSDictionary *response = self.responseJSONObject;
            NSString *httpCode = [NSString stringWithFormat:@"%@", response[@"code"]];
            NSLog(@"httpCode = %@", httpCode);
        }
    } else if ([self.error.domain isEqualToString:HJRequestCacheErrorDomain]) {
        NSLog(@"HJRequestCacheErrorDomain");
        NSString *localizedDesc = self.error.userInfo[NSLocalizedDescriptionKey]; // self.error.localizedDescription
        NSLog(@"localized desc: %@",localizedDesc);
        
        if (self.error.code == HJRequestCacheErrorExpired) {
        } else if (self.error.code == HJRequestCacheErrorVersionMismatch) {
        } else if (self.error.code == HJRequestCacheErrorSensitiveDataMismatch) {
        } else if (self.error.code == HJRequestCacheErrorAppVersionMismatch) {
        } else if (self.error.code == HJRequestCacheErrorInvalidCacheTime) {
        } else if (self.error.code == HJRequestCacheErrorInvalidMetadata) {
        } else if (self.error.code == HJRequestCacheErrorInvalidCacheData) {
        } else {
        }
    } else {
        
    }
}

- (NSDictionary *)requestHeaderFieldValueDictionary {
    return @{ @"Cache-Control":@"no-store" };
}

@end
