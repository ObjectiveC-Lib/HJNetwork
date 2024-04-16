//
//  HJDNSResolveManager.m
//  HJNetwork
//
//  Created by navy on 2022/11/10.
//  Copyright © 2022 HJNetwork. All rights reserved.
//

#import "HJDNSResolveManager.h"
#import <arpa/inet.h>
#import <pthread/pthread.h>
#import "HJDNSMap.h"

#define Lock() pthread_mutex_lock(&_lock)
#define Unlock() pthread_mutex_unlock(&_lock)

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

@interface HJDNSResolveManager ()
@property (nonatomic, strong) HJDNSMap *dnsMap;
@property (nonatomic, strong) HJDNSDictionary *defaultDNSDict;
@property (nonatomic, strong) HJDNSDictionary *remoteDNSDict;
@end

@implementation HJDNSResolveManager {
    pthread_mutex_t _lock;
    dispatch_queue_t _queue;
}

- (void)dealloc {
    pthread_mutex_destroy(&_lock);
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _debug = NO;
        _ignoreNegative = NO;
        _negativeCount = 1;
        _autoFetchInterval = 1 * 60 * 60;
        pthread_mutex_init(&_lock, NULL);
        _queue = dispatch_queue_create("com.hj.dns.resolve", DISPATCH_QUEUE_SERIAL);
        
        [self fetchRecursively];
    }
    return self;
}

