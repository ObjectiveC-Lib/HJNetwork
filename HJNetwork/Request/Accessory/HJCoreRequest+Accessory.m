//
//  HJCoreRequest+Accessory.m
//  HJNetwork
//
//  Created by navy on 2018/7/6.
//  Copyright © 2018 HJNetwork. All rights reserved.
//

#import "HJCoreRequest+Accessory.h"
#import "HJRequestAccessory.h"

@implementation HJCoreRequest (Accessory)

- (HJRequestAccessory *)animatingRequestAccessory {
    for (id accessory in self.requestAccessories) {
        if ([accessory isKindOfClass:[HJRequestAccessory class]]){
            return accessory;
        }
    }
    return nil;
}

- (UIView *)animatingView {
    return self.animatingRequestAccessory.animatingView;
}

- (void)setAnimatingView:(UIView *)animatingView {
    if (!self.animatingRequestAccessory) {
        [self addAccessory:[HJRequestAccessory accessoryWithAnimatingView:animatingView animatingText:nil]];
    } else {
        self.animatingRequestAccessory.animatingView = animatingView;
    }
}

- (NSString *)animatingText {
    return self.animatingRequestAccessory.animatingText;
}

- (void)setAnimatingText:(NSString *)animatingText {
    if (!self.animatingRequestAccessory) {
        [self addAccessory:[HJRequestAccessory accessoryWithAnimatingView:nil animatingText:animatingText]];
    } else {
        self.animatingRequestAccessory.animatingText = animatingText;
    }
}

@end
