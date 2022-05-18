//
//  HJXMLRequest.m
//  HJNetwork
//
//  Created by navy on 18/8/10.
//  Copyright © 2018 HJNetwork. All rights reserved.
//

#import "HJXMLRequest.h"

@implementation HJXMLRequest

- (HJResponseSerializerType)responseSerializerType {
    return HJResponseSerializerTypeXMLParser;
}

@end
