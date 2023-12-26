//
//  HJDNSMap.m
//  HJNetwork
//
//  Created by navy on 2022/11/10.
//  Copyright © 2022 HJNetwork. All rights reserved.
//

#import "HJDNSMap.h"
#import <CoreFoundation/CoreFoundation.h>
#import <pthread/pthread.h>
#import <arpa/inet.h>

static BOOL HJIsIPAddress(NSString *str) {
    if (!str) return NO;
    
    int success;
    struct in_addr dst;
    struct in6_addr dst6;
    const char *utf8 = [str UTF8String];
    
    success = inet_pton(AF_INET, utf8, &(dst.s_addr)); // check IPv4 address
    if (!success) {
        success = inet_pton(AF_INET6, utf8, &dst6); // check IPv6 address
    }
    
    return success;
}

@interface HJDNSLinkedMapNode : NSObject {
    @package
    __unsafe_unretained HJDNSLinkedMapNode *_prev;
    __unsafe_unretained HJDNSLinkedMapNode *_next;
    id _key;
    id _value;
    NSUInteger _failCount;
}
@end

@implementation HJDNSLinkedMapNode
@end

@interface HJDNSLinkedMap : NSObject {
    @package
    HJDNSLinkedMap *_prev;
    HJDNSLinkedMapNode *_current;
    CFMutableArrayRef _arr;
    NSUInteger _totalCount;
    HJDNSLinkedMapNode *_head;
    HJDNSLinkedMapNode *_tail;
}
- (void)insertNodeAtHead:(HJDNSLinkedMapNode *)node;
- (void)bringNodeToHead:(HJDNSLinkedMapNode *)node;
- (void)removeNode:(HJDNSLinkedMapNode *)node;
- (HJDNSLinkedMapNode *)removeTailNode;
- (HJDNSLinkedMapNode *)removeHeadNode;
- (void)removeAll;
@end

@implementation HJDNSLinkedMap

- (void)dealloc {
    CFRelease(_arr);
}

- (instancetype)init {
    self = [super init];
    _arr = CFArrayCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeArrayCallBacks);
    return self;
}

- (void)insertNodeAtHead:(HJDNSLinkedMapNode *)node {
    if (!node) return;
    
    CFArrayInsertValueAtIndex(_arr, 0, (__bridge const void *)(node));
    _totalCount++;
    if (_head) {
        node->_next = _head;
        _head->_prev = node;
        _head = node;
    } else {
        _head = _tail = node;
    }
}

- (void)bringNodeToHead:(HJDNSLinkedMapNode *)node {
    if (_head == node || !node) return;
    
    if (CFArrayContainsValue(_arr, CFRangeMake(0, CFArrayGetCount(_arr)), (__bridge const void *)(node))) {
        //        CFArrayRemoveValueAtIndex(_arr, CFArrayGetFirstIndexOfValue(_arr, CFRangeMake(0, CFArrayGetCount(_arr)), (__bridge const void *)(node)));
        //        CFArrayInsertValueAtIndex(_arr, 0, (__bridge const void *)(node));
        if (_tail == node) {
            _tail = node->_prev;
            _tail->_next = nil;
        } else {
            node->_next->_prev = node->_prev;
            node->_prev->_next = node->_next;
        }
        node->_next = _head;
        node->_prev = nil;
        _head->_prev = node;
        _head = node;
    }
}

- (void)bringNodeToTail:(HJDNSLinkedMapNode *)node {
    if (_tail == node || !node) return;
    
    if (CFArrayContainsValue(_arr, CFRangeMake(0, CFArrayGetCount(_arr)), (__bridge const void *)(node))) {
        //        CFArrayRemoveValueAtIndex(_arr, CFArrayGetFirstIndexOfValue(_arr, CFRangeMake(0, CFArrayGetCount(_arr)), (__bridge const void *)(node)));
        //        CFArrayInsertValueAtIndex(_arr, CFArrayGetCount(_arr) - 1, (__bridge const void *)(node));
        if (_head == node) {
            _head = node->_next;
            _head->_prev = nil;
        } else {
            node->_prev->_next = node->_next;
            node->_next->_prev = node->_prev;
        }
        node->_prev = _tail;
        node->_next = nil;
        _tail->_next = node;
        _tail = node;
    }
}

