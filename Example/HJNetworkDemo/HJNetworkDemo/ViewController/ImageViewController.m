//
//  ImageViewController.m
//  HJNetworkDemo
//
//  Created by navy on 2020/12/28.
//

#import "ImageViewController.h"
#import <SDWebImage/SDWebImage.h>

@interface ImageViewController ()
@property (nonatomic,strong) UIImageView *imageView;
@end

@implementation ImageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    self.imageView.image = [UIImage imageNamed:@"WechatIMG6"];
    [self.view addSubview:self.imageView];
//

    NSURL *url = [NSURL URLWithString:@"https://file.dingtalk.com/upd/v1/im/chat/pic/2012/6ba48be2e006e0eab10857d819530095.jpg"];
//    NSURL *url = [NSURL URLWithString:@"https://file.dingtalk.com/upd/v1/im/chat/pic/2012/64cf85efa1028174d19d25a0a4103c7a.jpg"];
//    NSURL *url = [NSURL URLWithString:@"https://file.dingtalk.com/upd/v1/im/chat/pic/2012/64cf85efa1028174d19d25a0a4103c7a_434x422.jpg"];
    [self.imageView sd_setImageWithURL:url placeholderImage:nil
                               options:SDWebImageRetryFailed
                              progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
        NSLog(@"receivedSize = %ld", (long)receivedSize);
    } completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        NSLog(@"imageURL = %@", imageURL);
        NSLog(@"error = %@", error);
        
        self.imageView.image = image;
    }];
}

- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [UIImageView new];
        _imageView.frame = self.view.bounds;
        _imageView.clipsToBounds = YES;
        _imageView.userInteractionEnabled = YES;
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
    }
    return _imageView;
}

@end
