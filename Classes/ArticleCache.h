//
//  ArticleCache.h
//  AbsReader
//
//  Created by Sven A. Schmidt on 29.12.10.
//  Copyright 2010 abstracture GmbH & Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ArticleCache : NSObject<NSXMLParserDelegate> {
}

@property (nonatomic, retain) NSMutableDictionary *cache;
@property (nonatomic, retain) NSMutableArray *stories;
@property (nonatomic, retain) NSXMLParser *rssParser;
@property (nonatomic, retain) NSMutableDictionary *item;
@property (nonatomic, retain) NSString *currentElement;
@property (nonatomic, retain) NSMutableString *currentTitle;
@property (nonatomic, retain) NSMutableString *currentDate;
@property (nonatomic, retain) NSMutableString *currentSummary;
@property (nonatomic, retain) NSMutableString *currentLink;
@property (nonatomic, retain) NSMutableString *currentAuthor;
@property (nonatomic, retain) NSMutableString *currentCategory;
@property (nonatomic, retain) NSMutableString *currentGuid;
@property (nonatomic, retain) NSMutableData *rssData;
@property (assign) BOOL recordCharacters;
@property (nonatomic, retain) NSDate *lastRefresh;
@property (assign) BOOL refreshInProgress;

- (void)parseXMLFileAtURL:(NSURL *)url;

@end
