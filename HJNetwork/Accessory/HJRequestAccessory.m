//
//  HJRequestAccessory.m
//  HJNetwork
//
//  Created by navy on 2018/7/6.
//  Copyright © 2018 HJNetwork. All rights reserved.
//

#import "HJRequestAccessory.h"

@implementation HJRequestAccessory

- (id)initWithAnimatingView:(UIView *)animatingView animatingText:(NSString *)animatingText {
    self = [super init];
    if (self) {
        _animatingView = animatingView;
        _animatingText = animatingText;
    }
    return self;
}

- (id)initWithAnimatingView:(UIView *)animatingView {
    self = [super init];
    if (self) {
        _animatingView = animatingView;
    }
    return self;
}

+ (id)accessoryWithAnimatingView:(UIView *)animatingView {
    return [[self alloc] initWithAnimatingView:animatingView];
}

+ (id)accessoryWithAnimatingView:(UIView *)animatingView animatingText:(NSString *)animatingText {
    return [[self alloc] initWithAnimatingView:animatingView animatingText:animatingText];
}

- (void)requestWillStart:(id)request {
    if (_animatingView) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // TODO: show loading
            //            [HJAlertUtils showLoadingAlertView:_animatingText inView:_animatingView];
        });
    }
}

- (void)requestWillStop:(id)request {
    if (_animatingView) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // TODO: hide loading
            //            [HJAlertUtils hideLoadingAlertView:_animatingView];
        });
    }
}

@end
