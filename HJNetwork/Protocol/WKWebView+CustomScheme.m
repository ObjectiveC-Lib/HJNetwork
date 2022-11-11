//
//  WKWebView+CustomScheme.m
//  HJNetwork
//
//  Created by navy on 2022/8/9.
//  Copyright © 2022 HJNetwork. All rights reserved.
//

#import "WKWebView+CustomScheme.h"

FOUNDATION_STATIC_INLINE Class WK_ContextControllerClass() {
    static Class cls;
    if (!cls) {
        cls = [[[WKWebView new] valueForKey:@"browsingContextController"] class];
    }
    return cls;
}

FOUNDATION_STATIC_INLINE SEL WK_RegisterSchemeSelector() {
    return NSSelectorFromString(@"registerSchemeForCustomProtocol:");
}

FOUNDATION_STATIC_INLINE SEL WK_UnregisterSchemeSelector() {
    return NSSelectorFromString(@"unregisterSchemeForCustomProtocol:");
}

@implementation WKWebView (CustomScheme)

+ (void)registerCustomScheme:(NSString *)scheme {
    Class cls = WK_ContextControllerClass();
    SEL sel = WK_RegisterSchemeSelector();
    if ([(id)cls respondsToSelector:sel]) {
        NSString *avilableScheme = [[[NSURL URLWithString:scheme] scheme] lowercaseString];
        if (!avilableScheme) {
            avilableScheme = scheme;
        }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [(id)cls performSelector:sel withObject:avilableScheme];
#pragma clang diagnostic pop
    }
}

+ (void)unregisterCustomScheme:(NSString *)scheme {
    Class cls = WK_ContextControllerClass();
    SEL sel = WK_UnregisterSchemeSelector();
    if ([(id)cls respondsToSelector:sel]) {
        NSString *avilableScheme = [[[NSURL URLWithString:scheme] scheme] lowercaseString];
        if (!avilableScheme) {
            avilableScheme = scheme;
        }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [(id)cls performSelector:sel withObject:scheme];
#pragma clang diagnostic pop
    }
}

@end
