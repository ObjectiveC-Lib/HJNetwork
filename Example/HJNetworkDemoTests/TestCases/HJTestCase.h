//
//  HJTestCase.h
//  HJNetwork
//
//  Created by navy on 18/8/2.
//  Copyright © 2018 HJNetwork. All rights reserved.
//

#import <XCTest/XCTest.h>

@class HJBaseRequest, HJRequest;

@interface HJTestCase : XCTestCase

@property (nonatomic, assign) NSTimeInterval networkTimeout;

- (void)expectSuccess:(HJRequest *)request;
- (void)expectSuccess:(HJRequest *)request withAssertion:(void(^)(HJBaseRequest * request)) assertion;
- (void)expectFailure:(HJRequest *)request;
- (void)expectFailure:(HJRequest *)request withAssertion:(void(^)(HJBaseRequest * request)) assertion;

- (void)waitForExpectationsWithCommonTimeout;
- (void)waitForExpectationsWithCommonTimeoutUsingHandler:(XCWaitCompletionHandler)handler;

- (void)createDirectory:(NSString *)path;
- (void)clearDirectory:(NSString *)path;

@end
