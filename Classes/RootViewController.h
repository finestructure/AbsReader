//
//  RootViewController.h
//  AbsReader
//
//  Created by Sven A. Schmidt on 23.01.11.
//  Copyright 2011 abstracture GmbH & Co. KG. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface RootViewController : UITableViewController<UIActionSheetDelegate> {
@private
    
}

- (void)refresh;
- (void)safeRefresh;
- (NSUInteger)unreadCount;


@property (nonatomic, retain) NSMutableArray *feeds;
@property (nonatomic, retain) NSMutableArray *feedControllers;

@end