- (void)removeNode:(HJDNSLinkedMapNode *)node {
    if (CFArrayGetCount(_arr) > 0 && CFArrayContainsValue(_arr, CFRangeMake(0, CFArrayGetCount(_arr)), (__bridge const void *)(node))) {
        CFArrayRemoveValueAtIndex(_arr, CFArrayGetFirstIndexOfValue(_arr, CFRangeMake(0, CFArrayGetCount(_arr)), (__bridge const void *)(node)));
        _totalCount--;
        if (node->_next) node->_next->_prev = node->_prev;
        if (node->_prev) node->_prev->_next = node->_next;
        if (_head == node) _head = node->_next;
        if (_tail == node) _tail = node->_prev;
    }
}

- (HJDNSLinkedMapNode *)removeHeadNode {
    if (!_head) return nil;
    
    HJDNSLinkedMapNode *head = _head;
    if (CFArrayGetCount(_arr) > 0) {
        CFArrayRemoveValueAtIndex(_arr, 0);
        _totalCount--;
        if (_head == _tail) {
            _head = _tail = nil;
        } else {
            _head = _head->_next;
            _head->_prev = nil;
        }
    }
    return head;
}

- (HJDNSLinkedMapNode *)removeTailNode {
    if (!_tail) return nil;
    
    HJDNSLinkedMapNode *tail = _tail;
    if (CFArrayGetCount(_arr) > 0) {
        CFArrayRemoveValueAtIndex(_arr, CFArrayGetCount(_arr) - 1);
        _totalCount--;
        if (_head == _tail) {
            _head = _tail = nil;
        } else {
            _tail = _tail->_prev;
            _tail->_next = nil;
        }
    }
    return tail;
}

- (nullable HJDNSLinkedMapNode *)headNode {
    HJDNSLinkedMapNode *node = _head;
    return node;
}

- (void)removeAll {
    _totalCount = 0;
    _head = nil;
    _tail = nil;
    _current = nil;
    _prev = nil;
    
    if (CFArrayGetCount(_arr) > 0) {
        CFMutableArrayRef holder = _arr;
        _arr = CFArrayCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeArrayCallBacks);
        CFRelease(holder);
    }
}

@end


@interface HJDNSDict : NSObject {
    @package
    CFMutableDictionaryRef _dict;
}
@end

@implementation HJDNSDict

- (void)dealloc {
    CFRelease(_dict);
}

- (instancetype)initWithDict:(NSDictionary <NSString*, NSArray*> *)dict {
    self = [super init];
    if (self) {
        _dict = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        [self setupMap:dict];
    }
    return self;
}

- (void)setupMap:(NSDictionary <NSString*, NSArray*> *)dict {
    if (!dict || !dict.count) return;
    
    [dict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSArray * _Nonnull values, BOOL * _Nonnull stop) {
        // NSArray *newArray = [[NSSet setWithArray:values] allObjects]; // deduplication Disorder
        NSMutableArray *newArray = [NSMutableArray array]; // deduplication order
        [values enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (![newArray containsObject:obj] ) {
                [newArray addObject:obj];
            }
        }];
        
        if (newArray.count) {
            HJDNSLinkedMap *map = CFDictionaryGetValue(_dict, (__bridge const void *)(key));
            if (map) {
                [map removeAll];
            } else {
                map = [HJDNSLinkedMap new];
            }
            
            [newArray enumerateObjectsWithOptions:NSEnumerationReverse
                                       usingBlock:^(id _Nonnull value, NSUInteger idx, BOOL * _Nonnull stop) {
                HJDNSLinkedMapNode *node = [HJDNSLinkedMapNode new];
                node->_key = key;
                node->_value = value;
                [map insertNodeAtHead:node];
            }];
            CFDictionarySetValue(_dict, (__bridge const void *)(key), (__bridge const void *)(map));
        }
    }];
}

