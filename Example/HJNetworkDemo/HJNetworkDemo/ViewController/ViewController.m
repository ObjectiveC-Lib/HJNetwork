//
//  ViewController.m
//  HJNetworkDemo
//
//  Created by navy on 2020/12/23.
//

#import "ViewController.h"
#import <HJNetwork/HJNetworkPrivate.h>
#import "DMHTTPRequest.h"
#import "DMDownloadRequest.h"
#import "DMUploadRequest.h"
#import "ImageViewController.h"
#import "WKWebViewController.h"
#import "NSObject+HJUpload.h"
#import "HJFileSource.h"
#import "HJUploadRequest.h"
#import "HJFileSourceManager.h"


@interface ViewController ()
@property (nonatomic, strong) HJFileSource *source;
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
    [btn0 addTarget:self action:@selector(iamgeShow:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn0];
    
    UIButton *btn = [self createButton:CGRectMake(0.0, CGRectGetHeight(self.view.frame) - 60 - bottom, 120.0, 60.0)];
    btn.backgroundColor = [UIColor blueColor];
    [btn setTitle:@"BasicRequest" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(basicHTTPRequest:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    UIButton *btn1 = [self createButton:CGRectMake(CGRectGetWidth(self.view.frame) * 0.5 - 40, CGRectGetHeight(self.view.frame) - 60 - bottom, 100.0, 60.0)];
    [btn1 setTitle:@"Upload" forState:UIControlStateNormal];
    btn1.backgroundColor = [UIColor yellowColor];
    [btn1 addTarget:self action:@selector(upload:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn1];
    
    UIButton *btn2 = [self createButton:CGRectMake(CGRectGetWidth(self.view.frame) - 100, CGRectGetHeight(self.view.frame) - 60 - bottom, 100.0, 60.0)];
    [btn2 setTitle:@"Download" forState:UIControlStateNormal];
    btn2.backgroundColor = [UIColor redColor];
    [btn2 addTarget:self action:@selector(resumDownload:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn2];
    
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

- (void)expectRequest:(HJRequest *)request {
    [request startWithCompletionBlockWithSuccess:^(__kindof HJBaseRequest * _Nonnull request) {
        NSDictionary *resultObj = request.responseJSONObject;
        NSLog(@"resultObj_Success = %@", resultObj);
    } failure:^(__kindof HJBaseRequest * _Nonnull request) {
        NSError *resultObj = request.error;
        NSLog(@"resultObj_Failure = %@", resultObj);
    }];
}

- (void)upload:(id)sender {
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"head" withExtension:@"jpeg"];
    NSURL *url1 = [[NSBundle mainBundle] URLForResource:@"test" withExtension:@"txt"];
    NSURL *url2 = [[NSBundle mainBundle] URLForResource:@"gamker" withExtension:@"mp4"];
    //    DMUploadRequest *upload = [[DMUploadRequest alloc] initWithPath:url.absoluteString];
    //    upload.uploadProgressBlock = ^(NSProgress * _Nonnull progress) {
    //        NSLog(@"req_Uploading: %lld / %lld", progress.completedUnitCount, progress.totalUnitCount);
    //    };
    //    [self expectRequest:upload];
    //    [upload stop];
    //    return;
    
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
    
//    [self uploadSourceWithAbsolutePaths:@[url.path, url1.path]];
//    [self uploadSourceWithAbsolutePaths:@[url.path]];
    [self uploadSourceWithAbsolutePaths:@[url2.path]];
}

- (void)uploadSourceWithAbsolutePaths:(NSArray <NSString *>*)paths {
    if (paths.count <= 0) return;
    
    HJFileSource *source = [[HJFileSource alloc] initWithAbsolutePaths:paths config:[HJUploadConfig defaultConfig]];
    source.progress = ^(NSProgress * _Nullable progress) {
        NSLog(@"HJFileSource_progress: %lld / %lld", progress.completedUnitCount, progress.totalUnitCount);
    };
    source.completion = ^(HJFileStatus status, NSError * _Nullable error) {
        NSLog(@"HJFileSource_completion: status = %lu", (unsigned long)status);
        NSLog(@"HJFileSource_completion: error = %@", error);
    };
    
    [source startWithBlock:^(HJFileFragment * _Nonnull fragment) {
        NSLog(@"fragment_index = %lu", (unsigned long)fragment.index);
        fragment.status = HJFileStatusProcessing;
        HJUploadRequest *upload = [[HJUploadRequest alloc] initWithFragment:fragment];
        [[HJTaskManager sharedInstance] executor:upload
                                        progress:^(NSProgress * _Nullable taskProgress) {
            if (fragment.progress) {
                fragment.progress(taskProgress);
            }
        } completion:^(HJTaskKey key,
                       HJTaskStage stage,
                       NSDictionary<NSString *,id> * _Nullable callbackInfo,
                       NSError * _Nullable error) {
            HJFileStatus status = HJFileStatusWaiting;
            if (stage == HJTaskStageFinished) {
                status = error?HJFileStatusFailure:HJFileStatusSuccess;
            } else if (stage == HJTaskStageCancelled) {
                status = HJFileStatusFailure;
            }
            fragment.status = status;
            if (fragment.completion) {
                fragment.completion(status, error);
            }
        }];
    }];
    
    //    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
    //        [source cancelWithBlock:^(HJFileFragment * _Nonnull fragment) {
    //            [[HJTaskManager sharedInstance] cancelWithKey:fragment.fragmentId];
    //        }];
    //    });
}

//NSString *const kTestDownloadURL = @"https://qd.myapp.com/myapp/qqteam/AndroidQQ/mobileqq_android.apk";
NSString *const kTestDownloadURL = @"https://seopic.699pic.com/photo/50008/9194.jpg_wh1200.jpg";

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
    AFSessionManager *manager = [AFSessionManager manager:[HJNetworkConfig new]];
    [manager GET:@"https://httpbin.org/get"
      parameters:nil
         headers:nil
        progress:^(NSProgress * _Nonnull progress) {
        NSLog(@"AFSessionManager_progress =  %lld / %lld", progress.completedUnitCount, progress.totalUnitCount);
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"AFSessionManager_success = %@", responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"AFSessionManager_failure = %@", error);
    }];
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

@end
