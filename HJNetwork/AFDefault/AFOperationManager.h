//
//  AFOperationManager.h
//  HJNetwork
//
//  Created by navy on 2022/8/18.
//

#import "AFHTTPRequestOperationManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface AFOperationManager : AFHTTPRequestOperationManager

@property (nonatomic, assign) BOOL dnsEnabled;

+ (instancetype)manager;

@end

NS_ASSUME_NONNULL_END
