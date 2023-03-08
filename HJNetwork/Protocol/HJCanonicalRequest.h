//
//  HJCanonicalRequest.h
//  HJNetwork
//
//  Created by navy on 2022/5/27.
//  Copyright © 2022 HJNetwork. All rights reserved.
//

#import <Foundation/Foundation.h>

/*! Returns a canonical form of the supplied request.
 *  \details The Foundation URL loading system needs to be able to canonicalize URL
 *  requests for various reasons (for example, to look for cache hits).  The default
 *  HTTP/HTTPS protocol has a complex chunk of code to perform this function.  Unfortunately
 *  there's no way for third party code to access this.  Instead, we have to reimplement
 *  it all ourselves.  This is split off into a separate file to emphasise that this
 *  is standard boilerplate that you probably don't need to look at.
 *
 *  IMPORTANT: While you can take most of this code as read, you might want to tweak
 *  the handling of the "Accept-Language" in the CanonicaliseHeaders routine.
 *  \param request The request to canonicalise; must not be nil.
 *  \returns The canonical request; should never be nil.
 */
extern NSMutableURLRequest * HJCanonicalRequestForRequest(NSURLRequest *request);
extern NSMutableURLRequest * HJGetMutablePostRequestIncludeBodyForRequest(NSURLRequest *request);