- (void)cleanTempVariables {
    if (CFDictionaryGetCount(_dict) > 0) {
        CFDictionaryApplyFunction(_dict, _cleanVariables, NULL);
    }
}

void _cleanVariables(const void *key, const void *value, void *context) {
    CFTypeRef _value = (CFTypeRef)value;
    HJDNSLinkedMap *strValue = (__bridge HJDNSLinkedMap *)_value;
    if (strValue) {
        strValue->_current = nil;
        strValue->_prev = nil;
    }
}

- (NSString *)description {
    //    size_t count = CFDictionaryGetCount(_dict);
    //    CFStringRef keys[count];
    //    CFTypeRef values[count];
    //    CFDictionaryGetKeysAndValues(_dict, (const void **)keys, (const void **)values);
    NSMutableDictionary <NSString*, NSArray*> *_desc = [NSMutableDictionary new];
    CFDictionaryApplyFunction(_dict, descriptionFunction, (__bridge const void *)(_desc));
    return [NSString stringWithFormat:@"<%@: %p>\n%@", self.class, self, _desc];
}

void descriptionFunction(const void *key, const void *value, void *context) {
    CFStringRef _key = (CFStringRef)key;
    CFTypeRef _value = (CFTypeRef)value;
    CFTypeRef _desc = (CFTypeRef)context;
    NSMutableDictionary *desc = (__bridge NSMutableDictionary *)_desc;
    
    NSString *strKey = (__bridge NSString *)_key;
    HJDNSLinkedMap *strValue = (__bridge HJDNSLinkedMap *)_value;
    HJDNSLinkedMapNode *node = [strValue headNode];
    if (node) {
        NSMutableArray *arr = [NSMutableArray new];
        do {
            [arr addObject:[NSString stringWithFormat:@"%@, %d", node->_value, node->_failCount]];
            node = node->_next;
        } while (node != nil);
        [desc setObject:arr forKey:strKey];
    }
}

@end

#define Lock() pthread_mutex_lock(&_lock)
#define Unlock() pthread_mutex_unlock(&_lock)

@implementation HJDNSMap {
    HJDNSDict *_dns;
    NSUInteger _negativeCount;
    pthread_mutex_t _lock;
}

#pragma mark - Initializer

- (void)dealloc {
    pthread_mutex_destroy(&_lock);
}

- (instancetype)initWithDict:(NSDictionary <NSString*, NSArray*> *)dict negativeCount:(NSUInteger)negativeCount {
    self = [super init];
    if (self) {
        pthread_mutex_init(&_lock, NULL);
        _dns = [[HJDNSDict alloc] initWithDict:dict];
        _negativeCount = negativeCount;
        if (negativeCount <= 0) {
            _negativeCount = 1;
        }
    }
    return self;
}

- (nullable NSString *)getDNSValue:(NSString *)key {
    if (!key || key.length <= 0) return nil;
    
    NSString *value = nil;
    Lock();
    HJDNSLinkedMap *map = CFDictionaryGetValue(_dns->_dict, (__bridge const void *)(key));
    if (map) {
        NSString *host = nil;
        do {
            HJDNSLinkedMapNode *node;
            if (map->_current && map->_current != map->_head) {
                node = map->_current;
            } else {
                node = map->_head;
            }
            value = node->_value;
            host = [NSURL URLWithString:value].host;
            
            if (node->_failCount >= _negativeCount) {
                HJDNSLinkedMap *tmpMap = map->_prev;
                if (tmpMap) {
                    map = tmpMap;
                    if (map->_current->_next) {
                        map->_current = map->_current->_next;
                    } else {
                        map = nil;
                        value = nil;
                    }
                } else {
                    map = nil;
                    value = nil;
                }
            } else {
                if (HJIsIPAddress(host)) {
                    map = nil;
                } else {
                    if (!map->_current) {
                        map->_current = map->_head;
                    }
                    HJDNSLinkedMap *tmpMap = CFDictionaryGetValue(_dns->_dict, (__bridge const void *)(value));
                    if (tmpMap) {
                        tmpMap->_prev = map;
                        map = tmpMap;
                    } else {
                        if (node->_failCount >= _negativeCount) {
                            if (map->_current->_next) {
                                map->_current = map->_current->_next;
                            } else {
                                map->_current = nil;
                            }
                            while (map && !map->_current) {
                                map = map->_prev;
                                if (map) {
                                    if (map->_current->_next) {
                                        map->_current = map->_current->_next;
                                    } else {
                                        map->_current = nil;
                                    }
                                }
                            }
                        } else {
                            map = nil;
                        }
                    }
                }
            }
        } while (map);
        [_dns cleanTempVariables];
    }
    Unlock();
    return value;
}

