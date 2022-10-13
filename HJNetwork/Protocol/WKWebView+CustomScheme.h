//
//  WKWebView+CustomScheme.h
//  HJNetwork
//
//  Created by navy on 2022/8/9.
//

#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKWebView (CustomScheme)

+ (void)registerCustomScheme:(NSString *)scheme;
+ (void)unregisterCustomScheme:(NSString *)scheme;

@end

NS_ASSUME_NONNULL_END
