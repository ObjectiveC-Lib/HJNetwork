//
//  HJFileBasic+WCTTableCoding.h
//  HJNetworkDemo
//
//  Created by navy on 2022/9/7.
//

#import "HJFileBasic.h"
#import <WCDB/WCDB.h>

@interface HJFileBasic (WCTTableCoding) <WCTTableCoding>

WCDB_PROPERTY(size)
WCDB_PROPERTY(status)

@end
