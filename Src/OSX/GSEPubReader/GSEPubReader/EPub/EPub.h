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

@property (readonly, nonatomic) NSString *path;

@property (readonly, nonatomic) NSDictionary *metadata;

@end


#pragma mark - Entities

@interface ManifestItem : NSObject

@property (strong, nonatomic) NSString *href;
@property (strong, nonatomic) NSString *itemId;
@property (strong, nonatomic) NSString *mediaType;

@end


@interface GuideItem : NSObject

@property (strong, nonatomic) NSString *href;
@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) NSString *type;

@end
