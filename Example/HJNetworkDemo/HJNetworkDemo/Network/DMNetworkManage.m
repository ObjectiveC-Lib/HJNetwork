//
//  DMNetworkManage.m
//  HJNetworkDemo
//
//  Created by navy on 2020/12/25.
//

#import "DMNetworkManage.h"
#import "DMInlineHeader.h"

@implementation DMNetworkManage {
    NSDictionary *_arguments;
}

+ (NSString *)serverHost {
    return @"http://www.dummy.com";
}

+ (DMNetworkManage *)urlFilter {
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    
    return [self filterWithArguments:@{ @"appver":appVersion,
                                     }];
}

+ (DMNetworkManage *)filterWithArguments:(NSDictionary *)arguments {
    return [[self alloc] initWithArguments:arguments];
}

- (id)initWithArguments:(NSDictionary *)arguments {
    self = [super init];
    if (self) {
        _arguments = arguments;
    }
    return self;
}

- (NSString *)filterUrl:(NSString *)originUrl withRequest:(HJBaseRequest *)request {
    return [self urlStringWithOriginUrlString:originUrl
                             appendParameters:_arguments
                                  withRequest:request];
}

- (NSString *)urlStringWithOriginUrlString:(NSString *)originUrlString
                          appendParameters:(NSDictionary *)parameters
                               withRequest:(HJBaseRequest *)request {
    NSURL *tempUrl = [NSURL URLWithString:originUrlString?:@""];
    NSString *queryString = DMSafeNSString(tempUrl.query);
    NSString *baseUrl = DMSafeNSString(originUrlString);
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
    
    [args setObject:@"uid" forKey:@"login_uid"];
    
    if (DMNSStringAvailable(baseUrl) && DMNSDictionaryAvailable(args)) {
        return [NSString stringWithFormat:@"%@?%@", baseUrl, AFQueryStringFromParameters(args)];
    } else if (DMNSStringAvailable(queryString) || (DMNSStringAvailable(originUrlString) && DMNSDictionaryAvailable(args))) {
        return [NSString stringWithFormat:@"?%@", AFQueryStringFromParameters(args)];
    }
    
    return originUrlString;
}

@end
