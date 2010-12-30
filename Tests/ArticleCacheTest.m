#import <GHUnit/GHUnit.h>
#import "ArticleCache.h"

@interface ArticleCacheTest : GHAsyncTestCase { }
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


- (void)checkProgress {
  if (self.cache.refreshInProgress == NO) {
    [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(test_parseXml)];
  } else {
    [self performSelector:@selector(checkProgress) withObject:nil afterDelay:0.1];
  }
}


- (void)test_parseXml {
  NSBundle *thisBundle = [NSBundle bundleForClass:[self class]];
  NSURL *url = [thisBundle URLForResource:@"rss_test" withExtension:@"xml"];
  GHAssertNotNil(url, nil);

  [self prepare];
  [self.cache parseXMLFileAtURL:url];
  [self checkProgress];
  [self waitForStatus:kGHUnitWaitStatusSuccess timeout:1.0];
  
  GHAssertNotNil(self.cache.rssData, nil);
  GHAssertEquals((int)[self.cache.rssData length], 30448, nil);
  GHAssertEquals((int)[self.cache.stories count], 50, nil);
}


- (void)parseTestXml {
  NSBundle *thisBundle = [NSBundle bundleForClass:[self class]];
  NSURL *url = [thisBundle URLForResource:@"rss_test" withExtension:@"xml"];
  GHAssertNotNil(url, nil);
  
  [self.cache parseXMLFileAtURL:url];

  NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:0.1];
  NSDate *timeOut = [NSDate dateWithTimeIntervalSinceNow:1];
  while (self.cache.refreshInProgress 
         && [timeOut compare:[NSDate date]] == NSOrderedDescending
         && [[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode beforeDate:loopUntil]) {
    loopUntil = [NSDate dateWithTimeIntervalSinceNow:0.1];
  }
}


- (void)test_xmlContent {
  [self parseTestXml];
  GHAssertNotNil(self.cache.stories, nil);
  NSArray *tags = [NSArray arrayWithObjects:@"title", @"dc:creator", @"pubDate", @"description", nil];
  for (NSString *tag in tags) {
    NSString *value = [[self.cache.stories objectAtIndex:0] objectForKey:tag];
    GHAssertNotNil(value, @"value for %@ is nil", tag);
    GHAssertTrue([value length] > 0, @"length for %@ is 0", tag);
  }
}

@end