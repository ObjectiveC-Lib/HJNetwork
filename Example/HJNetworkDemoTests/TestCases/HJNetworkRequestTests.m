//
//  HJNetworkDemoTests.m
//  HJNetworkDemoTests
//
//  Created by navy on 18/8/3.
//  Copyright © 2018 HJNetwork. All rights reserved.
//

#import "HJTestCase.h"
#import "HJNetworkConfig.h"
#import "HJNetworkAgent.h"
#import "HJBasicHTTPRequest.h"
#import "HJXMLRequest.h"
#import "HJBasicAuthRequest.h"
#import "HJCustomHeaderFieldRequest.h"
#import "HJJSONValidatorRequest.h"
#import "HJStatusCodeValidatorRequest.h"
#import "HJTImeoutRequest.h"

@interface HJNetworkRequestTests : HJTestCase

@end

@implementation HJNetworkRequestTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)_testBuildRequestURLWithBaseURL:(NSString *)baseURL detailURL:(NSString *)detailURL resultURL:(NSString *)resultURL {
    HJNetworkConfig *config = [HJNetworkConfig sharedConfig];
    HJNetworkAgent *agent = [HJNetworkAgent sharedAgent];
    
    config.baseUrl = baseURL;
    
    HJBasicHTTPRequest *request = [[HJBasicHTTPRequest alloc] initWithRequestUrl:detailURL];
    NSString *url = [agent buildRequestUrl:request];
    
    XCTAssertTrue([url isEqualToString:resultURL]);
}

- (void)testBuildRequestURL {
    [self _testBuildRequestURLWithBaseURL:@"http://www.example.com" detailURL:@"get" resultURL:@"http://www.example.com/get"];
    [self _testBuildRequestURLWithBaseURL:@"http://www.example.com/" detailURL:@"get" resultURL:@"http://www.example.com/get"];
    [self _testBuildRequestURLWithBaseURL:@"https://www.example.com" detailURL:@"get" resultURL:@"https://www.example.com/get"];
    [self _testBuildRequestURLWithBaseURL:@"http://www.example.com" detailURL:@"get/val" resultURL:@"http://www.example.com/get/val"];
    [self _testBuildRequestURLWithBaseURL:@"http://www.example.com" detailURL:@"get/val/" resultURL:@"http://www.example.com/get/val/"];
    [self _testBuildRequestURLWithBaseURL:@"https://www.example.com" detailURL:@"httpEndpoint" resultURL:@"https://www.example.com/httpEndpoint"];
    
    [self _testBuildRequestURLWithBaseURL:@"" detailURL:@"http://www.example.com" resultURL:@"http://www.example.com"];
    [self _testBuildRequestURLWithBaseURL:@"" detailURL:@"https://www.example.com" resultURL:@"https://www.example.com"];
    [self _testBuildRequestURLWithBaseURL:@"http://www.something.com" detailURL:@"https://www.example.com" resultURL:@"https://www.example.com"];
}

- (void)testBasicHTTPRequest {
    HJBasicHTTPRequest *get = [[HJBasicHTTPRequest alloc] initWithRequestUrl:@"get" method:HJRequestMethodGET];
    [self expectSuccess:get];
    
    HJBasicHTTPRequest *post = [[HJBasicHTTPRequest alloc] initWithRequestUrl:@"post" method:HJRequestMethodPOST];
    [self expectSuccess:post];
    
    HJBasicHTTPRequest *patch = [[HJBasicHTTPRequest alloc] initWithRequestUrl:@"patch" method:HJRequestMethodPATCH];
    [self expectSuccess:patch];
    
    HJBasicHTTPRequest *put = [[HJBasicHTTPRequest alloc] initWithRequestUrl:@"put" method:HJRequestMethodPUT];
    [self expectSuccess:put];
    
    HJBasicHTTPRequest *delete = [[HJBasicHTTPRequest alloc] initWithRequestUrl:@"delete" method:HJRequestMethodDELETE];
    [self expectSuccess:delete];
    
    HJBasicHTTPRequest *fail404 = [[HJBasicHTTPRequest alloc] initWithRequestUrl:@"status/404" method:HJRequestMethodGET];
    [self expectFailure:fail404];
}

