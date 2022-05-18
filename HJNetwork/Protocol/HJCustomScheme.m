//
//  HJCustomScheme.m
//  HJNetwork
//
//  Created by navy on 2022/6/8.
//

#import "HJCustomScheme.h"

#define Lock() dispatch_semaphore_wait(self->_lock, DISPATCH_TIME_FOREVER)
#define Unlock() dispatch_semaphore_signal(self->_lock)

@implementation HJSchemeItem
@end

@interface HJCustomScheme () {
    dispatch_semaphore_t _lock;
    NSMutableDictionary *_dict;
}
@end

@implementation HJCustomScheme

+ (instancetype)sharedInstance {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _lock = dispatch_semaphore_create(1);
        _dict = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (NSString *)getAvilableScheme:(NSString *)urlString {
    NSString *avilableScheme = nil;
    if ([urlString hasPrefix:@"http"]) {
        avilableScheme = [[[NSURL URLWithString:urlString] host] lowercaseString];
    } else {
        avilableScheme = [[[NSURL URLWithString:urlString] scheme] lowercaseString];
    }
    if (!avilableScheme) {
        avilableScheme = urlString;
    }
    return avilableScheme;
}

- (void)registerScheme:(NSString *)urlString selector:(SEL)selector {
    if (!urlString || !selector) return;
    if (urlString.length <= 0) return;
    if (![urlString isKindOfClass:[NSString class]]) return;
    
    NSString *scheme = [self getAvilableScheme:urlString];
    
    HJSchemeItem *item = [[HJSchemeItem alloc] init];
    item.scheme = scheme;
    item.selector = selector;
    
    Lock();
    [_dict setObject:item forKey:scheme];
    Unlock();
}

- (void)unregisterScheme:(NSString *)urlString {
    if (!urlString) return;
    if (urlString.length <= 0) return;
    if (![urlString isKindOfClass:[NSString class]]) return;
    
    NSString *scheme = [self getAvilableScheme:urlString];
    
    Lock();
    if (![_dict.allKeys containsObject:scheme]) return;
    [_dict removeObjectForKey:scheme];
    Unlock();
}

- (BOOL)containsScheme:(NSString *)urlString {
    if (!urlString) return NO;
    if (urlString.length <= 0) return NO;
    if (![urlString isKindOfClass:[NSString class]]) return NO;
    
    NSString *scheme = [self getAvilableScheme:urlString];
    
    Lock();
    BOOL contains = ([_dict.allKeys containsObject:scheme]);
    Unlock();
    return contains;
}

- (HJSchemeItem *)objectSchemeForKey:(NSString *)urlString {
    if (!urlString) return NO;
    if (urlString.length <= 0) return NO;
    if (![urlString isKindOfClass:[NSString class]]) return NO;
    
    NSString *scheme = [self getAvilableScheme:urlString];
    
    Lock();
    HJSchemeItem *item = ([_dict.allKeys containsObject:scheme])?[_dict objectForKey:scheme]:nil;
    Unlock();
    return item;
}

+ (void)registerScheme:(NSString *)urlString selector:(SEL)selector {
    [[HJCustomScheme sharedInstance] registerScheme:urlString selector:selector];
}

+ (void)unregisterScheme:(NSString *)urlString {
    [[HJCustomScheme sharedInstance] unregisterScheme:urlString];
}

+ (BOOL)containsScheme:(NSString *)urlString {
    return [[HJCustomScheme sharedInstance] containsScheme:urlString];
}

+ (HJSchemeItem *)objectSchemeForKey:(NSString *)urlString {
    return [[HJCustomScheme sharedInstance] objectSchemeForKey:urlString];
}

@end
