//
//  HJDNSMap.h
//  HJNetwork
//
//  Created by navy on 2022/11/10.
//  Copyright © 2022 HJNetwork. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HJDNSMap : NSObject

- (instancetype)initWithDict:(NSDictionary <NSString*, NSArray*> *)dict
               negativeCount:(NSUInteger)negativeCount;

- (nullable NSString *)getDNSValue:(NSString *)key;
- (void)setNegativeDNSValue:(NSString *)value key:(NSString *)key;
- (void)setPositiveDNSValue:(NSString *)value key:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
