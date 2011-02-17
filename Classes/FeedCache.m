//
//  ArticleCache.m
//  AbsReader
//
//  Created by Sven A. Schmidt on 29.12.10.
//  Copyright 2010 abstracture GmbH & Co. KG. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "FeedCache.h"


@implementation FeedCache

@synthesize delegate;

@synthesize title;
@synthesize url;
@synthesize urlString;
@synthesize username;
@synthesize password;

@synthesize cache;
@synthesize stories;
@synthesize rssParser;
@synthesize item;
@synthesize currentValue;
@synthesize rssData;
@synthesize recordCharacters;
@synthesize lastRefresh;
@synthesize refreshInProgress;
@synthesize readArticles;


#pragma mark - Init


- (id)init {
  self = [super init];
  if (self) {
    [self setup];
  }
  return self;
}


- (void)setup {
  self.cache = [NSMutableDictionary dictionary];
  
  if (self.readArticles == nil) {
    self.readArticles = [NSMutableDictionary dictionary];
  } else {
    // delete entries older than 90 days from cache
    NSMutableArray *keysToRemove = [NSMutableArray array];
    float nintyDays = 86400*90;
    NSDate *earliestDate = [NSDate dateWithTimeIntervalSinceNow:nintyDays];
    [self.readArticles enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
      if ([(NSDate *)obj compare:earliestDate] == NSOrderedDescending) {
        [keysToRemove addObject:key];
      }
    }];
    [self.readArticles removeObjectsForKeys:keysToRemove];
  }
}


#pragma mark - Workers


// Keep track of the date (pubdate of the article) as well as the guid
// in order to be able to limit the list size to a certain depth.
// Otherwise the list of read article guids would grow indefinitely.
- (void)markGuidRead:(NSString *)guid forDate:(NSDate *)date {
  [self.readArticles setObject:date forKey:guid];
  [self saveToUserDefaults];
}


- (void)markAllRead {
  for (NSDictionary *story in self.stories) {
    NSString *guid = [story objectForKey:@"guid"];
    NSDate *pubDate = [story objectForKey:@"pubDate"];
    [self.readArticles setObject:pubDate forKey:guid];
  }
  [self saveToUserDefaults];
}


- (BOOL)alreadyVisited:(NSString *)guid {
  return [self.readArticles objectForKey:guid] != nil;
}


- (NSUInteger)unreadCount {
  NSMutableSet *guids = [NSMutableSet set];
  [stories enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    [guids addObject:[(NSDictionary *)obj objectForKey:@"guid"]];
  }];
  [guids minusSet:[NSSet setWithArray:[self.readArticles allKeys]]];
  return [guids count];
}


- (void)saveToUserDefaults {
  NSDictionary *defaultFeeds = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"Feeds"];
  NSMutableDictionary *feedsUpdate = [NSMutableDictionary dictionaryWithDictionary:defaultFeeds];
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self];
  [feedsUpdate setObject:data forKey:self.urlString];
  [[NSUserDefaults standardUserDefaults] setObject:feedsUpdate forKey:@"Feeds"];
}


#pragma mark - XML Parsing


- (void)refresh {	
  self.refreshInProgress = YES;
  self.rssData = [NSMutableData data];
  self.stories = [NSMutableArray array];
  NSURLRequest *request = [NSURLRequest requestWithURL:self.url];
  [[[NSURLConnection alloc] initWithRequest:request delegate:self] autorelease];
}



- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
  self.refreshInProgress = NO;
  [self.delegate errorOccurred:parseError];
}


- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict{			
  self.currentValue = [NSMutableString string];
  self.recordCharacters = YES;
	if ([elementName isEqualToString:@"item"]) {
		self.item = [NSMutableDictionary dictionary];
  } else {
    [self.item setObject:self.currentValue forKey:elementName];
  }
}


- (NSString *)trimWhitespace:(NSString *)string {
  static NSCharacterSet *whitespace = nil;
  if (whitespace == nil) {
    whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
  }
  return [string stringByTrimmingCharactersInSet:whitespace];
}