- (void)testResponseHeaders {
    HJBasicHTTPRequest *req = [[HJBasicHTTPRequest alloc] initWithRequestUrl:@"response-headers?key=value"];
    [self expectSuccess:req withAssertion:^(HJBaseRequest *request) {
        NSDictionary<NSString *, NSString *> *responseHeaders = request.responseHeaders;
        XCTAssertNotNil(responseHeaders);
        XCTAssertTrue([responseHeaders[@"key"] isEqualToString:@"value"]);
    }];
}

- (void)testCustomHeaderField {
    HJCustomHeaderFieldRequest *req = [[HJCustomHeaderFieldRequest alloc] initWithCustomHeaderField:@{@"Custom-Header-Field": @"CustomHeaderValue"} requestUrl:@"headers"];
    [self expectSuccess:req withAssertion:^(HJBaseRequest *request) {
        XCTAssertNotNil(request.responseJSONObject);
        NSDictionary<NSString *, NSString *> *headers = request.responseJSONObject[@"headers"];
        XCTAssertTrue([headers[@"Custom-Header-Field"] isEqualToString:@"CustomHeaderValue"]);
    }];
}

- (void)testHTTPBasicAuthRequest {
    HJBasicAuthRequest *authSuccess = [[HJBasicAuthRequest alloc] initWithUsername:@"123" password:@"123" requestUrl:@"basic-auth/123/123"];
    [self expectSuccess:authSuccess];
    
    HJBasicAuthRequest *authFailure = [[HJBasicAuthRequest alloc] initWithUsername:@"123456" password:@"123" requestUrl:@"basic-auth/123/123"];
    [self expectFailure:authFailure];
}

- (void)testJSONValidator {
    HJJSONValidatorRequest *validateSuccess = [[HJJSONValidatorRequest alloc] initWithJSONValidator:@{@"headers": [NSDictionary class], @"args": [NSDictionary class]} requestUrl:@"get?key1=value&key2=123456"];
    [self expectSuccess:validateSuccess];
    
    HJJSONValidatorRequest *validateFailure = [[HJJSONValidatorRequest alloc] initWithJSONValidator:@{@"headers": [NSDictionary class], @"args": [NSString class]} requestUrl:@"get?key1=value&key2=123456"];
    [self expectFailure:validateFailure withAssertion:^(HJBaseRequest *request) {
        NSError *error = request.error;
        XCTAssertTrue([error.domain isEqualToString:HJRequestValidationErrorDomain]);
        XCTAssertTrue(error.code == HJRequestValidationErrorInvalidJSONFormat);
    }];
}

- (void)testXMLRequest {
    HJXMLRequest *req = [[HJXMLRequest alloc] initWithRequestUrl:@"xml"];
    [self expectSuccess:req withAssertion:^(HJBaseRequest *request) {
        XCTAssertNotNil(request);
        XCTAssertTrue([request.responseObject isMemberOfClass:[NSXMLParser class]]);
    }];
    
    HJXMLRequest *req2 = [[HJXMLRequest alloc] initWithRequestUrl:@"get"];
    [self expectFailure:req2];
}

- (void)testStatusCodeValidator {
    HJStatusCodeValidatorRequest *validateSuccess = [[HJStatusCodeValidatorRequest alloc] initWithRequestUrl:@"status/418"];
    [self expectSuccess:validateSuccess];
    
    HJStatusCodeValidatorRequest *validateFailure = [[HJStatusCodeValidatorRequest alloc] initWithRequestUrl:@"status/200"];
    [self expectFailure:validateFailure withAssertion:^(HJBaseRequest *request) {
        NSError *error = request.error;
        XCTAssertTrue([error.domain isEqualToString:HJRequestValidationErrorDomain]);
        XCTAssertTrue(error.code == HJRequestValidationErrorInvalidStatusCode);
    }];
}

