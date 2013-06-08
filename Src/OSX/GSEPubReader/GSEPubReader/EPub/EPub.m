//
//  EPub.m
//  GSEPubReader
//
//  Created by Xinrong Guo on 13-6-8.
//  Copyright (c) 2013年 Xinrong Guo. All rights reserved.
//

#import "EPub.h"
#import "GSLogUtils.h"
#import <ZipArchive.h>
#import <GDataXMLNode.h>

@interface EPub ()

@end

@implementation EPub

- (instancetype)initWithPath:(NSString *)path {
    self = [super init];
    if (self) {
        _path = path;
    }
    return self;
}

- (void)unArchieveToPath:(NSString *)destPath {
    ZipArchive *zipArchive = [[ZipArchive alloc] init];
    
    if ([zipArchive UnzipOpenFile:_path]) {
        if (![zipArchive UnzipFileTo:destPath overWrite:YES]) {
            GSALog(@"Failed unzip")
        }
    }
    else {
        GSALog(@"Faild open file");
    }
    [zipArchive UnzipCloseFile];
}

- (void)

@end
