//
//  HJUploadDefine.h
//  Pods
//
//  Created by navy on 2021/1/4.
//

#ifndef HJUploadDefine_h
#define HJUploadDefine_h

typedef NS_OPTIONS(NSUInteger, HJUploadCachesType) {
    HJUploadCachesTypeMemory  = 1 << 1,
    HJUploadCachesTypeDisk    = 1 << 2,
    HJUploadCachesTypeAll     = HJUploadCachesTypeMemory | HJUploadCachesTypeDisk,
};

#endif /* HJUploadDefine_h */
