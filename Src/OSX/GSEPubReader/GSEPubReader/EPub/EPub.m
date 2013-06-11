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
@property (strong, nonatomic) NSString *opfBasePath;
@property (strong, nonatomic) NSString *tocNcxPath;

@property (strong, nonatomic) NSDictionary *metadata;
@property (strong, nonatomic) NSDictionary *manifest;
@property (strong, nonatomic) NSArray *spine;
@property (strong, nonatomic) NSDictionary *reference;

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
    [self parseContainerXML] && [self parseOPF] && [self parseTocNcx];
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
            // The "_def_ns" is default namespace defined in GDataXMLNode
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

- (BOOL)parseOPF {
    BOOL success = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:_opfPath]) {
        NSData *xmlData = [NSData dataWithContentsOfFile:_opfPath];
        NSError *error;
        GDataXMLDocument *doc = [[GDataXMLDocument alloc] initWithData:xmlData error:&error];
        if (!error) {
            
            // Metadata
            // The "_def_ns" is default namespace defined in GDataXMLNode
            GDataXMLNode *metadataNode = [doc firstNodeForXPath:@"//_def_ns:metadata" error:&error];
            if (metadataNode) {
                NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:metadataNode.childCount];
                for (GDataXMLNode *node in [metadataNode children]) {
                    NSLog(@"%@| %@| %@", node.name, node.prefix, node.stringValue);
                    if ([[node.name substringWithRange:NSMakeRange(0, 3)] isEqualToString:@"dc:"]) {
                        [dict setValue:node.stringValue forKey:node.name];
                    }
                    else if ([node.name isEqualToString:@"meta"]) {
                        GDataXMLNode *nameAttr = [node firstNodeForXPath:@"@name" error:&error];
                        GDataXMLNode *contentAttr = [node firstNodeForXPath:@"@content" error:&error];
                        if (nameAttr) {
                            [dict setValue:contentAttr.stringValue forKey:nameAttr.stringValue];
                        }
                    }
                }
                _metadata = [NSDictionary dictionaryWithDictionary:dict];
            }
            
            
            // Manifest
            GDataXMLNode *manifestNode = [doc firstNodeForXPath:@"//_def_ns:manifest" error:&error];
            if (manifestNode) {
                NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:manifestNode.childCount];
                for (GDataXMLNode *node in [manifestNode children]) {
                    GDataXMLNode *idAttr = [node firstNodeForXPath:@"@id" error:&error];
                    GDataXMLNode *hrefAttr = [node firstNodeForXPath:@"@href" error:&error];
                    // !!!: Did not use media-type
                    if (idAttr && hrefAttr) {
                        [dict setValue:hrefAttr.stringValue forKey:idAttr.stringValue];
                    }
                }
                _manifest = [NSDictionary dictionaryWithDictionary:dict];
            }
            
            // Spine
            GDataXMLNode *spineNode = [doc firstNodeForXPath:@"//_def_ns:spine" error:&error];
            if (spineNode) {
                NSMutableArray *arr = [NSMutableArray arrayWithCapacity:spineNode.childCount];
                for (GDataXMLNode *node in spineNode.children) {
                    GDataXMLNode *idrefAttr = [node firstNodeForXPath:@"@idref" error:&error];
                    if (idrefAttr) {
                        [arr addObject:idrefAttr.stringValue];
                    }
                }
                _spine = [NSArray arrayWithArray:arr];
            }
        
            // Guide
            GDataXMLNode *guideNode = [doc firstNodeForXPath:@"//_def_ns:guide" error:&error];
            if (spineNode) {
                
                for (GDataXMLNode *node in guideNode.children) {
                    
                }
            }
            success = YES;
        }
        else {
            GSALog(@"[ERROR]: %@", [error description]);
        }
    }
    return success;
}

- (BOOL)parseTocNcx {
    BOOL success = NO;
    
    NSString *tocSubPath = [_manifest objectForKey:@"ncx"];
    if (tocSubPath) {
        NSInteger slashLoc = [_opfPath rangeOfString:@"/" options:NSBackwardsSearch].location;
        _opfBasePath = [_opfPath substringToIndex:slashLoc];
        _tocNcxPath = [_opfBasePath stringByAppendingPathComponent:tocSubPath];
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:_tocNcxPath]) {
            NSData *xmlData = [NSData dataWithContentsOfFile:_tocNcxPath];
            NSError *error;
            GDataXMLDocument *doc = [[GDataXMLDocument alloc] initWithData:xmlData error:&error];
            if (!error) {
                
            }
            else {
                GSALog(@"[ERROR]: %@", [error description]);
            }
        }
        
    }
    
    
    return success;
}

@end
