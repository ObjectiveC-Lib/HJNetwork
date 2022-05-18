//
//  HJFileFragment+WCTTableCoding.h
//  HJNetworkDemo
//
//  Created by navy on 2022/9/6.
//

#import "HJFileFragment.h"
#import <WCDB/WCDB.h>

@interface HJFileFragment (WCTTableCoding) <WCTTableCoding>

WCDB_PROPERTY(fragmentId)
WCDB_PROPERTY(index)
WCDB_PROPERTY(offset)
WCDB_PROPERTY(maxSize)
WCDB_PROPERTY(failureRetryCount)
WCDB_PROPERTY(block)

@end
