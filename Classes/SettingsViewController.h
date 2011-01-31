//
//  SettingsViewController.h
//  AbsReader
//
//  Created by Sven A. Schmidt on 27.12.10.
//  Copyright 2010 abstracture GmbH & Co. KG. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FeedCache.h"

static NSString *kFeedInfoUpdated __attribute__ ((unused)) = @"FeedInfoUpdated";


@interface SettingsViewController : UIViewController<UITextFieldDelegate> {
}

@property (nonatomic, retain) IBOutlet UITextField *titleField;
@property (nonatomic, retain) IBOutlet UITextField *urlField;
@property (nonatomic, retain) IBOutlet UITextField *usernameField;
@property (nonatomic, retain) IBOutlet UITextField *passwordField;
@property (nonatomic, retain) IBOutlet UILabel *versionLabel;

@property (nonatomic, retain) FeedCache *feed;

@end
