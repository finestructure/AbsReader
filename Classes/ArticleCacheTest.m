//
//  ArticleCacheTest.m
//  AbsReader
//
//  Created by Sven A. Schmidt on 29.12.10.
//  Copyright 2010 abstracture GmbH & Co. KG. All rights reserved.
//

#import "ArticleCacheTest.h"

@implementation ArticleCacheTest

@synthesize cache;


- (void)setUp {
  self.cache = [[[ArticleCache alloc] init] autorelease];
}


- (void)test_init {  
  STAssertTrue(self.cache != nil, @"cache is nil");
}


- (void)test_parseXml {
  NSBundle *thisBundle = [NSBundle bundleForClass:[self class]];
  NSURL *url = [thisBundle URLForResource:@"rss_test" withExtension:@"xml"];
  STAssertTrue(url != nil, @"url is nil");
  [self.cache parseXMLFileAtURL:url];
  STAssertTrue(self.cache.rssData != nil, @"rssDate is nil");
  while (self.cache.refreshInProgress) {
    usleep(500);
    [[NSRunLoop currentRunLoop] run];
  }
  STAssertTrue([self.cache.rssData length] > 0, @"rssDate length is 0");
}


@end
