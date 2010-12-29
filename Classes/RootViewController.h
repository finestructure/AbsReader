//
//  RootViewController.h
//  AbsReader
//
//  Created by Sven A. Schmidt on 27.12.10.
//  Copyright 2010 abstracture GmbH & Co. KG. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RootViewController : UITableViewController<NSXMLParserDelegate> {
  IBOutlet UITableView *newsTable;
}

@property (nonatomic, retain) UIActivityIndicatorView *activityIndicator;
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
@property (nonatomic, retain) NSMutableData *rssData;
@property (assign) BOOL recordCharacters;

- (void)parseXMLFileAtURL:(NSString *)url;
- (void)refresh;
- (void)settingsButtonPressed;
- (void)showSettings;
- (UITableViewCell *)tableViewCellWithReuseIdentifier:(NSString *)identifier;
- (void)configureCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath;

@end
