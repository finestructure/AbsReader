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


- (void)test_parseGuid {
  [self parseTestXml];
  GHAssertNotNil(self.cache.stories, nil);
  NSString *guid = [[self.cache.stories objectAtIndex:0] objectForKey:@"guid"];
  GHAssertNotNil(guid, nil);
  GHAssertTrue([guid length] > 0, nil);
}

@end