- (NSString *)flattenHTML:(NSString *)html {
  NSScanner *scanner = [NSScanner scannerWithString:html];
  NSString *temp = nil;
  
  while ([scanner isAtEnd] == NO) {
    [scanner scanUpToString:@"<" intoString:nil];
    [scanner scanUpToString:@">" intoString:&temp];
    html = [html stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@>", temp] withString:@""];
  }  
  return [self trimWhitespace:html];
}


- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName{     
	if ([elementName isEqualToString:@"item"]) {
    [self.stories addObject:self.item];
    NSDictionary *info = [NSDictionary dictionaryWithObject:self.item forKey:@"article"];
    [[NSNotificationCenter defaultCenter] postNotificationName:kArticleLoaded object:self userInfo:info];
  } else if ([elementName isEqualToString:@"description"]) {
    [self.item setObject:[self flattenHTML:self.currentValue] forKey:elementName];
	} else if ([elementName isEqualToString:@"pubDate"]) {
    static NSDateFormatter *formatter = nil;
    if (formatter == nil) {
      formatter = [[NSDateFormatter alloc] init];
      NSLocale *enUS = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
      [formatter setLocale:enUS];
      [enUS release];
      [formatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss z"];
    }
    NSDate *date = [formatter dateFromString:self.currentValue];
    [self.item setObject:date forKey:@"pubDate"];
  }
  self.recordCharacters = NO;
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string{
  if (self.recordCharacters == NO) {
    return;
  }
  [self.currentValue appendString:string];
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
  self.lastRefresh = [NSDate date];
  self.refreshInProgress = NO;
  [self.delegate didEndDocument];
  [[NSNotificationCenter defaultCenter] postNotificationName:kFeedLoaded object:self];
}


#pragma mark - NSURLConnectionDelegate


- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
  //NSLog(@"got auth challange");
  if ([challenge previousFailureCount] == 0) {
    if (self.username == nil || [[self username] isEqualToString:@""] || self.password == nil) {
      NSString *msg = [NSString stringWithFormat:@"Feed '%@' requires authentication but credentials are not fully provided. Please enter them in the feed settings.", self.title];
      UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Login required" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
      [alert show];
      [[challenge sender] cancelAuthenticationChallenge:challenge];
    } else {
      [[challenge sender] useCredential:[NSURLCredential credentialWithUser:self.username password:self.password persistence:NSURLCredentialPersistencePermanent] forAuthenticationChallenge:challenge];
    }
  } else {
    [[challenge sender] cancelAuthenticationChallenge:challenge]; 
  }
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
  [self.rssData appendData:data];
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
  //NSLog(@"finished loading");
  rssParser = [[[NSXMLParser alloc] initWithData:self.rssData] autorelease];
  [rssParser setDelegate:self];
  [rssParser setShouldProcessNamespaces:NO];
  [rssParser setShouldReportNamespacePrefixes:NO];
  [rssParser setShouldResolveExternalEntities:NO];
  [rssParser parse];
}


- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
  self.refreshInProgress = NO;
  [self.delegate errorOccurred:error];
}


- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection {
  return NO;
}


#pragma - NSCoding


- (id)initWithCoder:(NSCoder *)decoder {
  self = [super init];
  if (self) {
    self.title = [decoder decodeObjectForKey:@"title"];
    self.url = [decoder decodeObjectForKey:@"url"];
    self.urlString = [decoder decodeObjectForKey:@"urlString"];
    self.username = [decoder decodeObjectForKey:@"username"];
    self.password = [decoder decodeObjectForKey:@"password"];
    self.readArticles = [decoder decodeObjectForKey:@"readArticles"];
    [self setup];
  }
  return self;
}


- (void)encodeWithCoder:(NSCoder *)encoder {
  [encoder encodeObject:self.title forKey:@"title"];
  [encoder encodeObject:self.url forKey:@"url"];
  [encoder encodeObject:self.urlString forKey:@"urlString"];
  [encoder encodeObject:self.username forKey:@"username"];
  [encoder encodeObject:self.password forKey:@"password"];
  [encoder encodeObject:self.readArticles forKey:@"readArticles"];
}


@end
