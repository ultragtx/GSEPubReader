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
#import "FileMD5Hash.h"

@interface EPub ()

@property (strong, nonatomic) NSString *path;
@property (strong, nonatomic) NSString *cacheDirPath;
@property (strong, nonatomic) NSString *md5;
@property (strong, nonatomic) NSString *unarchivedPath;

@property (strong, nonatomic) NSString *opfPath;

@end

@implementation EPub

- (instancetype)initWithPath:(NSString *)path {
    self = [super init];
    if (self) {
        _path = path;
        [self prepare];
        [self parse];
    }
    return self;
}

#pragma mark - Prepare

- (void)prepare {
    [self prepareCachePath] && [self calculateMD5];
    
    _unarchivedPath = [_cacheDirPath stringByAppendingPathComponent:_md5];
    
    [self unarchive];
}

- (BOOL)prepareCachePath {
    BOOL success = YES;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *baseCachePath = [paths objectAtIndex:0];
    NSString *subEpubPath = [NSString stringWithFormat:@"%@/UnarchivedEPubs", [[NSBundle mainBundle] bundleIdentifier]];
    NSString *cacheDirPath = [baseCachePath stringByAppendingPathComponent:subEpubPath];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    if (![fileManager fileExistsAtPath:cacheDirPath]) {
        [fileManager createDirectoryAtPath:cacheDirPath withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            GSALog(@"[ERROR]: %@", [error description]);
            success = NO;
        }
    }
    _cacheDirPath = cacheDirPath;
    
    return success;
}

- (BOOL)calculateMD5 {
    BOOL success = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:_path]) {
        _md5 = [FileMD5Hash CalculateMD5ForFileWithPath:_path];
        success = YES;
    }
    return success;
}

- (BOOL)unarchive {
    BOOL success = NO;
    ZipArchive *zipArchive = [[ZipArchive alloc] init];
    
    if ([zipArchive UnzipOpenFile:_path] && [zipArchive UnzipFileTo:_unarchivedPath overWrite:YES]) {
        success = YES;
    }
    
    [zipArchive UnzipCloseFile];
    
    return success;
}

#pragma mark - Parse

- (void)parse {
    [self parseContainerXML];
}

- (BOOL)parseContainerXML {
    // Get the path of opf file
    BOOL success = NO;
    NSString *path = [_unarchivedPath stringByAppendingPathComponent:@"META-INF/container.xml"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:path]) {
        NSData *xmlData = [NSData dataWithContentsOfFile:path];
        NSError *error;
        GDataXMLDocument *doc = [[GDataXMLDocument alloc] initWithData:xmlData error:&error];
        if (!error) {
            GDataXMLNode *node = [doc firstNodeForXPath:@"//_def_ns:rootfile[@media-type='application/oebps-package+xml']/@full-path" error:&error];
            if (node) {
                _opfPath = [_unarchivedPath stringByAppendingPathComponent:[node stringValue]];
                success = YES;
            }
        }
        else {
            GSALog(@"[ERROR]: %@", [error description]);
        }
    }
    return success;
}

@end
