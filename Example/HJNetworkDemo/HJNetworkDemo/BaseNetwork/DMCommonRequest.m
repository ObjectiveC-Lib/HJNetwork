//
//  DMCommonRequest.m
//  HJNetworkDemo
//
//  Created by navy on 2023/1/4.
//

#import "DMCommonRequest.h"

@implementation DMCommonRequest {
    NSString *_requestUrl;
    id _requestArgument;
    NSDictionary *_headerField;
    HJRequestMethod _requestMethod;
    HJRequestSerializerType _requestSerializerType;
    HJResponseSerializerType _responseSerializerType;
}

- (instancetype)initWithUrl:(NSString *)requestUrl
            requestArgument:(id)requestArgument
                headerField:(NSDictionary *)headerField
              requestMethod:(HJRequestMethod)requestMethod
      requestSerializerType:(HJRequestSerializerType)requestSerializerType
     responseSerializerType:(HJResponseSerializerType)responseSerializerType {
    self = [super init];
    if (self) {
        _requestUrl = requestUrl;
        _requestMethod = requestMethod;
        _requestSerializerType = requestSerializerType;
        _responseSerializerType = responseSerializerType;
    }
    return self;
}

- (HJRequestMethod)requestMethod {
    return _requestMethod;
}

- (HJRequestSerializerType)requestSerializerType {
    return _requestSerializerType;
}

- (HJResponseSerializerType)responseSerializerType {
    return _responseSerializerType;
}

- (NSString *)requestUrl {
    return _requestUrl;
}

- (nullable id)requestArgument {
    return _requestArgument;
}

- (NSDictionary *)requestHeaderFieldValueDictionary {
    NSMutableDictionary *tmpDict = [NSMutableDictionary new];
    NSDictionary *dict = [super requestHeaderFieldValueDictionary];
    if (dict && dict.count) {
        [tmpDict addEntriesFromDictionary:dict];
    }
    if (_headerField && _headerField.count) {
        [tmpDict addEntriesFromDictionary:_headerField];
    }
    return tmpDict.copy;
}

@end
