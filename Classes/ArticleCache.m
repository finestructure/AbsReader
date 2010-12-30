//
//  ArticleCache.m
//  AbsReader
//
//  Created by Sven A. Schmidt on 29.12.10.
//  Copyright 2010 abstracture GmbH & Co. KG. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ArticleCache.h"


@implementation ArticleCache

@synthesize cache;
@synthesize stories;
@synthesize rssParser;
@synthesize item;
@synthesize currentElement;
@synthesize currentTitle;
@synthesize currentDate;
@synthesize currentSummary;
@synthesize currentLink;
@synthesize currentAuthor;
@synthesize currentCategory;
@synthesize rssData;
@synthesize recordCharacters;
@synthesize lastRefresh;
@synthesize refreshInProgress;


- (id)init {
  self = [super init];
  if (self) {
    self.cache = [NSMutableDictionary dictionary];
  }
  return self;
}


#pragma mark -
#pragma mark XML Parsing


- (void)parseXMLFileAtURL:(NSURL *)url {	
  self.refreshInProgress = YES;
  self.rssData = [NSMutableData data];
  self.stories = [NSMutableArray array];
  NSURLRequest *request = [NSURLRequest requestWithURL:url];
  [[[NSURLConnection alloc] initWithRequest:request delegate:self] autorelease];
}



- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
	NSString * errorString = [NSString stringWithFormat:@"Unable to download story feed from web site (Error code %i )", [parseError code]];
	NSLog(@"error parsing XML: %@", errorString);
	
	UIAlertView * errorAlert = [[UIAlertView alloc] initWithTitle:@"Error parsing feed" message:[parseError localizedDescription] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[errorAlert show];
  self.refreshInProgress = NO;
}


- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict{			
	self.currentElement = elementName;
	if ([elementName isEqualToString:@"item"]) {
    self.recordCharacters = YES;
		self.item = [NSMutableDictionary dictionary];
		self.currentTitle = [NSMutableString string];
		self.currentDate = [NSMutableString string];
		self.currentSummary = [NSMutableString string];
		self.currentLink = [NSMutableString string];
    self.currentAuthor = [NSMutableString string];
    self.currentCategory = [NSMutableString string];
	} else if ([elementName isEqualToString:@"title"]
             || [elementName isEqualToString:@"link"]
             || [elementName isEqualToString:@"description"]
             || [elementName isEqualToString:@"pubDate"]
             || [elementName isEqualToString:@"dc:creator"]
             || [elementName isEqualToString:@"category"]) {
    self.recordCharacters = YES;
  }	
}


- (NSString *)removeWhitespace:(NSString *)string {
  static NSCharacterSet *whitespace = nil;
  if (whitespace == nil) {
    whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
  }
  return [string stringByTrimmingCharactersInSet:whitespace];
}


- (NSString *)flattenHTML:(NSString *)html {
  NSScanner *scanner = [NSScanner scannerWithString:html];
  NSString *temp = nil;
  html = [self removeWhitespace:html];
  
  while ([scanner isAtEnd] == NO) {
    [scanner scanUpToString:@"<" intoString:nil];
    [scanner scanUpToString:@">" intoString:&temp];
    html = [html stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@>", temp] withString:@""];
  }  
  return html;
}


- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName{     
	if ([elementName isEqualToString:@"item"]) {
		[self.item setObject:self.currentTitle forKey:@"title"];    
		[self.item setObject:self.currentLink forKey:@"link"];
		[self.item setObject:[self flattenHTML:self.currentSummary] forKey:@"summary"];
		[self.item setObject:self.currentDate forKey:@"date"];
    [self.item setObject:self.currentAuthor forKey:@"author"];
    [self.item setObject:self.currentCategory forKey:@"category"];
    [self.stories addObject:self.item];
	} else if ([elementName isEqualToString:@"title"]
             || [elementName isEqualToString:@"link"]
             || [elementName isEqualToString:@"description"]
             || [elementName isEqualToString:@"pubDate"]
             || [elementName isEqualToString:@"dc:creator"]
             || [elementName isEqualToString:@"category"]) {
    self.recordCharacters = NO;
	}
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string{
  if (self.recordCharacters == NO) {
    return;
  }
	if ([self.currentElement isEqualToString:@"title"]) {
		[self.currentTitle appendString:string];
	} else if ([self.currentElement isEqualToString:@"link"]) {
		[self.currentLink appendString:string];
	} else if ([self.currentElement isEqualToString:@"description"]) {
		[self.currentSummary appendString:string];
	} else if ([self.currentElement isEqualToString:@"pubDate"]) {
		[self.currentDate appendString:string];
	} else if ([self.currentElement isEqualToString:@"dc:creator"]) {
    [self.currentAuthor appendString:string];
	} else if ([self.currentElement isEqualToString:@"category"]) {
    [self.currentCategory appendString:string];
  }	
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
  self.lastRefresh = [NSDate date];
  self.refreshInProgress = NO;
}


#pragma mark -
#pragma mark NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
  //NSLog(@"got auth challange");
  if ([challenge previousFailureCount] == 0) {
    NSString *user = [[NSUserDefaults standardUserDefaults] stringForKey:@"Username"];
    NSString *pass = [[NSUserDefaults standardUserDefaults] stringForKey:@"Password"];
    
    [[challenge sender] useCredential:[NSURLCredential credentialWithUser:user password:pass persistence:NSURLCredentialPersistencePermanent] forAuthenticationChallenge:challenge];
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
	NSString * errorString = [NSString stringWithFormat:@"%@ (Error code %i)", [error description], [error code]];
	NSLog(@"Error loading feed: %@", errorString);
	
	UIAlertView * errorAlert = [[UIAlertView alloc] initWithTitle:@"Error loading feed" message:[error localizedDescription] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[errorAlert show];
  self.refreshInProgress = NO;
}


- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection {
  return NO;
}


@end
