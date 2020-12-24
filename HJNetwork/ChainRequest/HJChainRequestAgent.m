//
//  HJChainRequestAgent.m
//  HJNetwork
//
//  Created by navy on 2018/7/5.
//  Copyright © 2018 HJNetwork. All rights reserved.
//

#import "HJChainRequestAgent.h"
#import "HJChainRequest.h"

@interface HJChainRequestAgent()
@property (strong, nonatomic) NSMutableArray<HJChainRequest *> *requestArray;
@end

@implementation HJChainRequestAgent

+ (HJChainRequestAgent *)sharedAgent {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _requestArray = [NSMutableArray array];
    }
    return self;
}

- (void)addChainRequest:(HJChainRequest *)request {
    @synchronized(self) {
        [_requestArray addObject:request];
    }
}

- (void)removeChainRequest:(HJChainRequest *)request {
    @synchronized(self) {
        [_requestArray removeObject:request];
    }
}

@end