+ (instancetype)sharedManager {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

#pragma mark - Resolve Url

- (HJDNSNode *)resolveURL:(NSURL *)originalURL {
    if (originalURL == nil || originalURL.absoluteString.length == 0) {
        return nil;
    }
    
    NSString *urlKey = [self filterOutExtraHost:originalURL.absoluteString];
    NSString *extraHost = [self getExtraHost:originalURL.absoluteString];
    
    HJDNSNode *node = [HJDNSNode new];
    NSString *host = [NSURL URLWithString:urlKey].host;
    if(HJIsIPAddress(host)) {
        node.url = urlKey;
        if ([extraHost length] > 0) {
            node.host = extraHost;
        }
        return node;
    }
    
    NSString *mapKey = [self.class getUrlMapKeyWithPort:[NSURL URLWithString:urlKey]];
    NSString *mapValue;
    if (!HJIsIPAddress([NSURL URLWithString:mapKey].host)) {
        Lock();
        mapValue = [self.dnsMap getDNSValue:mapKey];
        Unlock();
    }
    
    node.host = [NSURL URLWithString:mapKey].host;
    if (mapValue.length != 0) {
        node.url = [originalURL.absoluteString stringByReplacingOccurrencesOfString:mapKey withString:mapValue];
    } else {
        node.url = originalURL.absoluteString;
    }
    
    if (self.debug) NSLog(@"HJ_DNS_Use_Get: MapKey = %@, MapValue = %@", mapKey, mapValue);
    
    return node;
}

- (void)setNegativeUrl:(NSString *)url host:(NSString *)host {
    [self markUrl:url host:host isNegative:YES];
}

- (void)setNegativeUrl:(NSString *)url key:(NSString *)key {
    [self markUrl:url key:key isNegative:YES];
}

- (void)setPositiveUrl:(NSString *)url host:(NSString *)host {
    [self markUrl:url host:host isNegative:NO];
}

- (void)setPositiveUrl:(NSString *)url key:(NSString *)key {
    [self markUrl:url key:key isNegative:NO];
}

- (void)markUrl:(NSString *)url host:(NSString *)host isNegative:(BOOL)isNegative  {
    if (!url || url.length <= 0 || !host || host.length <= 0 || _ignoreNegative) return;
    
    NSString *mapKey = [self.class getUrlMapKeyWithoutPort:[NSURL URLWithString:[url stringByReplacingOccurrencesOfString:[NSURL URLWithString:url].host withString:host]]];
    NSString *mapKey1 = [self.class getUrlMapKeyWithPort:[NSURL URLWithString:[url stringByReplacingOccurrencesOfString:[NSURL URLWithString:url].host withString:host]]];
    NSString *mapValue = [self.class getUrlMapKeyWithPort:[NSURL URLWithString:url]];
    if ([mapKey1 isEqualToString:mapValue]) { return; }
    
    Lock();
    if (isNegative) {
        if (self.debug) NSLog(@"HJ_DNS_Use_Set_Negative: MapKey = %@, MapValue = %@", mapKey1, mapValue);
        [self.dnsMap setNegativeDNSValue:mapValue key:mapKey];
        if (![mapKey isEqualToString:mapKey1]) {
            [self.dnsMap setNegativeDNSValue:mapValue key:mapKey1];
        }
    } else {
        if (self.debug) NSLog(@"HJ_DNS_Use_Set_Positive: MapKey = %@, MapValue = %@", mapKey1, mapValue);
        [self.dnsMap setPositiveDNSValue:mapValue key:mapKey];
        if (![mapKey isEqualToString:mapKey1]) {
            [self.dnsMap setPositiveDNSValue:mapValue key:mapKey1];
        }
    }
    Unlock();
}

- (void)markUrl:(NSString *)url key:(NSString *)key isNegative:(BOOL)isNegative  {
    if (!url || url.length <= 0 || !key || key.length <= 0 || _ignoreNegative) return;
    
    NSURL *mapURL = [NSURL URLWithString:url];
    NSString *mapValue = [self.class getUrlMapKeyWithPort:mapURL];
    
    NSURL *keyURL = [NSURL URLWithString:key];
    NSString *keyScheme = keyURL.scheme;
    NSString *keyHost = keyURL.host;
    NSString *keyPort = keyURL.port.stringValue;
    
    if (!keyHost || keyHost.length <= 0) return;
    
    NSString *mapKeyWithSchemeHostPort = nil;
    NSString *mapKeyWithSchemeHost = nil;
    NSString *mapKeyWithHostPort = nil;
    if (keyScheme && keyScheme.length && keyPort && keyPort.length) {
        mapKeyWithSchemeHostPort = key;
    } else if (keyScheme && keyScheme.length) {
        mapKeyWithSchemeHost = key;
        if (mapURL.port && mapURL.port.intValue > 0) {
            mapKeyWithSchemeHostPort = [NSString stringWithFormat:@"%@:%@", mapKeyWithSchemeHost, mapURL.port.stringValue];
        }
    } else if (keyPort && keyPort.length) {
        mapKeyWithHostPort = key;
        if (mapURL.scheme && mapURL.scheme.length > 0) {
            mapKeyWithSchemeHostPort = [NSString stringWithFormat:@"%@://%@", mapURL.scheme, mapKeyWithHostPort];
        }
    }
    
    if (mapKeyWithSchemeHostPort && ![mapKeyWithSchemeHostPort isEqualToString:url]) {
        Lock();
        if (isNegative) {
            if (self.debug) NSLog(@"HJ_DNS_Use_Set_Negative: MapKey = %@, MapValue = %@", mapKeyWithSchemeHostPort, mapValue);
            [self.dnsMap setNegativeDNSValue:mapValue key:mapKeyWithSchemeHostPort];
        } else {
            if (self.debug) NSLog(@"HJ_DNS_Use_Set_Positive: MapKey = %@, MapValue = %@", mapKeyWithSchemeHostPort, mapValue);
            [self.dnsMap setPositiveDNSValue:mapValue key:mapKeyWithSchemeHostPort];
        }
        Unlock();
    }
    
    if (mapKeyWithSchemeHost && ![mapKeyWithSchemeHost isEqualToString:url]) {
        Lock();
        if (isNegative) {
            if (self.debug) NSLog(@"HJ_DNS_Use_Set_Negative: MapKey = %@, MapValue = %@", mapKeyWithSchemeHost, mapValue);
            [self.dnsMap setNegativeDNSValue:mapValue key:mapKeyWithSchemeHost];
        } else {
            if (self.debug) NSLog(@"HJ_DNS_Use_Set_Positive: MapKey = %@, MapValue = %@", mapKeyWithSchemeHost, mapValue);
            [self.dnsMap setPositiveDNSValue:mapValue key:mapKeyWithSchemeHost];
        }
        Unlock();
    }
    
    if (mapKeyWithHostPort && ![mapKeyWithHostPort isEqualToString:url]) {
        Lock();
        if (isNegative) {
            if (self.debug) NSLog(@"HJ_DNS_Use_Set_Negative: MapKey = %@, MapValue = %@", mapKeyWithHostPort, mapValue);
            [self.dnsMap setNegativeDNSValue:mapValue key:mapKeyWithHostPort];
        } else {
            if (self.debug) NSLog(@"HJ_DNS_Use_Set_Positive: MapKey = %@, MapValue = %@", mapKeyWithHostPort, mapValue);
            [self.dnsMap setPositiveDNSValue:mapValue key:mapKeyWithHostPort];
        }
        Unlock();
    }
}

#pragma mark - Default Map

- (void)setDefaultDNS:(HJDNSDictionary *)dict {
    if (dict == nil || !dict.count) {
        [self fetchRemoteDNS];
        return;
    }
    
    Lock();
    self.defaultDNSDict = [[NSDictionary alloc] initWithDictionary:dict];
    Unlock();
    
    [self composeDNSMap];
    [self fetchRemoteDNS];
}

#pragma mark - Fetch Server Map

- (void)fetchRemoteDNS {
    __weak typeof(self) weakSelf = self;
    dispatch_async(_queue, ^{
        if (self.dnsRemoteDictBlock) {
            HJDNSDictBlock dnsDict = ^(HJDNSDictionary *dict) {
                Lock();
                weakSelf.remoteDNSDict = [[NSDictionary alloc] initWithDictionary:dict];
                Unlock();
                [self composeDNSMap];
            };
            self.dnsRemoteDictBlock(self.dnsRemoteUrl, dnsDict);
        }
    });
}

- (void)composeDNSMap {
    Lock();
    NSMutableDictionary *dict = [NSMutableDictionary new];
    if (self.defaultDNSDict) {
        [dict addEntriesFromDictionary:self.defaultDNSDict];
    }
    if (self.remoteDNSDict) {
        [dict addEntriesFromDictionary:self.remoteDNSDict];
    }
    self.dnsMap = [[HJDNSMap alloc] initWithDict:dict negativeCount:_negativeCount];
    Unlock();
    
    if (self.debug) NSLog(@"HJ_DNS_Map = %@", self.dnsMap);
}

#pragma mark - Private

- (void)fetchRecursively {
    __weak typeof(self) _self = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_autoFetchInterval * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        __strong typeof(_self) self = _self;
        if (!self) return;
        [self fetchRemoteDNS];
        [self fetchRecursively];
    });
}

