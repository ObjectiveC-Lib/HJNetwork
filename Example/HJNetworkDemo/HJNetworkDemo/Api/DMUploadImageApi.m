//
//  DMUploadImageApi.m
//  HJNetworkDemo
//
//  Created by navy on 2020/12/29.
//

#import "DMUploadImageApi.h"
#import "DMInlineHeader.h"

@interface DMUploadImageApi()
@property (nonatomic, copy, nullable) HJUploadProgressBlock myProgress;
@property (nonatomic, copy, nullable) HJUploadCompletionBlock myCompletion;
@end

@implementation DMUploadImageApi {
    UIImage *_image;
    NSString *_key;
}

- (id)initWithKey:(nullable NSString *)key image:(nullable UIImage *)image {
    self = [super init];
    if (self) {
        _image = image;
        _key = key;
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

//- (AFConstructingBlock)constructingBodyBlock {
//    return ^(id<AFMultipartFormData> formData) {
//        NSData *data = UIImageJPEGRepresentation(self->_image, 0.9);
//        NSString *name = @"image";
//        NSString *formKey = @"image";
//        NSString *type = @"image/jpeg";
//        [formData appendPartWithFileData:data name:formKey fileName:name mimeType:type];
//    };
//}

- (AFConstructingBlock)constructingBodyBlock {
    return ^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFormData:[@"photo" dataUsingEncoding:NSUTF8StringEncoding] name:@"app"];
        [formData appendPartWithFormData:[@"json" dataUsingEncoding:NSUTF8StringEncoding] name:@"s"];
        [formData appendPartWithFormData:[@"1" dataUsingEncoding:NSUTF8StringEncoding] name:@"p"];
        [formData appendPartWithFormData:[@"1" dataUsingEncoding:NSUTF8StringEncoding] name:@"exif"];
        [formData appendPartWithFormData:[@"asdf22qw000a9sd00fb0g0q9f09qwfr0qw9f39--dsf" dataUsingEncoding:NSUTF8StringEncoding] name:@"token"];
        
        NSData *data = UIImageJPEGRepresentation(self->_image, 0.9);
        NSString *fileName = [NSString stringWithFormat:@"%@.jpg",self->_key];
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

#pragma mark - HJUploadProtocol

- (HJUploadProgressBlock)progress {
    return self.uploadProgressBlock;
}

- (void)setProgress:(HJUploadProgressBlock)progress {
    self.myProgress = progress;
}

- (HJUploadCompletionBlock)completion {
    return self.myCompletion;
}

- (void)setCompletion:(HJUploadCompletionBlock)completion {
    self.myCompletion = completion;
}

- (void)uploadStart {
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
        
        if (self.completion) {
            self.completion(self->_key, HJUploadStageFinished, dict, nil);
        }
    } failure:^(__kindof HJBaseRequest * _Nonnull request) {
        __strong typeof(_self) self = _self;
        if (self.completion) {
            self.completion(self->_key, HJUploadStageFinished, nil, request.error);
        }
    }];
}

- (void)uploadCancel {
    [self stop];
}

@end
