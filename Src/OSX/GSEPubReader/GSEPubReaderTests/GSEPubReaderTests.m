//
//  GSEPubReaderTests.m
//  GSEPubReaderTests
//
//  Created by Xinrong Guo on 13-5-29.
//  Copyright (c) 2013年 Xinrong Guo. All rights reserved.
//

#import "GSEPubReaderTests.h"
#import "EPub.h"

@implementation GSEPubReaderTests

- (void)setUp {
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown {
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testEPub {
    EPub *ep = [[EPub alloc] initWithPath:@"/Users/ultragtx/Desktop/GSEPubReader/SampleEPub/1.epub"];
    NSString *unarchivedPath = [ep performSelector:@selector(unarchivedPath)];
    NSFileManager *manager = [NSFileManager defaultManager];
    STAssertTrue([manager fileExistsAtPath:unarchivedPath], @"Failed initializing epub file");
}

@end
