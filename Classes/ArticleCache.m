//
//  ArticleCache.m
//  AbsReader
//
//  Created by Sven A. Schmidt on 29.12.10.
//  Copyright 2010 abstracture GmbH & Co. KG. All rights reserved.
//

#import "ArticleCache.h"


@implementation ArticleCache

@synthesize cache;

- (id)init {
  self = [super init];
  if (self) {
    self.cache = [NSMutableDictionary dictionary];
  }
  return self;
}

@end
