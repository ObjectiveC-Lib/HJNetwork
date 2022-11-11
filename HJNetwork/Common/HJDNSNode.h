//
//  HJDNSNode.h
//  HJNetwork
//
//  Created by navy on 2022/6/1.
//  Copyright © 2022 HJNetwork. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HJDNSNode : NSObject

@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong, nullable) NSString *host;

@end

NS_ASSUME_NONNULL_END
