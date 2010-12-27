//
//  SettingsViewController.h
//  AbsReader
//
//  Created by Sven A. Schmidt on 27.12.10.
//  Copyright 2010 abstracture GmbH & Co. KG. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface SettingsViewController : UIViewController<UITextFieldDelegate> {
}

@property (nonatomic, retain) IBOutlet UITextField *usernameField;
@property (nonatomic, retain) IBOutlet UITextField *passwordField;

@end
