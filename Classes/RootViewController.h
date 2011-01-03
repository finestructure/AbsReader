//
//  RootViewController.h
//  AbsReader
//
//  Created by Sven A. Schmidt on 27.12.10.
//  Copyright 2010 abstracture GmbH & Co. KG. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ArticleCache.h"

@interface RootViewController : UITableViewController<ArticleCacheDelegate> {
  IBOutlet UITableView *newsTable;
}

@property (nonatomic, retain) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, retain) ArticleCache *articles;

- (void)refresh;
- (void)safeRefresh;
- (void)settingsButtonPressed;
- (void)showSettings;
- (UITableViewCell *)tableViewCellWithReuseIdentifier:(NSString *)identifier;
- (void)configureCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath;
- (NSUInteger)unreadCount;

@end
