//
//  HJJSONValidatorTests.m
//  HJNetworkDemo
//
//  Created by navy on 18/8/3.
//  Copyright © 2018 HJNetwork. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "HJNetworkPrivate.h"

@interface HJJSONValidatorTests : XCTestCase

@end

@implementation HJJSONValidatorTests

- (void)testCompoundDictionaryVailidateShouldSucceed {
    NSDictionary *json = @{
        @"son": @{
            @"age": @14,
        },
        @"name": @"family"
    };
    
    NSDictionary *validator = @{
        @"son": [NSDictionary class],
        @"name": [NSString class]
    };
    
    BOOL result = [self validateJSON:json withValidator:validator];
    XCTAssertTrue(result);
}

- (void)testCompoundDictionaryVailidateShouldFail {
    NSDictionary *json = @{
        @"son": @{
            @"age": @14,
        },
        @"name": @"family"
    };
    NSDictionary *validator = @{
        @"son": [NSDictionary class],
        @"name": [NSNumber class]
    };
    BOOL result = [self validateJSON:json withValidator:validator];
    XCTAssertFalse(result);
}

- (void)testSimpleArrayValidatorShouldSucceed {
    NSArray *json = @[@1 , @2];
    NSArray *validator = @[[NSNumber class]];
    BOOL result = [self validateJSON:json withValidator:validator];
    XCTAssertTrue(result);
}

- (void)testSimpleArrayValidatorShouldFail {
    NSArray *json = @[@1 , @2];
    NSArray *validator = @[[NSString class]];
    BOOL result = [self validateJSON:json withValidator:validator];
    XCTAssertFalse(result);
}

- (void)testEmptyArrayValidatorShouldSucceed {
    NSArray *json = @[@{
        @"values": @[]
    }];
    NSArray *validator = @[@{
        @"values": @[]
    }];
    BOOL result = [self validateJSON:json withValidator:validator];
    XCTAssertTrue(result);
}

- (BOOL)validateJSON:(id)json withValidator:(id)validator {
    return [HJNetworkUtils validateJSON:json withValidator:validator];
}

@end
