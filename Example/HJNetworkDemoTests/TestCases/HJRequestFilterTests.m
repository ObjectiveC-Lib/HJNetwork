//
//  HJRequestFilterTests.m
//  HJNetwork
//
//  Created by navy on 18/8/2.
//  Copyright © 2018 HJNetwork. All rights reserved.
//

#import "HJTestCase.h"
#import "HJNetwork.h"
#import "HJBasicUrlFilter.h"
#import "HJBasicHTTPRequest.h"

@interface HJRequestFilterTests : HJTestCase

@end

@implementation HJRequestFilterTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testBasicFilter {
    HJBasicUrlFilter *filter = [HJBasicUrlFilter filterWithArguments:@{@"key": @"value"}];
    [[HJNetworkConfig sharedConfig] addUrlFilter:filter];
    
    HJBasicHTTPRequest *req = [[HJBasicHTTPRequest alloc] initWithRequestUrl:@"get"];
    [self expectSuccess:req withAssertion:^(HJBaseRequest *request) {
        NSDictionary<NSString *, NSString *> *args = request.responseJSONObject[@"args"];
        XCTAssertTrue([args[@"key"] isEqualToString:@"value"]);
    }];
}

@end
