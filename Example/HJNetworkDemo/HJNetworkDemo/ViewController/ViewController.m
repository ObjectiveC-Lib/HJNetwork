//
//  ViewController.m
//  HJNetworkDemo
//
//  Created by navy on 2020/12/23.
//

#import "ViewController.h"
#import "ImageViewController.h"
#import "DMAccountLoginApi.h"
#import "DMAppConfigApi.h"
#import "DMUploadImageApi.h"
#import "HJUpload.h"


@interface ViewController ()
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGFloat bottom = 0;
    if (@available(iOS 11.0, *)) {
        bottom = [UIApplication sharedApplication].delegate.window.safeAreaInsets.bottom;
    }
    
    UIButton *btn = [self createButton:CGRectMake(0.0, CGRectGetHeight(self.view.frame) - 60 - bottom, 100.0, 60.0)];
    btn.backgroundColor = [UIColor blueColor];
    [btn setTitle:@"LoginApi" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(loginApi:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    UIButton *btn1 = [self createButton:CGRectMake(CGRectGetWidth(self.view.frame) * 0.5 - 30, CGRectGetHeight(self.view.frame) - 60 - bottom, 100.0, 60.0)];
    [btn1 setTitle:@"ConfigApi" forState:UIControlStateNormal];
    btn1.backgroundColor = [UIColor yellowColor];
    [btn1 addTarget:self action:@selector(configApi:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn1];
    
    UIButton *btn2 = [self createButton:CGRectMake(CGRectGetWidth(self.view.frame) - 60, CGRectGetHeight(self.view.frame) - 60 - bottom, 60.0, 60.0)];
    [btn2 setTitle:@"点击我" forState:UIControlStateNormal];
    btn2.backgroundColor = [UIColor redColor];
    [btn2 addTarget:self action:@selector(uploadImage) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn2];
}

- (UIButton *)createButton:(CGRect)frame {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = frame;
    [btn setTitleColor:[UIColor brownColor] forState:UIControlStateNormal];
    btn.exclusiveTouch = YES;
    return btn;
}

#pragma mark - Action

- (void)loginApi:(id)sender {
    DMAccountLoginApi *api = [[DMAccountLoginApi alloc] initWithAccountName:@"name" pwd:@"pwd"];
    [api startWithCompletionBlockWithSuccess:^(__kindof HJBaseRequest * _Nonnull request) {
        NSDictionary *resultObj = request.responseJSONObject;
        NSLog(@"resultObj = %@", resultObj);
        
    } failure:^(__kindof HJBaseRequest * _Nonnull request) {
        NSDictionary *resultObj = request.responseJSONObject;
        NSLog(@"resultObj = %@", resultObj);

    }];
}

- (void)configApi:(id)sender {
    DMAppConfigApi *api = [[DMAppConfigApi alloc] init];
    [api startWithCompletionBlockWithSuccess:^(__kindof HJBaseRequest * _Nonnull request) {
        NSDictionary *resultObj = request.responseJSONObject;
        NSLog(@"resultObj = %@", resultObj);

    } failure:^(__kindof HJBaseRequest * _Nonnull request) {
        NSDictionary *resultObj = request.responseJSONObject;
        NSLog(@"resultObj = %@", resultObj);

    }];
}

- (void)uploadImage {
    UIImage *image = [UIImage imageNamed:@"WechatIMG6"];
    DMUploadImageApi *api = [[DMUploadImageApi alloc] initWithImage:image];
    
    [HJUpload hj_upload:api
                  image:image
               progress:^(NSProgress * _Nullable taskProgress) {
        NSLog(@"fractionCompleted: %f", taskProgress.fractionCompleted);
//        NSLog(@"totalUnitCount: %lld", uploadProgress.totalUnitCount);
        
    } completion:^(HJTaskKey key, HJTaskStage stage, NSDictionary<NSString *,id> * _Nullable callbackInfo, NSError * _Nullable error) {
        NSLog(@"completion_key = %@", key);
        NSLog(@"completion_stage = %ld", (long)stage);
        NSLog(@"completion_callbackInfo = %@", callbackInfo);
        NSLog(@"completion_error = %@", error);
    }];
}

- (void)doShowImageVC:(id)sender {
    ImageViewController *vc = [ImageViewController new];
    [self.navigationController pushViewController:vc animated:YES];
}



@end
