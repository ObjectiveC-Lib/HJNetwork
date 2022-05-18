//
//  WKWebViewController.m
//  HJNetworkDemo
//
//  Created by navy on 2022/8/30.
//

#import "WKWebViewController.h"
#import <WebKit/WebKit.h>
#import "DMURLProtocol.h"

@interface WKWebViewController ()

@end

@implementation WKWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSURLRequest *webViewReq = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://ent.163.com/photo/#Index"]];
    //创建WKWebview
    WKWebViewConfiguration * config = [[WKWebViewConfiguration alloc] init];
    WKWebView * wkWebView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height) configuration:config];
    [wkWebView loadRequest:webViewReq];
    [self.view addSubview:wkWebView];
}

@end
