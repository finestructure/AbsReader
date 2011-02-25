#import <GHUnit/GHUnit.h>
#import "FeedCache.h"

@interface FeedCacheTest : GHAsyncTestCase { }
@property (nonatomic, retain) FeedCache *feed;
@end



@implementation FeedCacheTest

@synthesize feed;


- (void)setUp {
  self.feed = [[[FeedCache alloc] init] autorelease];
}


#pragma mark - Helpers


- (void)checkProgress_test_parseXml {
  if (self.feed.refreshInProgress == NO) {
    [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(test_parseXml)];
  } else {
    [self performSelector:@selector(checkProgress_test_parseXml) withObject:nil afterDelay:0.1];
  }
}


- (void)parseTestXml {
  NSBundle *thisBundle = [NSBundle bundleForClass:[self class]];
  NSURL *url = [thisBundle URLForResource:@"rss_test" withExtension:@"xml"];
  GHAssertNotNil(url, nil);
  
  self.feed.url = url;
  [self.feed refresh];

  NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:0.1];
  NSDate *timeOut = [NSDate dateWithTimeIntervalSinceNow:1];
  while (self.feed.refreshInProgress 
         && [timeOut compare:[NSDate date]] == NSOrderedDescending
         && [[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode beforeDate:loopUntil]) {
    loopUntil = [NSDate dateWithTimeIntervalSinceNow:0.1];
  }
}


#pragma mark - Tests


- (void)test_init {  
  GHAssertNotNil(self.feed, nil);
}


- (void)test_parseXml {
  NSBundle *thisBundle = [NSBundle bundleForClass:[self class]];
  NSURL *url = [thisBundle URLForResource:@"rss_test" withExtension:@"xml"];
  GHAssertNotNil(url, nil);
  
  [self prepare];
  self.feed.url = url;
  [self.feed refresh];
  [self checkProgress_test_parseXml];
  [self waitForStatus:kGHUnitWaitStatusSuccess timeout:1.0];
  
  GHAssertNotNil(self.feed.rssData, nil);
  GHAssertEquals((int)[self.feed.rssData length], 30448, nil);
  GHAssertEquals((int)[self.feed.stories count], 50, nil);
}


- (void)test_xmlContent {
  [self parseTestXml];
  GHAssertNotNil(self.feed.stories, nil);
  // test string values
  NSArray *tags = [NSArray arrayWithObjects:@"title", @"dc:creator", @"description", nil];
  for (NSString *tag in tags) {
    NSString *value = [[self.feed.stories objectAtIndex:0] objectForKey:tag];
    GHAssertNotNil(value, @"value for %@ is nil", tag);
    GHAssertTrue([value isKindOfClass:[NSString class]], @"requiring NSString for %@", tag);
    GHAssertTrue([value length] > 0, @"length for %@ is 0", tag);
  }
  // test date value
  NSDate *date = [[self.feed.stories objectAtIndex:0] objectForKey:@"pubDate"];
  GHAssertTrue([date isKindOfClass:[NSDate class]], @"requiring NSDate");
}

@end
