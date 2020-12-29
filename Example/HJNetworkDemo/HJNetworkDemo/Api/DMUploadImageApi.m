//
//  DMUploadImageApi.m
//  HJNetworkDemo
//
//  Created by navy on 2020/12/29.
//

#import "DMUploadImageApi.h"

@implementation DMUploadImageApi {
    UIImage *_image;
    NSString *_name;
}

- (id)initWithName:(NSString *)name image:(UIImage *)image {
    self = [super init];
    if (self) {
        _image = image;
        _name = name;
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
    return @"/iphone/image/upload";
}

- (AFConstructingBlock)constructingBodyBlock {
    return ^(id<AFMultipartFormData> formData) {
        NSData *data = UIImageJPEGRepresentation(self->_image, 0.9);
        NSString *name = @"image";
        NSString *formKey = @"image";
        NSString *type = @"image/jpeg";
        [formData appendPartWithFileData:data name:formKey fileName:name mimeType:type];
    };
}

//- (AFConstructingBlock)constructingBodyBlock {
//    return ^(id<AFMultipartFormData> formData) {
//        [formData appendPartWithFormData:[@"photo" dataUsingEncoding:NSUTF8StringEncoding] name:@"app"];
//        [formData appendPartWithFormData:[@"json" dataUsingEncoding:NSUTF8StringEncoding] name:@"s"];
//        [formData appendPartWithFormData:[@"1" dataUsingEncoding:NSUTF8StringEncoding] name:@"p"];
//        [formData appendPartWithFormData:[@"1" dataUsingEncoding:NSUTF8StringEncoding] name:@"exif"];
//        [formData appendPartWithFormData:[@"asdf22qw000a9sd00fb0g0q9f09qwfr0qw9f39--dsf" dataUsingEncoding:NSUTF8StringEncoding] name:@"token"];
//
//        NSData *data = UIImageJPEGRepresentation(self->_image, 0.9);
//        NSString *fileName = [NSString stringWithFormat:@"%@.jpg",self->_name];
//        [formData appendPartWithFileData:data
//                                    name:@"pic1"
//                                fileName:fileName
//                                mimeType:@"image/jpeg"];
//    };
//}

- (id)jsonValidator {
    return @{ @"imageId": [NSString class] };
}

- (NSString *)responseImageId {
    NSDictionary *dict = self.responseJSONObject;
    return dict[@"imageId"];
}

@end
