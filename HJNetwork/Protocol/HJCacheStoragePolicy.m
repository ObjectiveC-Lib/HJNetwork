//
//  HJCacheStoragePolicy.m
//  HJNetwork
//
//  Created by navy on 2022/5/27.
//  Copyright © 2022 HJNetwork. All rights reserved.
//

#import "HJCacheStoragePolicy.h"

extern NSURLCacheStoragePolicy HJCacheStoragePolicyForRequestAndResponse(NSURLRequest * request, NSHTTPURLResponse * response) {
    BOOL                        cacheable;
    NSURLCacheStoragePolicy     result;
    
    //    assert(request != NULL);
    //    assert(response != NULL);
    
    // First determine if the request is cacheable based on its status code.
    switch ([response statusCode]) {
        case 200:
        case 203:
        case 206:
        case 301:
        case 304:
        case 404:
        case 410: {
            cacheable = YES;
        } break;
        default: {
            cacheable = NO;
        } break;
    }
    
    // If the response might be cacheable, look at the "Cache-Control" header in
    // the response.
    
    // IMPORTANT: We can't rely on -rangeOfString: returning valid results if the target
    // string is nil, so we have to explicitly test for nil in the following two cases.
    if (cacheable) {
        NSString *responseHeader = [[response allHeaderFields][@"Cache-Control"] lowercaseString];
        if ((responseHeader != nil) && [responseHeader rangeOfString:@"no-store"].location != NSNotFound) {
            cacheable = NO;
        }
    }
    
    // If we still think it might be cacheable, look at the "Cache-Control" header in the request.
    if (cacheable) {
        NSString *requestHeader = [[request allHTTPHeaderFields][@"Cache-Control"] lowercaseString];
        if ((requestHeader != nil) &&
            ([requestHeader rangeOfString:@"no-store"].location != NSNotFound) &&
            ([requestHeader rangeOfString:@"no-cache"].location != NSNotFound)) {
            cacheable = NO;
        }
    }
    
    // Use the cacheable flag to determine the result.
    if (cacheable) {
        // This code only caches HTTPS data in memory.  This is inline with earlier versions of
        // iOS.  Modern versions of iOS use file protection to protect the cache, and thus are
        // happy to cache HTTPS on disk.  I've not made the correspondencing change because
        // it's nice to see all three cache policies in action.
        if ([[[[request URL] scheme] lowercaseString] isEqual:@"https"]) {
            result = NSURLCacheStorageAllowedInMemoryOnly;
        } else {
            result = NSURLCacheStorageAllowed;
        }
    } else {
        result = NSURLCacheStorageNotAllowed;
    }
    
    return result;
}
