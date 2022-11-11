//
//  HJUploadManager.h
//  HJNetworkDemo
//
//  Created by navy on 2023/1/3.
//

#import <Foundation/Foundation.h>
#import <HJNetwork/HJUpload.h>

NS_ASSUME_NONNULL_BEGIN

@interface HJUploadManager : NSObject

+ (HJUploadSourceKey)uploadWithAbsolutePath:(NSString *)path
                             uploadProgress:(void (^)(NSProgress * _Nullable progress))uploadProgress
                                 completion:(void (^)(NSDictionary<NSString *,id> * _Nullable callbackInfo, NSError * _Nullable error))completion;

+ (void)cancelSource:(HJUploadSourceKey)key;

@end

NS_ASSUME_NONNULL_END
