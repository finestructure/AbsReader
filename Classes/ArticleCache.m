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

@synthesize delegate;
@synthesize cache;
@synthesize stories;
@synthesize rssParser;
@synthesize item;
@synthesize currentValue;
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
  self.refreshInProgress = NO;
  [self.delegate errorOccurred:parseError];
}


- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict{			
  self.currentValue = [NSMutableString string];
  self.recordCharacters = YES;
	if ([elementName isEqualToString:@"item"]) {
		self.item = [NSMutableDictionary dictionary];
  } else if ([elementName isEqualToString:@"description"]) {
    [self.item setObject:[self flattenHTML:self.currentValue] forKey:elementName];
  } else {
    [self.item setObject:self.currentValue forKey:elementName];
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
    [self.stories addObject:self.item];
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
  self.refreshInProgress = NO;
  [self.delegate errorOccurred:error];
}


- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection {
  return NO;
}


@end
