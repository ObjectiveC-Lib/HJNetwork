//
//  DMBaseUrlFilter.m
//  HJNetworkDemo
//
//  Created by navy on 2020/12/25.
//

#import "DMBaseUrlFilter.h"
#import "DMInlineHeader.h"

@interface DMBaseUrlFilter ()
@property (nonatomic, strong) NSDictionary *arguments;
@end

@implementation DMBaseUrlFilter

+ (NSString *)baseUrl {
    return @"https://httpbin.org/";
}

+ (instancetype)filterWithArguments:(NSDictionary *)arguments {
    return [[self alloc] initWithArguments:arguments];
}

- (instancetype)initWithArguments:(NSDictionary *)arguments {
    self = [super init];
    if (self) {
        _arguments = arguments;
    }
    return self;
}

#pragma mark - HJUrlFilterProtocol

- (NSString *)filterUrl:(NSString *)originUrl withRequest:(HJCoreRequest *)request {
    return [self appendParameters:_arguments originUrl:originUrl request:request];
}

- (NSString *)appendParameters:(NSDictionary *)parameters
                     originUrl:(NSString *)originUrl
                       request:(HJCoreRequest *)request {
    NSURL *tempUrl = [NSURL URLWithString:originUrl?:@""];
    NSString *queryString = DMSafeNSString(tempUrl.query);
    NSString *baseUrl = DMSafeNSString(originUrl);
    if (DMNSStringAvailable(queryString)) {
        baseUrl = DMSafeNSString([[tempUrl.absoluteString componentsSeparatedByString:@"?"] objectAtIndex:0]);
    }
    
    NSMutableDictionary *args = @{}.mutableCopy;
    NSDictionary *queryDict;
    if (DMNSStringAvailable(queryString)) {
        NSArray *queryArray = [queryString componentsSeparatedByString:@"&"];
        NSMutableArray *keys = @[].mutableCopy;
        NSMutableArray *values = @[].mutableCopy;
        for (NSString *obj in queryArray) {
            NSArray *objs = [obj componentsSeparatedByString:@"="];
            [keys addObject:[objs objectAtIndex:0]];
            [values addObject:[objs objectAtIndex:1]?:@""];
        }
        queryDict = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    }
    
    if (DMNSDictionaryAvailable(queryDict)) {
        [args addEntriesFromDictionary:queryDict];
    }
    
    if (DMNSDictionaryAvailable(parameters)) {
        [args addEntriesFromDictionary:parameters];
    }
    
    NSDictionary *dictArgument = request.requestArgument;
    if (DMNSDictionaryAvailable(dictArgument)) {
        [args addEntriesFromDictionary:dictArgument];
    }
    
    if (DMNSStringAvailable(baseUrl) && DMNSDictionaryAvailable(args)) {
        return [NSString stringWithFormat:@"%@?%@", baseUrl, AFQueryStringFromParameters(args)];
    } else if (DMNSStringAvailable(queryString) || (DMNSStringAvailable(originUrl) && DMNSDictionaryAvailable(args))) {
        return [NSString stringWithFormat:@"?%@", AFQueryStringFromParameters(args)];
    }
    
    return originUrl;
}

@end
