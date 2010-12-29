//
//  ArticleCacheTest.m
//  AbsReader
//
//  Created by Sven A. Schmidt on 29.12.10.
//  Copyright 2010 abstracture GmbH & Co. KG. All rights reserved.
//

#import "ArticleCacheTest.h"
#import "ArticleCache.h"

@implementation ArticleCacheTest

- (void) test_init {
  ArticleCache *c = [[ArticleCache alloc] init];
  
  STAssertTrue(c, @"c is nil");
    
  [c release];
}


@end
