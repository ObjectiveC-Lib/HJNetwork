//
//  HJNetworkCache.h
//  HJNetwork
//
//  Created by navy on 2019/3/7.
//  Copyright © 2019 HJNetwork. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <HJCache/HJCache.h>

NS_ASSUME_NONNULL_BEGIN

@interface HJNetworkCache : NSObject

#pragma mark - Attribute

@property (copy, readonly) NSString *name;
@property (strong, readonly) HJMemoryCache *memoryCache;
@property (strong, readonly) HJDiskCache *diskCache;

#pragma mark - Initializer

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (instancetype)new UNAVAILABLE_ATTRIBUTE;

+ (HJNetworkCache *)sharedCache;

#pragma mark - Access Methods

- (BOOL)containsObjectForKey:(NSString *)key;
- (void)containsObjectForKey:(NSString *)key withBlock:(nullable void(^)(NSString *key, BOOL contains))block;

- (nullable id<NSCoding>)objectForKey:(NSString *)key;
- (void)objectForKey:(NSString *)key withBlock:(nullable void(^)(NSString *key, id<NSCoding> object))block;

- (nullable id)extendedDataForKey:(NSString *)key;

- (void)setObject:(nullable id<NSCoding>)object forKey:(NSString *)key withExtendedData:(id)extendedData;

- (void)removeObjectForKey:(NSString *)key;
- (void)removeObjectForKey:(NSString *)key withBlock:(nullable void(^)(NSString *key))block;

- (void)removeAllObjects;
- (void)removeAllObjectsWithBlock:(void(^)(void))block;

- (void)removeAllObjectsWithProgressBlock:(nullable void(^)(int removedCount, int totalCount))progress
                                 endBlock:(nullable void(^)(BOOL error))end;

- (NSInteger)totalCost;

@end

NS_ASSUME_NONNULL_END