- (void)testBatchRequest {
    HJBasicHTTPRequest *req1 = [[HJBasicHTTPRequest alloc] initWithRequestUrl:@"get?key1=value1"];
    HJBasicHTTPRequest *req2 = [[HJBasicHTTPRequest alloc] initWithRequestUrl:@"get?key2=value2"];
    HJBasicHTTPRequest *req3 = [[HJBasicHTTPRequest alloc] initWithRequestUrl:@"get?key3=value3"];
    
    XCTestExpectation *exp = [self expectationWithDescription:@"Batch Request should succeed"];
    
    HJBatchRequest *batch = [[HJBatchRequest alloc] initWithRequestArray:@[req1, req2, req3]];
    [batch startWithCompletionBlockWithSuccess:^(HJBatchRequest * _Nonnull batchRequest) {
        XCTAssertNotNil(batchRequest);
        XCTAssertEqual(batchRequest.requestArray.count, 3);
        
        HJRequest *req1 = batchRequest.requestArray[0];
        NSDictionary<NSString *, NSString *> *responseArgs1 = req1.responseJSONObject[@"args"];
        XCTAssertTrue([responseArgs1[@"key1"] isEqualToString:@"value1"]);
        XCTAssertNil(req1.successCompletionBlock);
        XCTAssertNil(req1.failureCompletionBlock);
        
        HJRequest *req2 = batchRequest.requestArray[1];
        NSDictionary<NSString *, NSString *> *responseArgs2 = req2.responseJSONObject[@"args"];
        XCTAssertTrue([responseArgs2[@"key2"] isEqualToString:@"value2"]);
        XCTAssertNil(req2.successCompletionBlock);
        XCTAssertNil(req2.failureCompletionBlock);
        
        HJRequest *req3 = batchRequest.requestArray[2];
        NSDictionary<NSString *, NSString *> *responseArgs3 = req3.responseJSONObject[@"args"];
        XCTAssertTrue([responseArgs3[@"key3"] isEqualToString:@"value3"]);
        XCTAssertNil(req3.successCompletionBlock);
        XCTAssertNil(req3.failureCompletionBlock);
        
        [exp fulfill];
    } failure:^(HJBatchRequest * _Nonnull batchRequest) {
        XCTFail(@"Batch Request should succeed, but failed");
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testChainRequest {
    HJBasicHTTPRequest *req1 = [[HJBasicHTTPRequest alloc] initWithRequestUrl:@"get?key1=value1"];
    HJBasicHTTPRequest *req2 = [[HJBasicHTTPRequest alloc] initWithRequestUrl:@"get?key2=value2"];
    HJBasicHTTPRequest *req3 = [[HJBasicHTTPRequest alloc] initWithRequestUrl:@"get?key3=value3"];
    
    XCTestExpectation *exp = [self expectationWithDescription:@"Chain Request should succeed"];
    
    HJChainRequest *chain = [[HJChainRequest alloc] init];
    [chain addRequest:req1 callback:^(HJChainRequest * _Nonnull chainRequest, HJBaseRequest * _Nonnull baseRequest) {
        NSDictionary<NSString *, NSString *> *responseArgs1 = baseRequest.responseJSONObject[@"args"];
        XCTAssertTrue([responseArgs1[@"key1"] isEqualToString:@"value1"]);
        XCTAssertNil(baseRequest.successCompletionBlock);
        XCTAssertNil(baseRequest.failureCompletionBlock);
        
        [chainRequest addRequest:req2 callback:^(HJChainRequest * _Nonnull chainRequest, HJBaseRequest * _Nonnull baseRequest) {
            NSDictionary<NSString *, NSString *> *responseArgs2 = baseRequest.responseJSONObject[@"args"];
            XCTAssertTrue([responseArgs2[@"key2"] isEqualToString:@"value2"]);
            XCTAssertNil(baseRequest.successCompletionBlock);
            XCTAssertNil(baseRequest.failureCompletionBlock);
            
            [chainRequest addRequest:req3 callback:^(HJChainRequest * _Nonnull chainRequest, HJBaseRequest * _Nonnull baseRequest) {
                NSDictionary<NSString *, NSString *> *responseArgs3 = baseRequest.responseJSONObject[@"args"];
                XCTAssertTrue([responseArgs3[@"key3"] isEqualToString:@"value3"]);
                XCTAssertNil(baseRequest.successCompletionBlock);
                XCTAssertNil(baseRequest.failureCompletionBlock);
                
                [exp fulfill];
            }];
        }];
    }];
    [chain start];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testTimeoutRequest {
    HJTimeoutRequest *timeoutSuccess = [[HJTimeoutRequest alloc] initWithTimeout:5 requestUrl:@"delay/3"];
    [self expectSuccess:timeoutSuccess];
    
    HJTimeoutRequest *timeoutFailure = [[HJTimeoutRequest alloc] initWithTimeout:5 requestUrl:@"delay/7"];
    [self expectFailure:timeoutFailure];
}

@end
