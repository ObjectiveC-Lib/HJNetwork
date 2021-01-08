//
//  DMInlineHeader.h
//  HJNetworkDemo
//
//  Created by navy on 2020/12/25.
//

#ifndef DMInlineHeader_h
#define DMInlineHeader_h

static inline NSString *DMQueryStringFromParameters(NSDictionary *parameters) {
    NSMutableArray *mutablePairs = [NSMutableArray array];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"description" ascending:YES selector:@selector(compare:)];
    for (id nestedKey in [parameters.allKeys sortedArrayUsingDescriptors:@[ sortDescriptor ]]) {
        id nestedValue = parameters[nestedKey];
        [mutablePairs addObject:[NSString stringWithFormat:@"%@=%@", nestedKey, nestedValue?:@""]];
    }
    return [mutablePairs componentsJoinedByString:@"&"];
}

static inline NSString *DMSafeNSString(NSString *string) {
    return (string && [string isKindOfClass:[NSString class]]) ? string : ([string isKindOfClass:[NSNumber class]] ? [string description]:@"");
}

static inline BOOL DMNSStringIsEqual(NSString *string, NSString *toString) {
    return ([string isEqualToString:toString]);
}

static inline BOOL DMNSStringAvailable(NSString *string) {
    return (string != nil && [string isKindOfClass:[NSString class]] && string.length > 0);
}

static inline BOOL DMNSArrayAvailable(NSArray *array) {
    return (array && [array isKindOfClass:[NSArray class]] && [array count]);
}

static inline BOOL DMNSDictionaryAvailable(NSDictionary *dictionary) {
    return (dictionary && [dictionary isKindOfClass:[NSDictionary class]] && [dictionary count]);
}


#endif /* DMInlineHeader_h */
