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


- (id)initWithUrlString:(NSString *)string {
  self = [super init];
  if (self) {    
    self.url = [NSURL URLWithString:string];
    self.urlString = urlString;
    self.cache = [NSMutableDictionary dictionary];

    // fetch data from user defaults
    NSDictionary *defaultFeeds = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"Feeds"];
    NSDictionary *info = [defaultFeeds objectForKey:url];

    self.title = [info objectForKey:@"title"];
    self.username = [info objectForKey:@"username"];
    self.password = [info objectForKey:@"password"];
    self.readArticles = [info objectForKey:@"readArticles"];
    if (self.readArticles == nil) {
      self.readArticles = [NSMutableDictionary dictionary];
			//[self updateDefaultsWithObject:self.readArticles forKey:@"readArticles"];
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
  return self;
}


#pragma mark -
#pragma mark Workers


// Keep track of the date (pubdate of the article) as well as the guid
// in order to be able to limit the list size to a certain depth.
// Otherwise the list of read article guids would grow indefinitely.
- (void)markGuidRead:(NSString *)guid forDate:(NSDate *)date {
  [self.readArticles setObject:date forKey:guid];
  [self updateDefaultsWithObject:self.readArticles forKey:@"readArticles"];
}


- (void)markAllRead {
  for (NSDictionary *story in self.stories) {
    NSString *guid = [story objectForKey:@"guid"];
    NSDate *pubDate = [story objectForKey:@"pubDate"];
    [self markGuidRead:guid forDate:pubDate];
  }
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


- (void)updateDefaultsWithObject:(id)object forKey:(NSString *)key {
  NSDictionary *defaultFeeds = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"Feeds"];
  NSDictionary *info = [defaultFeeds objectForKey:self.urlString];
  NSMutableDictionary *feedsUpdate = [NSMutableDictionary dictionaryWithDictionary:defaultFeeds];
  NSMutableDictionary *infoUpdate = [NSMutableDictionary dictionaryWithDictionary:info];
  [infoUpdate setObject:object forKey:key];
  [feedsUpdate setObject:infoUpdate forKey:self.urlString];
  [[NSUserDefaults standardUserDefaults] setObject:feedsUpdate forKey:@"Feeds"];
}


#pragma mark -
#pragma mark XML Parsing


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
}


#pragma mark -
#pragma mark NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
  //NSLog(@"got auth challange");
  if ([challenge previousFailureCount] == 0) {
    [[challenge sender] useCredential:[NSURLCredential credentialWithUser:self.username password:self.password persistence:NSURLCredentialPersistencePermanent] forAuthenticationChallenge:challenge];
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


@end