- (void)setNegativeDNSValue:(NSString *)dnsValue key:(NSString *)key {
    if (!dnsValue || dnsValue.length <= 0 || !key || key.length <= 0) return;
    
    Lock();
    HJDNSLinkedMap *map = CFDictionaryGetValue(_dns->_dict, (__bridge const void *)(key));
    if (map) {
        NSString *value = nil;
        do {
            HJDNSLinkedMapNode *node;
            if (map->_current && map->_current != map->_head) {
                node = map->_current;
            } else {
                node = map->_head;
            }
            value = node->_value;
            
            if ([value isEqualToString:dnsValue]) {
                node->_failCount += 1;
                [map bringNodeToTail:node];
                map = nil;
            } else {
                if (!map->_current) {
                    map->_current = map->_head;
                }
                HJDNSLinkedMap *tmpMap = CFDictionaryGetValue(_dns->_dict, (__bridge const void *)(value));
                if (tmpMap) {
                    tmpMap->_prev = map;
                    map = tmpMap;
                } else {
                    if (map->_current->_next) {
                        map->_current = map->_current->_next;
                    } else {
                        map->_current = nil;
                    }
                    while (map && !map->_current) {
                        map = map->_prev;
                        if (map) {
                            if (map->_current->_next) {
                                map->_current = map->_current->_next;
                            } else {
                                map->_current = nil;
                            }
                        }
                    }
                }
            }
        } while (map);
        [_dns cleanTempVariables];
    }
    Unlock();
}

- (void)setPositiveDNSValue:(NSString *)dnsValue key:(NSString *)key {
    if (!dnsValue || dnsValue.length <= 0 || !key || key.length <= 0) return;
    
    Lock();
    HJDNSLinkedMap *map = CFDictionaryGetValue(_dns->_dict, (__bridge const void *)(key));
    if (map) {
        NSString *value = nil;
        do {
            HJDNSLinkedMapNode *node;
            if (map->_current && map->_current != map->_head) {
                node = map->_current;
            } else {
                node = map->_head;
            }
            value = node->_value;
            
            if ([value isEqualToString:dnsValue]) {
                node->_failCount = 0;
                [map bringNodeToHead:node];
                map = nil;
            } else {
                if (!map->_current) {
                    map->_current = map->_head;
                }
                HJDNSLinkedMap *tmpMap = CFDictionaryGetValue(_dns->_dict, (__bridge const void *)(value));
                if (tmpMap) {
                    tmpMap->_prev = map;
                    map = tmpMap;
                } else {
                    if (map->_current->_next) {
                        map->_current = map->_current->_next;
                    } else {
                        map->_current = nil;
                    }
                    while (map && !map->_current) {
                        map = map->_prev;
                        if (map) {
                            if (map->_current->_next) {
                                map->_current = map->_current->_next;
                            } else {
                                map->_current = nil;
                            }
                        }
                    }
                }
            }
        } while (map);
        [_dns cleanTempVariables];
    }
    Unlock();
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p>\n%@", self.class, self, self->_dns];
}

@end

