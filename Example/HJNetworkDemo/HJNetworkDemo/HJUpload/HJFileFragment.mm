//
//  HJFileFragment.m
//  HJNetworkDemo
//
//  Created by navy on 2022/9/2.
//

#import "HJFileFragment.h"
#import <WCDB/WCDB.h>
#import "HJFileBlock.h"
#import "HJFileManager.h"

@implementation HJFileFragment

WCDB_IMPLEMENTATION(HJFileFragment)

WCDB_SYNTHESIZE(HJFileFragment, fragmentId)
WCDB_SYNTHESIZE(HJFileFragment, index)
WCDB_SYNTHESIZE(HJFileFragment, offset)
WCDB_SYNTHESIZE(HJFileFragment, maxSize)
WCDB_SYNTHESIZE(HJFileFragment, failureRetryCount)
WCDB_SYNTHESIZE(HJFileFragment, block)

WCDB_INDEX(HJFileFragment, "index", index)

/// 获取片Data
- (NSData *)fetchFragmentData {
    NSData *data = nil;
    NSString *absolutePath = self.block.absolutePath;
    if ([[NSFileManager defaultManager] fileExistsAtPath:absolutePath]) {
        NSFileHandle *readHandle = [NSFileHandle fileHandleForReadingAtPath:absolutePath];
        [readHandle seekToFileOffset:self.offset];
        data = [readHandle readDataOfLength:self.size];
        [readHandle closeFile];
    }
    
    return data;
}

@end
