//
//  HJRequestAccessory.h
//  HJNetwork
//
//  Created by navy on 2018/7/6.
//  Copyright © 2018 HJNetwork. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "HJCoreRequest.h"

@interface HJRequestAccessory : NSObject <HJRequestAccessory>
@property(nonatomic, weak  ) UIView *animatingView;
@property(nonatomic, strong) NSString *animatingText;

- (id)initWithAnimatingView:(UIView *)animatingView;
- (id)initWithAnimatingView:(UIView *)animatingView animatingText:(NSString *)animatingText;
+ (id)accessoryWithAnimatingView:(UIView *)animatingView;
+ (id)accessoryWithAnimatingView:(UIView *)animatingView animatingText:(NSString *)animatingText;
@end
