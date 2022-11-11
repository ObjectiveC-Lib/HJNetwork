//
//  HJCustomScheme.h
//  HJNetwork
//
//  Created by navy on 2022/6/8.
//  Copyright © 2022 HJNetwork. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HJSchemeItem : NSObject
@property (nonatomic, strong) NSString *scheme;
@property (nonatomic, assign) SEL selector;
@end


@interface HJCustomScheme : NSObject

+ (void)registerScheme:(NSString *)urlString selector:(SEL)selector;
+ (void)unregisterScheme:(NSString *)urlString;
+ (BOOL)containsScheme:(NSString *)urlString;
+ (nullable HJSchemeItem *)objectSchemeForKey:(NSString *)urlString;

@end

NS_ASSUME_NONNULL_END