/// return: scheme://host
+ (NSString *)getUrlMapKeyWithoutPort:(NSURL *)url {
    NSString *urlKey = [NSString stringWithFormat:@"%@://%@", url.scheme, url.host];
    return urlKey;
}

/// return: scheme://host:port
+ (NSString *)getUrlMapKeyWithPort:(NSURL *)url {
    NSString *port = @"";
    if (url.port != nil) {
        port = [NSString stringWithFormat:@":%d", url.port.intValue];
    }
    NSString *urlKey = [NSString stringWithFormat:@"%@://%@%@", url.scheme, url.host, port];
    
    return urlKey;
}

/* https://xyz.com@abc.com -> https://abc.com */
/* Return url without exra host */
- (NSString *)filterOutExtraHost:(NSString *)urlKey {
    NSRange startFound = [urlKey rangeOfString:@"://"];
    if (startFound.location == NSNotFound) {
        // no protocol beginning
        NSString *host = nil;
        NSRange hostEnd = [urlKey rangeOfString:@"/"];
        if (hostEnd.location == NSNotFound) {
            host = urlKey;
        } else {
            // contains "/"
            host = [urlKey substringToIndex:hostEnd.location];
        }
        NSRange atFound = [host rangeOfString:@"@"];
        if (atFound.location == NSNotFound) {
            return urlKey; // not changed
        }
        return [urlKey substringFromIndex:atFound.location + 1];
    }
    NSString *host = nil;
    NSRange hostEnd = [urlKey rangeOfString:@"/" options:NSCaseInsensitiveSearch range:NSMakeRange(startFound.location + 3, urlKey.length - (startFound.location + 3))];
    if (hostEnd.location == NSNotFound) {
        host = [urlKey substringFromIndex:startFound.location + 3];
    } else {
        // contains "/"
        host = [urlKey substringWithRange:NSMakeRange(startFound.location + 3, hostEnd.location - (startFound.location + 3) - 1)];
    }
    NSRange atFound = [host rangeOfString:@"@"];
    if (atFound.location == NSNotFound) {
        return urlKey; // not changed
    }
    if (hostEnd.location == NSNotFound) {
        return [NSString stringWithFormat:@"%@%@", [urlKey substringToIndex:startFound.location + 3], [host substringFromIndex:atFound.location + 1]];
    } else {
        return [NSString stringWithFormat:@"%@%@%@", [urlKey substringToIndex:startFound.location + 3], [host substringFromIndex:atFound.location + 1], [urlKey substringFromIndex:hostEnd.location]];
    }
}

/* https://xyz.com@abc.com -> xyz.com */
/* Return extra host from url */
- (NSString *)getExtraHost:(NSString *)urlKey {
    NSString *host = nil;
    NSRange startFound = [urlKey rangeOfString:@"://"];
    if (startFound.location == NSNotFound) {
        // no protocol beginning
        NSRange hostEnd = [urlKey rangeOfString:@"/"];
        if (hostEnd.location == NSNotFound) {
            host = urlKey;
        } else {
            // contains "/"
            host = [urlKey substringToIndex:hostEnd.location];
        }
    } else {
        NSRange hostEnd = [urlKey rangeOfString:@"/" options:NSCaseInsensitiveSearch range:NSMakeRange(startFound.location + 3, urlKey.length - (startFound.location + 3))];
        if (hostEnd.location == NSNotFound) {
            host = [urlKey substringFromIndex:startFound.location + 3];
        } else {
            // contains "/"
            host = [urlKey substringWithRange:NSMakeRange(startFound.location + 3, hostEnd.location - (startFound.location + 3) - 1)];
        }
    }
    NSRange atFound = [host rangeOfString:@"@"];
    if (atFound.location == NSNotFound) {
        return nil; // no extra host
    }
    return [host substringToIndex:atFound.location];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p>\n%@", self.class, self, self.dnsMap];
}

@end
