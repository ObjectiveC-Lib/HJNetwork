//
//  UIImageView+DM.m
//
//
//  Created by navy on 2022/3/3.
//

#import "UIImageView+DM.h"
#import "objc/runtime.h"
#import "UIView+WebCacheOperation.h"
#import "UIView+WebCache.h"

@implementation UIImageView (DM)

- (void)dm_setImageWithURL:(nullable NSURL *)url {
    [self dm_setImageWithURL:url placeholderImage:nil options:0 progress:nil completed:nil];
}

- (void)dm_setImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder {
    [self dm_setImageWithURL:url placeholderImage:placeholder options:0 progress:nil completed:nil];
}

- (void)dm_setImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder options:(SDWebImageOptions)options {
    [self dm_setImageWithURL:url placeholderImage:placeholder options:options progress:nil completed:nil];
}

- (void)sd_setImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder options:(SDWebImageOptions)options context:(nullable SDWebImageContext *)context {
    SDWebImageMutableContext *tmpContext = @{ SDWebImageContextCustomManager : DMSDWebImageManager.sharedManager.imageManager }.mutableCopy;
    if (context && context.count) {
        [tmpContext addEntriesFromDictionary:context];
    }
    [self dm_setImageWithURL:url placeholderImage:placeholder options:options context:tmpContext progress:nil completed:nil];
}

- (void)dm_setImageWithURL:(nullable NSURL *)url completed:(nullable SDExternalCompletionBlock)completedBlock {
    [self dm_setImageWithURL:url placeholderImage:nil options:0 progress:nil completed:completedBlock];
}

- (void)dm_setImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder completed:(nullable SDExternalCompletionBlock)completedBlock {
    [self dm_setImageWithURL:url placeholderImage:placeholder options:0 progress:nil completed:completedBlock];
}

- (void)dm_setImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder options:(SDWebImageOptions)options completed:(nullable SDExternalCompletionBlock)completedBlock {
    [self dm_setImageWithURL:url placeholderImage:placeholder options:options progress:nil completed:completedBlock];
}

- (void)dm_setImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder options:(SDWebImageOptions)options progress:(nullable SDImageLoaderProgressBlock)progressBlock completed:(nullable SDExternalCompletionBlock)completedBlock {
    SDWebImageContext *context = @{ SDWebImageContextCustomManager : DMSDWebImageManager.sharedManager.imageManager };
    [self dm_setImageWithURL:url placeholderImage:placeholder options:options context:context progress:progressBlock completed:completedBlock];
}

- (void)dm_setImageWithURL:(nullable NSURL *)url
          placeholderImage:(nullable UIImage *)placeholder
                   options:(SDWebImageOptions)options
                   context:(nullable SDWebImageContext *)context
                  progress:(nullable SDImageLoaderProgressBlock)progressBlock
                 completed:(nullable SDExternalCompletionBlock)completedBlock {
    [self sd_internalSetImageWithURL:url
                    placeholderImage:placeholder
                             options:options
                             context:context
                       setImageBlock:nil
                            progress:progressBlock
                           completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
        if (completedBlock) {
            completedBlock(image, error, cacheType, imageURL);
        }
    }];
}

@end
