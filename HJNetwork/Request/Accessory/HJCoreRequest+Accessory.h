//
//  HJCoreRequest+Accessory.h
//  HJNetwork
//
//  Created by navy on 2018/7/6.
//  Copyright © 2018 HJNetwork. All rights reserved.
//

#import "HJCoreRequest.h"
#import <UIKit/UIKit.h>

@interface HJCoreRequest (Accessory)
@property(nonatomic, weak  ) UIView *animatingView;
@property(nonatomic, strong) NSString *animatingText;
@end
