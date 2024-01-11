//
//  ViewController.m
//  HJNetworkDemo
//
//  Created by navy on 2020/12/23.
//

#import "ViewController.h"
#import "ImageViewController.h"
#import "WKWebViewController.h"

#import <HJNetwork/HJNetwork.h>
#import <HJNetwork/HJNetworkPrivate.h>
#import "DMCommonRequest.h"
#import "DMHTTPRequest.h"
#import "DMDownloadRequest.h"
#import "DMUploadRequest.h"
#import "NSObject+HJUploadTask.h"
#import "HJUploadManager.h"
#import "DMDNSTest.h"
#import "DMHTTPSessionManager.h"
#import "HJUploadRequest.h"

@interface ViewController ()
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGFloat bottom = 0;
    if (@available(iOS 11.0, *)) {
        bottom = [UIApplication sharedApplication].delegate.window.safeAreaInsets.bottom;
    }
    
    UIButton *btn0 = [self createButton:CGRectMake(0.0, CGRectGetHeight(self.view.frame) - 60 - bottom - 120, 120.0, 60.0)];
    btn0.backgroundColor = [UIColor blueColor];
    [btn0 setTitle:@"Image" forState:UIControlStateNormal];
    [btn0 addTarget:self action:@selector(HJRequestManagerRequest:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *btn = [self createButton:CGRectMake(0.0, CGRectGetHeight(self.view.frame) - 60 - bottom, 120.0, 60.0)];
    btn.backgroundColor = [UIColor blueColor];
    [btn setTitle:@"BasicRequest" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(basicHTTPRequest:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *btn1 = [self createButton:CGRectMake(CGRectGetWidth(self.view.frame) * 0.5 - 40, CGRectGetHeight(self.view.frame) - 60 - bottom, 100.0, 60.0)];
    [btn1 setTitle:@"Upload" forState:UIControlStateNormal];
    btn1.backgroundColor = [UIColor yellowColor];
    [btn1 addTarget:self action:@selector(upload:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *btn2 = [self createButton:CGRectMake(CGRectGetWidth(self.view.frame) - 100, CGRectGetHeight(self.view.frame) - 60 - bottom, 100.0, 60.0)];
    [btn2 setTitle:@"Download" forState:UIControlStateNormal];
    btn2.backgroundColor = [UIColor redColor];
    [btn2 addTarget:self action:@selector(resumDownload:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *btn3 = [self createButton:CGRectMake(CGRectGetWidth(self.view.frame) - 100, CGRectGetHeight(self.view.frame) - 130 - bottom, 100.0, 60.0)];
    [btn3 setTitle:@"resolveURL" forState:UIControlStateNormal];
    btn3.backgroundColor = [UIColor cyanColor];
    [btn3 addTarget:self action:@selector(resolveURL) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *btn4 = [self createButton:CGRectMake(CGRectGetWidth(self.view.frame) - 100, CGRectGetHeight(self.view.frame) - 200 - bottom, 100.0, 60.0)];
    [btn4 setTitle:@"negative" forState:UIControlStateNormal];
    btn4.backgroundColor = [UIColor cyanColor];
    [btn4 addTarget:self action:@selector(negative) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *btn5 = [self createButton:CGRectMake(CGRectGetWidth(self.view.frame) - 100, CGRectGetHeight(self.view.frame) - 270 - bottom, 100.0, 60.0)];
    [btn5 setTitle:@"positive" forState:UIControlStateNormal];
    btn5.backgroundColor = [UIColor cyanColor];
    [btn5 addTarget:self action:@selector(positive) forControlEvents:UIControlEventTouchUpInside];
    
    //    NSURL *url = [NSURL URLWithString:@"https://www.cnblogs.com:8080/isItOk/p/5025679.html"];
    //    NSLog(@"host = %@", url.host);
    //    NSLog(@"port = %@", url.port);
    //    NSLog(@"scheme = %@", url.scheme);
    //
    //    CFMutableArrayRef _arr = CFArrayCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeArrayCallBacks);
    //    CFArrayAppendValue(_arr,  CFSTR("a"));
    //    CFArrayAppendValue(_arr,  CFSTR("b"));
    //    CFArrayAppendValue(_arr,  CFSTR("c"));
    //    CFArrayExchangeValuesAtIndices(_arr, 0, 2);
    //    NSLog(@"_arr = %@", _arr);
    
    //    NSArray *arr = @[@"a", @"b", @"a"];
    //    NSSet *set = [NSSet setWithArray:arr];
    //    NSLog(@"set = %@", set);
}

- (UIButton *)createButton:(CGRect)frame {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = frame;
    [btn setTitleColor:[UIColor brownColor] forState:UIControlStateNormal];
    btn.exclusiveTouch = YES;
    [self.view addSubview:btn];
    return btn;
}

#pragma mark - Action

- (void)basicHTTPRequest:(id)sender {
    DMHTTPRequest *get = [[DMHTTPRequest alloc] initWithRequestUrl:@"get" method:HJRequestMethodGET];
    [self expectRequest:get];
    
    //    DMHTTPRequest *post = [[DMHTTPRequest alloc] initWithRequestUrl:@"post" method:HJRequestMethodPOST];
    //    [self expectRequest:post];
    
    //    DMHTTPRequest *patch = [[DMHTTPRequest alloc] initWithRequestUrl:@"patch" method:HJRequestMethodPATCH];
    //    [self expectRequest:patch];
    
    //    DMHTTPRequest *put = [[DMHTTPRequest alloc] initWithRequestUrl:@"put" method:HJRequestMethodPUT];
    //    [self expectRequest:put];
    
    //    DMHTTPRequest *delete = [[DMHTTPRequest alloc] initWithRequestUrl:@"delete" method:HJRequestMethodDELETE];
    //    [self expectRequest:delete];
    
    //    DMHTTPRequest *head = [[DMHTTPRequest alloc] initWithRequestUrl:@"head" method:HJRequestMethodHEAD];
    //    [self expectRequest:head];
    
    //    DMHTTPRequest *fail404 = [[DMHTTPRequest alloc] initWithRequestUrl:@"status/404" method:HJRequestMethodGET];
    //    [self expectRequest:fail404];
}

- (void)expectRequest:(HJBaseRequest *)request {
    [request startWithCompletionBlockWithSuccess:^(__kindof HJCoreRequest * _Nonnull request) {
        NSDictionary *resultObj = request.responseJSONObject;
        NSLog(@"resultObj_Success = %@", resultObj);
    } failure:^(__kindof HJCoreRequest * _Nonnull request) {
        NSError *resultObj = request.error;
        NSLog(@"resultObj_Failure = %@", resultObj);
    }];
}

- (void)upload:(id)sender {
    NSURL *url1 = [[NSBundle mainBundle] URLForResource:@"head" withExtension:@"jpeg"];
    NSURL *url2 = [[NSBundle mainBundle] URLForResource:@"test" withExtension:@"txt"];
    NSURL *url3 = [[NSBundle mainBundle] URLForResource:@"gamker" withExtension:@"mp4"];
    NSURL *url4 = [[NSBundle mainBundle] URLForResource:@"movie" withExtension:@"mp4"];
    
    /*********************************************************************************************/
    //    DMUploadRequest *upload = [[DMUploadRequest alloc] initWithPath:url.absoluteString];
    //    upload.uploadProgressBlock = ^(NSProgress * _Nonnull progress) {
    //        NSLog(@"req_Uploading: %lld / %lld", progress.completedUnitCount, progress.totalUnitCount);
    //    };
    //    [self expectRequest:upload];
    //    [upload stop];
    //    return;
    /*********************************************************************************************/
    
    
    /*********************************************************************************************/
    //    HJTaskKey key = [[HJTaskManager sharedInstance] executor:upload
    //                                                   preHandle:^BOOL(HJTaskKey key) {return YES;}
    //                                                    progress:^(NSProgress * _Nullable taskProgress) {
    //        NSLog(@"HJTaskManager_progress: %lld / %lld", taskProgress.completedUnitCount, taskProgress.totalUnitCount);
    //    }
    //                                                  completion:^(HJTaskKey key,
    //                                                               HJTaskStage stage,
    //                                                               NSDictionary<NSString *,id> * _Nullable callbackInfo,
    //                                                               NSError * _Nullable error) {
    //        NSLog(@"completion_key = %@", key);
    //        NSLog(@"completion_stage = %ld", (long)stage);
    //        NSLog(@"completion_callbackInfo = %@", callbackInfo);
    //        NSLog(@"completion_error = %@", error);
    //    }];
    //    [[HJTaskManager sharedInstance] cancelWithKey:key];
    //    return;
    /*********************************************************************************************/
    
    
    /*********************************************************************************************/
    //    HJTaskKey uploadkey = [self hj_upload:nil
    //                                     path:url.path
    //                                 progress:^(NSProgress * _Nullable taskProgress) {
    //        NSLog(@"HJUpload_progress: %lld / %lld", taskProgress.completedUnitCount, taskProgress.totalUnitCount);
    //    } completion:^(HJTaskKey key,
    //                   HJTaskStage stage,
    //                   NSDictionary<NSString *,id> * _Nullable callbackInfo,
    //                   NSError * _Nullable error) {
    //        NSLog(@"HJUpload_completion_key = %@", key);
    //        NSLog(@"HJUpload_completion_stage = %ld", (long)stage);
    //        NSLog(@"HJUpload_completion_callbackInfo = %@", callbackInfo);
    //        NSLog(@"HJUpload_completion_error = %@", error);
    //    }];
    
    //    __weak typeof (self) _self = self;
    //    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
    //        __strong typeof(_self) self = _self;
    //        [self hj_cancelUploadWithKey:uploadkey];
    //    });
    //    return;
    /*********************************************************************************************/
    
    
    /*********************************************************************************************/
    
    HJUploadConfig *config = [HJUploadConfig defaultConfig];
    config.retryEnable = YES;
    config.fragmentEnable = YES;
    config.fragmentMaxSize = 512*1024;
    
    HJUploadSourceKey key = [HJUploadManager uploadWithAbsolutePath:url4.path
                                                             config:config
                                                      uploadRequest:^HJCoreRequest * _Nonnull(HJUploadFileFragment * _Nonnull fragment) {
        HJUploadRequest *request = [[HJUploadRequest alloc] initWithFragment:fragment];
        return request;
    } uploadProgress:^(NSProgress * _Nullable progress) {
        NSLog(@"HJUpload_progress: %lld / %lld", progress.completedUnitCount, progress.totalUnitCount);
    } uploadCompletion:^(HJUploadStatus status, id  _Nullable callbackInfo, NSError * _Nullable error) {
        NSLog(@"$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$");
        NSLog(@"HJUpload_completion_stage = %ld", (long)status);
        NSLog(@"HJUpload_completion_callbackInfo = %@", callbackInfo);
        NSLog(@"HJUpload_completion_error = %@", error);
    }];
    
    //    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
    //        [HJUploadManager cancelUpload:key];
    //    });
    
    /*********************************************************************************************/
}

//NSString *const kTestDownloadURL = @"https://qd.myapp.com/myapp/qqteam/AndroidQQ/mobileqq_android.apk";
//NSString *const kTestDownloadURL = @"https://seopic.699pic.com/photo/50008/9194.jpg_wh1200.jpg";
NSString *const kTestDownloadURL = @"https://47.244.6.114/upd/v1/im/chat/file/2401/95b5ee7b-4c51-4067-add2-480f5d98d12e";

- (void)resumDownload:(id)sender {
    [self clearDirectory:[DMDownloadRequest saveBasePath]];
    [self clearDirectory:[[HJNetworkAgent sharedAgent] incompleteDownloadTempCacheFolder]];
    [self createDirectory:[DMDownloadRequest saveBasePath]];
    
    DMDownloadRequest *req = [[DMDownloadRequest alloc] initWithTimeout:20 requestUrl:kTestDownloadURL];
    req.resumableDownloadProgressBlock = ^(NSProgress *progress) {
        NSLog(@"req_Downloading: %lld / %lld", progress.completedUnitCount, progress.totalUnitCount);
    };
    [self expectRequest:req];
    
    //    // Start the request again
    //    [[HJNetworkAgent sharedAgent] resetURLSessionManager];
    //    // Allow all content type
    //    [[HJNetworkAgent sharedAgent] manager].responseSerializer.acceptableContentTypes = nil;
    //
    //    DMDownloadRequest *req2 = [[DMDownloadRequest alloc] initWithTimeout:20 requestUrl:kTestDownloadURL];
    //    req2.resumableDownloadProgressBlock = ^(NSProgress *progress) {
    //        NSLog(@"req2_Downloading: %lld / %lld", progress.completedUnitCount, progress.totalUnitCount);
    //    };
    //    [self expectRequest:req2];
}

- (void)get:(id)sender {
    DMHTTPSessionManager *manager = [DMHTTPSessionManager manager];
    [manager GET:@"https://httpbin.org/get"
      parameters:nil
         headers:nil
        progress:^(NSProgress * _Nonnull progress) {
        NSLog(@"DMHTTPSessionManager_progress =  %lld / %lld", progress.completedUnitCount, progress.totalUnitCount);
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"DMHTTPSessionManager_success = %@", responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"DMHTTPSessionManager_failure = %@", error);
    }];
}

- (void)HJRequestManagerRequest:(id)sender {
    HJRetryRequestConfig *config = [HJRetryRequestConfig defaultConfig];
    config.retryInterval = 2;
    HJRetryRequestKey key = [HJRetryRequestManager requestWithConfig:config
                                                        retryRequest:^HJCoreRequest * _Nonnull {
        BOOL isImage = YES;
        NSString *url = isImage?kTestDownloadURL:@"https://httpbin.org/get";
        DMCommonRequest *request = [[DMCommonRequest alloc] initWithUrl:url
                                                        requestArgument:nil
                                                            headerField:nil
                                                          requestMethod:HJRequestMethodGET
                                                  requestSerializerType:HJRequestSerializerTypeHTTP
                                                 responseSerializerType:HJResponseSerializerTypeJSON];
        if (isImage) {
            [self clearDirectory:[DMDownloadRequest saveBasePath]];
            [self clearDirectory:[[HJNetworkAgent sharedAgent] incompleteDownloadTempCacheFolder]];
            [self createDirectory:[DMDownloadRequest saveBasePath]];
        }
        if (isImage) {
            request.resumableDownloadPath = [DMDownloadRequest saveBasePath];
            request.ignoreResumableData = YES;
        }
        request.ignoreCache = YES;
        request.requestCachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
        return request;
    } requestProgress:^(NSProgress * _Nullable progress) {
        NSLog(@"HJRetryRequestManager_progress =  %lld / %lld", progress.completedUnitCount, progress.totalUnitCount);
    } requestCompletion:^(HJRetryRequestStatus status, id  _Nullable callbackInfo, NSError * _Nullable error) {
        NSLog(@"HJRetryRequestManager_result:\ncallbackInfo = %@,\nerror = %@", callbackInfo, error);
    }];
    
    //    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
    //        [HJRetryRequestManager cancelRequest:key];
    //    });
}

- (void)createDirectory:(NSString *)path {
    NSError *error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:path
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:&error];
    if (error) {
        NSLog(@"Create directory error: %@", error);
    }
}

- (void)clearDirectory:(NSString *)path {
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    if (![fileManager fileExistsAtPath:path isDirectory:nil]) {
        return;
    }
    
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtPath:path];
    NSError *err = nil;
    BOOL res;
    
    NSString *file;
    while (file = [enumerator nextObject]) {
        res = [fileManager removeItemAtPath:[path stringByAppendingPathComponent:file] error:&err];
        if (!res && err) {
            NSLog(@"Delete file error: %@", err);
        }
    }
}

- (void)iamgeShow:(id)sender {
    //    ImageViewController *vc = [[ImageViewController alloc] init];
    WKWebViewController *vc = [[WKWebViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)resolveURL {
    [DMDNSTest resolveURL];
}

- (void)negative {
    [DMDNSTest negative];
}

- (void)positive {
    [DMDNSTest positive];
}

@end
