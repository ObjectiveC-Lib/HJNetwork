//
//  DMDownloadRequest.m
//  HJNetworkDemo
//
//  Created by navy on 2022/7/27.
//

#import "DMDownloadRequest.h"

@interface DMDownloadRequest ()

@property (nonatomic, assign) NSTimeInterval timeout;
@property (nonatomic, strong) NSString *url;

@end

@implementation DMDownloadRequest

- (instancetype)initWithTimeout:(NSTimeInterval)timeout requestUrl:(NSString *)requestUrl {
    self = [super init];
    if (self) {
        _timeout = timeout;
        _url = requestUrl;
    }
    return self;
}

- (HJResponseSerializerType)responseSerializerType {
    return HJResponseSerializerTypeHTTP;
}

- (NSTimeInterval)requestTimeoutInterval {
    return _timeout;
}

- (NSString *)requestUrl {
    return _url;
}

- (NSString *)resumableDownloadPath {
//    NSString *filePath = [[self.class saveBasePath] stringByAppendingPathComponent:@"downloaded.bin"]; // full path
    NSString *filePath = [self.class saveBasePath]; // directory
    return filePath;
}

+ (NSString *)saveBasePath {
    NSString *pathOfLibrary = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *path = [pathOfLibrary stringByAppendingPathComponent:@"TestResumableDownload"];
    return path;
}

@end
