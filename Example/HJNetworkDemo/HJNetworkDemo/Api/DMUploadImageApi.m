//
//  DMUploadImageApi.m
//  HJNetworkDemo
//
//  Created by navy on 2020/12/29.
//

#import "DMUploadImageApi.h"
#import "DMInlineHeader.h"
#import <HJTask/HJTask.h>

@interface DMUploadImageApi()

@end

@implementation DMUploadImageApi {
    UIImage *_image;
}

- (id)initWithImage:(nullable UIImage *)image {
    self = [super init];
    if (self) {
        _image = image;
    }
    return self;
}

- (HJRequestMethod)requestMethod {
    return HJRequestMethodPOST;
}

- (NSString *)acceptableContentType {
    return @"text/html";
}

- (NSString *)requestUrl {
    return @"http://upload.photo.sina.com.cn/interface/pic_upload.php";
}

- (AFConstructingBlock)constructingBodyBlock {
    return ^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFormData:[@"photo" dataUsingEncoding:NSUTF8StringEncoding] name:@"app"];
        [formData appendPartWithFormData:[@"json" dataUsingEncoding:NSUTF8StringEncoding] name:@"s"];
        [formData appendPartWithFormData:[@"1" dataUsingEncoding:NSUTF8StringEncoding] name:@"p"];
        [formData appendPartWithFormData:[@"1" dataUsingEncoding:NSUTF8StringEncoding] name:@"exif"];
        [formData appendPartWithFormData:[@"asdf22qw000a9sd00fb0g0q9f09qwfr0qw9f39--dsf" dataUsingEncoding:NSUTF8StringEncoding] name:@"token"];
        
        NSData *data = UIImageJPEGRepresentation(self->_image, 0.9);
        NSString *fileName = [NSString stringWithFormat:@"%@.jpg", self.taskKey];
        [formData appendPartWithFileData:data
                                    name:@"pic1"
                                fileName:fileName
                                mimeType:@"image/jpeg"];
    };
}

- (BOOL)customCodeValidator {
    NSString *statusCode = [NSString stringWithFormat:@"%@", self.responseJSONObject[@"code"]];
    NSString *resultCode = @"0";
    NSDictionary *tmpDict = self.responseJSONObject[@"data"][@"pics"];
    if (DMNSDictionaryAvailable(tmpDict)) {
        resultCode = [NSString stringWithFormat:@"%@", tmpDict[@"pic_1"][@"ret"]];
    }
    return DMNSStringIsEqual(statusCode, @"A00006") && DMNSStringIsEqual(resultCode, @"1");
}

#pragma mark - HJTaskProtocol

- (void)startTask {
    __weak typeof(self) _self = self;
    [self startWithCompletionBlockWithSuccess:^(__kindof HJBaseRequest * _Nonnull request) {
        __strong typeof(_self) self = _self;
        
        NSMutableDictionary *dict;
        NSDictionary *tmpDict = request.responseJSONObject[@"data"][@"pics"];
        if (DMNSDictionaryAvailable(tmpDict)) {
            dict = [NSMutableDictionary dictionaryWithDictionary:tmpDict[@"pic_1"]];
        }
        if (DMNSDictionaryAvailable(dict)) {
            dict[@"imgUrl"] = [NSString stringWithFormat:@"http://s8.sinaimg.cn/middle/%@", DMSafeNSString(dict[@"pid"])];
        }
        
        if (self.taskResult) {
            self.taskResult(HJTaskStageFinished, dict, nil);
        }
    } failure:^(__kindof HJBaseRequest * _Nonnull request) {
        __strong typeof(_self) self = _self;
        if (self.taskResult) {
            self.taskResult(HJTaskStageFinished, nil, request.error);
        }
    }];
}

- (void)cancelTask {
    [self stop];
}

@end
