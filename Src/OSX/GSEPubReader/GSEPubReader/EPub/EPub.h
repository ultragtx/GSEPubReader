//
//  EPub.h
//  GSEPubReader
//
//  Created by Xinrong Guo on 13-6-8.
//  Copyright (c) 2013年 Xinrong Guo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EPub : NSObject

- (instancetype)initWithPath:(NSString *)path;

@property (strong, nonatomic) NSString *path;

@end
