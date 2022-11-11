//
//  HJTestCase.h
//  HJNetwork
//
//  Created by navy on 18/8/2.
//  Copyright © 2018 HJNetwork. All rights reserved.
//

#import <XCTest/XCTest.h>

@class HJCoreRequest, HJBaseRequest;

@interface HJTestCase : XCTestCase

@property (nonatomic, assign) NSTimeInterval networkTimeout;

- (void)expectSuccess:(HJBaseRequest *)request;
- (void)expectSuccess:(HJBaseRequest *)request withAssertion:(void(^)(HJCoreRequest * request)) assertion;
- (void)expectFailure:(HJBaseRequest *)request;
- (void)expectFailure:(HJBaseRequest *)request withAssertion:(void(^)(HJCoreRequest * request)) assertion;

- (void)waitForExpectationsWithCommonTimeout;
- (void)waitForExpectationsWithCommonTimeoutUsingHandler:(XCWaitCompletionHandler)handler;

- (void)createDirectory:(NSString *)path;
- (void)clearDirectory:(NSString *)path;

@end
