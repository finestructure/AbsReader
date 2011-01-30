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

#pragma mark -
#pragma mark Workers


- (void)save:(id)sender {
	// Collect info
  NSString *url = self.urlField.text;
  NSMutableDictionary *info = [NSMutableDictionary dictionary];
  [info setObject:self.titleField.text forKey:@"title"];
  [info setObject:url forKey:@"url"];
  [info setObject:self.usernameField.text forKey:@"username"];
  [info setObject:self.passwordField.text forKey:@"password"];

  NSDictionary *defaults_dict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"Feeds"];
  NSMutableDictionary *feeds = [NSMutableDictionary dictionaryWithDictionary:defaults_dict];
  if ([feeds objectForKey:url] != nil) {
    UIAlertView * errorAlert = [[UIAlertView alloc] initWithTitle:@"Feed already exists" message:@"A feed with the given URL has already been configured. Please enter a new URL." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [errorAlert show];
  } else {
    [feeds setObject:info forKey:url];
    [[NSUserDefaults standardUserDefaults] setObject:feeds forKey:@"Feeds"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
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
  self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save:)] autorelease];
  self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)] autorelease];
  
	self.titleField.text = @"";
  self.urlField.text = @"";
  self.usernameField.text = @"";
  self.passwordField.text = @"";
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


- (void)dealloc {
    [super dealloc];
}


@end
