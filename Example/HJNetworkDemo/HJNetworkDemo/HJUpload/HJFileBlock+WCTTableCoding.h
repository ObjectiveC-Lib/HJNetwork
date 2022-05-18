//
//  HJFileBlock+WCTTableCoding.h
//  HJNetworkDemo
//
//  Created by navy on 2022/9/6.
//

#import "HJFileBlock.h"
#import <WCDB/WCDB.h>

@interface HJFileBlock (WCTTableCoding) <WCTTableCoding>

WCDB_PROPERTY(blockId)
WCDB_PROPERTY(name)
WCDB_PROPERTY(path)
WCDB_PROPERTY(absolutePath)
WCDB_PROPERTY(fileType)
WCDB_PROPERTY(dirType)
WCDB_PROPERTY(fragments)
WCDB_PROPERTY(source)

@end
