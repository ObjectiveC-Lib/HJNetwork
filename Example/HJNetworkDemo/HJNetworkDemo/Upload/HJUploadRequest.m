//
//  HJUploadRequest.m
//  HJNetworkDemo
//
//  Created by navy on 2022/9/6.
//

#import "HJUploadRequest.h"

@implementation HJUploadRequest {
    HJUploadFileFragment * _fragment;
    HJUploadInputStream * _inputStream;
}

- (void)dealloc {
    NSLog(@"HJUploadRequest_dealloc");
}

- (instancetype)initWithFragment:(nullable HJUploadFileFragment *)fragment {
    self = [super init];
    if (self) {
        _fragment = fragment;
        if (_fragment.block.config.formType == HJUploadFormTypeStream) {
            _inputStream = [[HJUploadInputStream alloc] initWithFragment:fragment];
        }
    }
    return self;
}

- (HJRequestMethod)requestMethod {
    return HJRequestMethodPOST;
}

- (NSString *)requestUrl {
    return @"anything";
}

- (AFConstructingBlock)constructingBodyBlock {
    return ^(id<AFMultipartFormData> formData) {
        NSString *name = self->_fragment.block.name;
        if (self->_fragment.block.config.formType == HJUploadFormTypeURL) {
            NSError *error = nil;
            NSURL *URL = self->_fragment.block.absolutePathURL;
            [formData appendPartWithFileURL:URL
                                       name:name
                                   fileName:name
                                   mimeType:HJUploadContentTypeForPathExtension(self->_fragment.block.absolutePath)
                                      error:&error];
            if (error) {
                NSLog(@"appendPartWithFileURL_error = %@", error);
            }
        } else if (self->_fragment.block.config.formType == HJUploadFormTypeStream) {
            [formData appendPartWithInputStream:self->_inputStream
                                           name:name
                                       fileName:name
                                         length:self->_fragment.cryptoEnable?self->_fragment.cryptoSize:self->_fragment.size
                                       mimeType:HJUploadContentTypeForPathExtension(self->_fragment.block.absolutePath)];
        } else {
            NSData *data = [self->_fragment fetchData];
            [formData appendPartWithFileData:data
                                        name:name
                                    fileName:name
                                    mimeType:HJUploadContentTypeForPathExtension(self->_fragment.block.absolutePath)];
        }
    };
}

- (BOOL)debugLogEnabled {
    return YES;
}

@end
