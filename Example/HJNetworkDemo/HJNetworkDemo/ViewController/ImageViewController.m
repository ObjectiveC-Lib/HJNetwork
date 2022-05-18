//
//  ImageViewController.m
//  HJNetworkDemo
//
//  Created by navy on 2022/8/4.
//

#import "ImageViewController.h"
#import <SDWebImage/SDWebImage.h>


@interface ImageViewController ()
@property (nonatomic, strong) UIImageView *imageView;
@end

@implementation ImageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    
    [self.view addSubview:self.imageView];
    NSURL *url = [NSURL URLWithString:@"https://seopic.699pic.com/photo/50008/9194.jpg_wh1200.jpg"];
    [self.imageView sd_setImageWithURL:url
                             completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        NSLog(@"image = %@", image);
        NSLog(@"error = %@", error);
        NSLog(@"imageURL = %@", imageURL.absoluteString);
    }];
}

- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(100, 100, 100, 100)];
        _imageView.backgroundColor = [UIColor blueColor];
    }
    return _imageView;
}

@end
