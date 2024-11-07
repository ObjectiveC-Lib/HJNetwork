//
//  HJUploadInputStream.h
//  HJNetwork
//
//  Created by navy on 2022/9/7.
//  Copyright © 2022 HJNetwork. All rights reserved.
//

#import "HJUploadInputStream.h"
#import <CommonCrypto/CommonDigest.h>
#import "HJUploadFileFragment.h"
#import "HJUploadFileBlock.h"

@interface NSStream ()
@property (readwrite) NSStreamStatus streamStatus;
@property (readwrite, copy) NSError *streamError;
@end

@interface HJUploadInputStream () <NSStreamDelegate> {
}
@property (nonatomic, assign) unsigned long long offset;
@property (nonatomic, strong) NSData *overflowData;
@end

@implementation HJUploadInputStream {
    CC_MD5_CTX _MD5_CTX;
    HJUploadFileFragment * __weak _fragment;
}
#if (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000) || (defined(__MAC_OS_X_VERSION_MAX_ALLOWED) && __MAC_OS_X_VERSION_MAX_ALLOWED >= 1100)
@synthesize delegate;
#endif
@synthesize streamStatus;
@synthesize streamError;

- (void)dealloc {
    // NSLog(@"HJUpload_InputStream_dealloc");
}

- (instancetype)initWithFragment:(nullable HJUploadFileFragment *)fragment {
    self = [super init];
    if (self) {
        _fragment = fragment;
        self.delegate = self;
    }
    return self;
}

#pragma mark - NSStream

- (void)open {
    if (self.streamStatus != NSStreamStatusOpen) {
        self.offset = 0;
        CC_MD5_Init(&_MD5_CTX);
    }
    self.streamStatus = NSStreamStatusOpen;
}

- (void)close {
    if (self.streamStatus == NSStreamStatusAtEnd) {
        unsigned char digest[CC_MD5_DIGEST_LENGTH];
        CC_MD5_Final(digest, &_MD5_CTX);
        char hash[2 * sizeof(digest) + 1];
        for (size_t i = 0; i < sizeof(digest); ++i) {
            snprintf(hash + (2 * i), 3, "%02x", (int)(digest[i]));
        }
        CFStringRef md5HashResult = CFStringCreateWithCString(kCFAllocatorDefault, (const char *)hash, kCFStringEncodingUTF8);
        NSString *md5 = (__bridge_transfer NSString *)md5HashResult;
        if (_fragment.cryptoEnable) {
            _fragment.cryptoMD5 = md5;
            if (_fragment.isSingle) {
                _fragment.block.cryptoMD5 = md5;
            }
        } else {
            _fragment.MD5 = md5;
        }
        md5HashResult = NULL;
    }
    self.streamStatus = NSStreamStatusClosed;
}

- (id)propertyForKey:(NSString *)key {
    return nil;
}

- (BOOL)setProperty:(id)property forKey:(NSString *)key {
    return NO;
}

- (void)scheduleInRunLoop:(NSRunLoop *)aRunLoop forMode:(NSString *)mode {
}

- (void)removeFromRunLoop:(NSRunLoop *)aRunLoop forMode:(NSString *)mode {
}

#pragma mark - NSInputStream

//- (NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)len {
//    if (self.offset >= _fragment.size) {
//        self.streamStatus = NSStreamStatusAtEnd;
//        return 0;
//    }
//    
//    NSInteger read = 0;
//    NSInteger readRemaining = len;
//    while ((readRemaining > 0) && (self.offset < _fragment.size)) {
//        NSInteger dataRemaining = (_fragment.size - self.offset);
//        NSInteger dataFetch = MIN(readRemaining, dataRemaining);
//        NSData *data = [_fragment fetchData:dataFetch offset:self.offset];
//        NSInteger dataLength = data.length;
//        if (!data || dataLength <= 0) return -1;
//        self.offset += data.length;
//        
//        CC_MD5_Update(&_MD5_CTX, data.bytes, (CC_LONG)data.length);
//        NSRange range = NSMakeRange(0, dataLength);
//        [data getBytes:(buffer + read) range:range];
//        read += dataLength;
//        readRemaining -= dataLength;
//    }
//    return read;
//}

- (NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)len {
    if (!self.overflowData && self.offset >= _fragment.size) {
        self.streamStatus = NSStreamStatusAtEnd;
        return 0;
    }
    
    NSMutableData *cryptoData = [NSMutableData new];
    if (self.overflowData) {
        [cryptoData appendData:self.overflowData];
        self.overflowData = nil;
    }
    
    NSInteger readRemaining = len;
    while ((cryptoData.length < readRemaining) && (self.offset < _fragment.size)) {
        NSInteger dataRemaining = (_fragment.size - self.offset);
        NSInteger dataFetch = MIN(_fragment.bufferSize, dataRemaining);
        NSData *data = [_fragment fetchData:dataFetch offset:self.offset];
        NSInteger dataLength = data.length;
        if (!data || dataLength <= 0) return -1;
        self.offset += data.length;
        if (_fragment.cryptoEnable) {
            data = [_fragment cryptoData:data];
        }
        [cryptoData appendData:data];
    }
    
    NSInteger cryptoLength = cryptoData.length;
    NSInteger copyLength = MIN(readRemaining, cryptoLength);
    NSData *copyData = [cryptoData subdataWithRange:NSMakeRange(0, copyLength)];
    [copyData getBytes:buffer range:NSMakeRange(0, copyData.length)];
    copyLength = copyData.length;
    CC_MD5_Update(&_MD5_CTX, copyData.bytes, (CC_LONG)copyLength);
    if (copyLength < cryptoLength) {
        self.overflowData = [cryptoData subdataWithRange:NSMakeRange(copyLength, cryptoLength - copyLength)];
    }
    
    return copyLength;
}

- (BOOL)getBuffer:(uint8_t * _Nullable * _Nonnull)buffer length:(NSUInteger *)len {
    return NO;
}

- (BOOL)hasBytesAvailable {
    if (self.offset < _fragment.size) return YES;
    return NO;
}

#pragma mark - NSStreamDelegate

- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent {
    [self stream:self handleEvent:streamEvent];
}

@end
