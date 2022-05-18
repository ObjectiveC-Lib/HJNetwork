//
//  HJResumableDownloadTests.m
//  HJNetwork
//
//  Created by navy on 18/8/12.
//  Copyright © 2018 HJNetwork. All rights reserved.
//

#import "HJTestCase.h"
#import "HJDownloadRequest.h"
#import "HJNetworkPrivate.h"
#import "AFNetworking.h"

NSString *const kTestDownloadURL = @"https://qd.myapp.com/myapp/qqteam/AndroidQQ/mobileqq_android.apk";
NSString *const kTestFailDownloadURL = @"https://qd.myapp.com/myapp/qqteam/AndroidQQ/mobileqq_android.apkfail";

@interface HJResumableDownloadTests : HJTestCase

@end

@implementation HJResumableDownloadTests

- (void)setUp {
    [super setUp];
    [self createDirectory:[self saveBasePath]];
    [self clearDirectory:[[HJNetworkAgent sharedAgent] incompleteDownloadTempCacheFolder]];
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    // Ignore cache
    config.requestCachePolicy = NSURLRequestReloadIgnoringCacheData;
    config.HTTPCookieAcceptPolicy = NSHTTPCookieAcceptPolicyNever;
    // Force download failed because of timeout.
    config.timeoutIntervalForResource = 1;
    [[HJNetworkAgent sharedAgent] resetURLSessionManagerWithConfiguration:config];
    // Allow all content type
    [[HJNetworkAgent sharedAgent] manager].responseSerializer.acceptableContentTypes = nil;
}

- (void)tearDown {
    [super tearDown];
    [self clearDirectory:[self saveBasePath]];
    [self clearDirectory:[[HJNetworkAgent sharedAgent] incompleteDownloadTempCacheFolder]];
}

- (NSString *)saveBasePath {
    NSString *pathOfLibrary = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *path = [pathOfLibrary stringByAppendingPathComponent:@"testResumableDownload"];
    return path;
}

- (void)testResumableDownloadWithFullPath {
    // Timeout less than 1 second will be ignored.
    // Here we assume that the file can not be fully downloaded in 1 second.
    // !!If run this test for multiple times. Local cache or CDN cache may still kick in, causing very fast download
    // speed and break this test.
    HJDownloadRequest *req = [[HJDownloadRequest alloc] initWithTimeout:1 requestUrl:kTestDownloadURL];
    req.resumableDownloadPath = [[self saveBasePath] stringByAppendingPathComponent:@"downloaded.bin"];
    req.resumableDownloadProgressBlock = ^(NSProgress *progress) {
        NSLog(@"Downloading: %lld / %lld", progress.completedUnitCount, progress.totalUnitCount);
    };
    
    [self expectFailure:req];
    
    // Start the request again
    [[HJNetworkAgent sharedAgent] resetURLSessionManager];
    // Allow all content type
    [[HJNetworkAgent sharedAgent] manager].responseSerializer.acceptableContentTypes = nil;
    
    HJDownloadRequest *req2 = [[HJDownloadRequest alloc] initWithTimeout:self.networkTimeout requestUrl:kTestDownloadURL];
    req2.resumableDownloadPath = [[self saveBasePath] stringByAppendingPathComponent:@"downloaded.bin"];
    req2.resumableDownloadProgressBlock = ^(NSProgress *progress) {
        XCTAssertTrue(progress.completedUnitCount > 0);
        NSLog(@"Downloading: %lld / %lld", progress.completedUnitCount, progress.totalUnitCount);
    };
    
    [self expectSuccess:req2];
}

- (void)testResumableDownloadWithDirectoryPath {
    HJDownloadRequest *req = [[HJDownloadRequest alloc] initWithTimeout:1 requestUrl:kTestDownloadURL];
    req.resumableDownloadPath = [self saveBasePath];
    req.resumableDownloadProgressBlock = ^(NSProgress *progress) {
        NSLog(@"Downloading: %lld / %lld", progress.completedUnitCount, progress.totalUnitCount);
    };
    
    [self expectFailure:req];
    
    [[HJNetworkAgent sharedAgent] resetURLSessionManager];
    [[HJNetworkAgent sharedAgent] manager].responseSerializer.acceptableContentTypes = nil;
    
    HJDownloadRequest *req2 = [[HJDownloadRequest alloc] initWithTimeout:self.networkTimeout requestUrl:kTestDownloadURL];
    req2.resumableDownloadPath = [self saveBasePath];
    req2.resumableDownloadProgressBlock = ^(NSProgress *progress) {
        XCTAssertTrue(progress.completedUnitCount > 0);
        NSLog(@"Downloading: %lld / %lld", progress.completedUnitCount, progress.totalUnitCount);
    };
    
    [self expectSuccess:req2];
}

- (void)testResumableDownloadOverwriteAndCleanup {
    [[HJNetworkAgent sharedAgent] resetURLSessionManager];
    [[HJNetworkAgent sharedAgent] manager].responseSerializer.acceptableContentTypes = nil;
    NSString *path = [[self saveBasePath] stringByAppendingPathComponent:@"downloaded.bin"];
    
    // Create a exist file
    NSString *testString = @"TEST";
    NSData *stringData = [testString dataUsingEncoding:NSUTF8StringEncoding];
    [stringData writeToFile:path atomically:YES];
    
    // Download req file
    HJDownloadRequest *req = [[HJDownloadRequest alloc] initWithTimeout:self.networkTimeout requestUrl:kTestDownloadURL];
    req.resumableDownloadPath = path;
    req.resumableDownloadProgressBlock = ^(NSProgress *progress) {
        XCTAssertTrue(progress.completedUnitCount > 0);
        NSLog(@"Downloading: %lld / %lld", progress.completedUnitCount, progress.totalUnitCount);
    };
    
    [self expectSuccess:req];
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:path]);
    XCTAssertTrue(([[NSFileManager defaultManager] contentsAtPath:path].length > stringData.length));
    
    HJDownloadRequest *req2 = [[HJDownloadRequest alloc] initWithTimeout:self.networkTimeout requestUrl:kTestFailDownloadURL];
    req2.resumableDownloadPath = path;
    req2.resumableDownloadProgressBlock = ^(NSProgress *progress) {
        XCTAssertTrue(progress.completedUnitCount > 0);
        NSLog(@"Downloading: %lld / %lld", progress.completedUnitCount, progress.totalUnitCount);
    };
    
    [self expectFailure:req2];
    XCTAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:path]);
    XCTAssertTrue(req2.responseData.length > 0 && req2.responseString.length > 0);
}

@end
