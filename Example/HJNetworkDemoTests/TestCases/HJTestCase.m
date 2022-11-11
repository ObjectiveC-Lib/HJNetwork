//
//  HJTestCase.m
//  HJNetwork
//
//  Created by navy on 18/8/2.
//  Copyright © 2018 HJNetwork. All rights reserved.
//

#import "HJTestCase.h"
#import "HJNetworkConfig.h"
#import "HJNetworkAgent.h"
#import "HJBaseRequest.h"

NSString * const HJNetworkingTestsBaseURLString = @"https://httpbin.org/";

@implementation HJTestCase

- (void)setUp {
    [super setUp];
    
    self.networkTimeout = 20.0;
    [HJNetworkConfig sharedConfig].baseUrl = HJNetworkingTestsBaseURLString;
}

- (void)tearDown {
    [super tearDown];
    
    [[HJNetworkAgent sharedAgent] cancelAllRequests];
    [HJNetworkConfig sharedConfig].baseUrl = @"";
    [HJNetworkConfig sharedConfig].cdnUrl = @"";
    [[HJNetworkConfig sharedConfig] clearUrlFilter];
}

- (void)expectSuccess:(HJBaseRequest *)request {
    [self expectSuccess:request withAssertion:nil];
}

- (void)expectSuccess:(HJBaseRequest *)request withAssertion:(void(^)(HJCoreRequest * request)) assertion {
    XCTestExpectation *exp = [self expectationWithDescription:@"Request should succeed"];
    
    [request startWithCompletionBlockWithSuccess:^(__kindof HJCoreRequest * _Nonnull request) {
        XCTAssertNotNil(request);
        XCTAssertNil(request.error);
        if (assertion) {
            assertion(request);
        }
        [exp fulfill];
    } failure:^(__kindof HJCoreRequest * _Nonnull request) {
        XCTFail(@"Request should succeed, but failed");
        [exp fulfill];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)expectFailure:(HJBaseRequest *)request {
    [self expectFailure:request withAssertion:nil];
}

- (void)expectFailure:(HJBaseRequest *)request withAssertion:(void(^)(HJCoreRequest * request)) assertion {
    XCTestExpectation *exp = [self expectationWithDescription:@"Request should fail"];
    
    [request startWithCompletionBlockWithSuccess:^(__kindof HJCoreRequest * _Nonnull request) {
        XCTFail(@"Request should fail, but succeeded");
        [exp fulfill];
    } failure:^(__kindof HJCoreRequest * _Nonnull request) {
        XCTAssertNotNil(request);
        XCTAssertNotNil(request.error);
        if (assertion) {
            assertion(request);
        }
        [exp fulfill];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)waitForExpectationsWithCommonTimeout {
    [self waitForExpectationsWithCommonTimeoutUsingHandler:^(NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"Error: %@", error.localizedDescription);
        }
    }];
}

- (void)waitForExpectationsWithCommonTimeoutUsingHandler:(XCWaitCompletionHandler)handler {
    [self waitForExpectationsWithTimeout:self.networkTimeout handler:handler];
}

#pragma mark -

- (void)createDirectory:(NSString *)path {
    NSError *error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:path
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:&error];
    if (error) {
        NSLog(@"Create directory error: %@", error);
    }
}

- (void)clearDirectory:(NSString *)path {
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    if (![fileManager fileExistsAtPath:path isDirectory:nil]) {
        return;
    }
    
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtPath:path];
    NSError *err = nil;
    BOOL res;
    
    NSString *file;
    while (file = [enumerator nextObject]) {
        res = [fileManager removeItemAtPath:[path stringByAppendingPathComponent:file] error:&err];
        if (!res && err) {
            NSLog(@"Delete file error: %@", err);
        }
    }
}

@end
