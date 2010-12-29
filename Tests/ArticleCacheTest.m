#import <GHUnit/GHUnit.h>
#import "ArticleCache.h"

@interface ArticleCacheTest : GHTestCase { }
@property (nonatomic, retain) ArticleCache *cache;
@end



@implementation ArticleCacheTest

@synthesize cache;


- (void)setUp {
  self.cache = [[[ArticleCache alloc] init] autorelease];
}


- (void)test_init {  
  GHAssertNotNil(self.cache, nil);
}


- (void)test_parseXml {
  NSBundle *thisBundle = [NSBundle bundleForClass:[self class]];
  NSURL *url = [thisBundle URLForResource:@"rss_test" withExtension:@"xml"];
  GHAssertNotNil(url, nil);
  [self.cache parseXMLFileAtURL:url];
  GHAssertNotNil(self.cache.rssData, nil);
  GHAssertTrue([self.cache.rssData length] > 0, nil);
}


@end