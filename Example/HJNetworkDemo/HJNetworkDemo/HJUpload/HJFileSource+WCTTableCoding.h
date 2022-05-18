//
//  HJFileSource+WCTTableCoding.h
//  HJNetworkDemo
//
//  Created by navy on 2022/9/6.
//

#import "HJFileSource.h"
#import <WCDB/WCDB.h>

@interface HJFileSource (WCTTableCoding) <WCTTableCoding>

WCDB_PROPERTY(sourceId)
WCDB_PROPERTY(blocks)

@end
