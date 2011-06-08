//
//  SettingsViewController.m
//  AbsReader
//
//  Created by Sven A. Schmidt on 27.12.10.
//  Copyright 2010 abstracture GmbH & Co. KG. All rights reserved.
//

#import "SettingsViewController.h"


@implementation SettingsViewController

@synthesize titleField;
@synthesize urlField;
@synthesize usernameField;
@synthesize passwordField;
@synthesize versionLabel;
@synthesize feed;
@synthesize isNew;


#pragma mark -
#pragma mark Workers


- (void)save:(id)sender {
  NSString *url = self.urlField.text;
  
  if (url == nil) {
    UIAlertView * errorAlert = [[UIAlertView alloc] initWithTitle:@"No URL specified" message:@"Please provide a valid URL." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [errorAlert show];
    return;
  }
  
  NSString *oldUrl = self.feed.urlString;
  BOOL urlChanged = (oldUrl != nil) && ![oldUrl isEqualToString:url];
  
  self.feed.title = self.titleField.text;
  self.feed.urlString = url;
  self.feed.url = [NSURL URLWithString:url];
  self.feed.username = self.usernameField.text;
  self.feed.password = self.passwordField.text;
  

  NSDictionary *defaults = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"Feeds"];
  
  if (self.isNew && [defaults objectForKey:url] != nil) {
    UIAlertView * errorAlert = [[UIAlertView alloc] initWithTitle:@"Feed already exists" message:@"A feed with the given URL has already been configured. Please enter a new URL." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [errorAlert show];
    return;
  } else {
    if (urlChanged) {
      // delete previous version from user defaults
      NSMutableDictionary *update = [NSMutableDictionary dictionaryWithDictionary:defaults];
      [update removeObjectForKey:oldUrl];
      [[NSUserDefaults standardUserDefaults] setObject:update forKey:@"Feeds"];
    }
    [self.feed saveToUserDefaults];
    [[NSNotificationCenter defaultCenter] postNotificationName:kFeedInfoUpdated object:self];
    [self.navigationController popViewControllerAnimated:YES];
  }
}


- (void)cancel:(id)sender {
  [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark -
#pragma mark - View lifecycle

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
  [super viewDidLoad];
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save:)];
  self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
  
	self.titleField.text = self.feed.title;
  self.urlField.text = self.feed.urlString;
  self.usernameField.text = self.feed.username;
  self.passwordField.text = self.feed.password;
  
  NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
  self.versionLabel.text = version;
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [textField resignFirstResponder];
  return YES;
}


- (void)textFieldDidEndEditing:(UITextField *)textField {
}


- (void)viewDidAppear:(BOOL)animated {
  [self.navigationController setToolbarHidden:YES animated:animated];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  return YES;
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}




@end
