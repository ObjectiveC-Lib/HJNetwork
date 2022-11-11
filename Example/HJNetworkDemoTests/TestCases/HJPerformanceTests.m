//
//  HJPerformanceTests.m
//  HJNetwork
//
//  Created by navy on 18/8/3.
//  Copyright © 2018 HJNetwork. All rights reserved.
//

#import "HJTestCase.h"
#import "HJBasicHTTPRequest.h"

@interface HJPerformanceTests : HJTestCase

@end

@implementation HJPerformanceTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testBaseRequestCreationPerformance {
    NSInteger targetCount = 1000;
    // The measure block will be called several times.
    [self measureBlock:^{
        for (NSUInteger i = 0; i < targetCount; i++) {
            @autoreleasepool {
                HJBasicHTTPRequest *req = [[HJBasicHTTPRequest alloc] init];
                [req startWithCompletionBlockWithSuccess:^(__kindof HJCoreRequest * _Nonnull request) {
                    NSNumber *result = request.responseObject;
                    XCTAssertTrue([result isEqualToNumber:@(i)]);
                } failure:nil];
                [req.requestTask cancel];
            }
        }
    }];
}

@end
