//
//  RootViewController.m
//  AbsReader
//
//  Created by Sven A. Schmidt on 23.01.11.
//  Copyright 2011 abstracture GmbH & Co. KG. All rights reserved.
//

#import "RootViewController.h"
#import "FeedViewController.h"
#import "SettingsViewController.h"


@implementation RootViewController

@synthesize feeds;
@synthesize feedControllers;


- (id)initWithStyle:(UITableViewStyle)style {
  self = [super initWithStyle:style];
  if (self) {
  }
  return self;
}


- (void)dealloc {
  [super dealloc];
}


- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
}


#pragma mark -
#pragma mark Workers


- (void)safeRefresh {
  static double refreshInterval = 15*60; // seconds
  NSDate *now = [NSDate date];

  for (FeedCache *feed in self.feeds) {
    NSTimeInterval diff = [now timeIntervalSinceDate:feed.lastRefresh];
    if (feed.lastRefresh == nil || diff > refreshInterval) {
      [feed refresh];
      [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    }
  }
}


- (void)refresh {
  for (FeedCache *feed in self.feeds) {
    if (! feed.refreshInProgress) {
      [feed refresh];
      [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    }
  }
}


- (void)addFeed:(id)sender {
  SettingsViewController *vc = [[SettingsViewController alloc] initWithNibName:@"SettingsViewController" bundle:nil];
  vc.feed = [[[FeedCache alloc] init] autorelease];
  vc.isNew = YES;
  [self.navigationController pushViewController:vc animated:YES];
  [vc release];
}


- (void)loadFeedList {
  self.feeds = [NSMutableArray array];
  self.feedControllers = [NSMutableArray array];
  NSDictionary *defaultFeeds = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"Feeds"];
	for (NSString *url in defaultFeeds) {
    NSData *data = [defaultFeeds objectForKey:url];
    FeedCache *feed = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    FeedViewController *vc = [[FeedViewController alloc] initWithNibName:@"FeedViewController" bundle:nil];
    vc.feed = feed;
    vc.title = feed.title;
    feed.delegate = vc;
    [self.feeds addObject:feed];
    [self.feedControllers addObject:vc];
  }
  [self refresh];
  [(UITableView *)self.view reloadData];
}


- (void)refreshFeedList:(NSNotification *)notification {
  [self loadFeedList];
}


- (void)articleLoaded:(NSNotification *)notification {
  [self.tableView reloadData];
}


- (void)feedLoaded:(NSNotification *)notification {
  BOOL allDone = YES;
  for (FeedCache *feed in self.feeds) {
    if (feed.refreshInProgress) {
      allDone = NO;
      break;
    }
  }
  if (allDone) {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
  }
}


- (NSUInteger)unreadCount {
  NSUInteger total = 0;
  for (FeedCache *feed in self.feeds) {
    total += [feed unreadCount];
  }
  return total;
}


- (void)markAllRead {
  UIActionSheet *sheet = [[[UIActionSheet alloc] initWithTitle:@"Mark all read" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Mark Read" otherButtonTitles:nil] autorelease];
  [sheet showFromBarButtonItem:[self.toolbarItems objectAtIndex:0] animated:YES];
}


#pragma mark - View lifecycle


- (void)viewDidLoad {
  [super viewDidLoad];

  self.title = @"AbsReader";

  self.navigationItem.leftBarButtonItem = self.editButtonItem;
  self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addFeed:)] autorelease];

  [self loadFeedList];

  // set up toolbar
  NSMutableArray *buttons = [NSMutableArray array];
  [buttons addObject:[[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"check.png"] style:UIBarButtonItemStylePlain target:self action:@selector(markAllRead)] autorelease]];
  [buttons addObject:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease]];
  [buttons addObject:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refresh)] autorelease]];
  self.toolbarItems = buttons;
  
  // register notification handlers
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshFeedList:) name:kFeedInfoUpdated object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(articleLoaded:) name:kArticleLoaded object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(feedLoaded:) name:kFeedLoaded object:nil];
}


- (void)viewDidUnload {
  [super viewDidUnload];
}


- (void)viewWillAppear:(BOOL)animated{
  [super viewWillAppear:animated];
}


- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [self.tableView reloadData];
  [self.navigationController setToolbarHidden:NO animated:animated];
}


- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
}


- (void)viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}


#pragma mark - Configuring table view cells


- (UITableViewCell *)tableViewCellWithReuseIdentifier:(NSString *)identifier {
	
	UITableViewCell *cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier] autorelease];
  
  const CGFloat rowHeight = 24;
  const CGFloat rowWidth = 320;
  
  // title
  {
    CGFloat x = 10;
    CGFloat y = 10;
    CGFloat width = 200;
    CGFloat height = rowHeight;
    CGRect rect = CGRectMake(x, y, width, height);
    UILabel *label = [[[UILabel alloc] initWithFrame:rect] autorelease];
    label.tag = 1;
    label.font = [UIFont boldSystemFontOfSize:16];
    label.adjustsFontSizeToFitWidth = NO;
    label.highlightedTextColor = [UIColor whiteColor];
    [cell.contentView addSubview:label];
  }
  
  // count
  {
    CGFloat x = rowWidth - 55;
    CGFloat y = 9;
    CGFloat width = 30;
    CGFloat height = rowHeight;
    CGRect rect = CGRectMake(x, y, width, height);
    UILabel *label = [[[UILabel alloc] initWithFrame:rect] autorelease];
    label.tag = 2;
    label.font = [UIFont boldSystemFontOfSize:12];
    label.adjustsFontSizeToFitWidth = NO;
    label.highlightedTextColor = [UIColor whiteColor];
    label.textAlignment = UITextAlignmentRight;
    [cell.contentView addSubview:label];
  }
  
  cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  
	return cell;
}


- (void)configureCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath {
  
	static NSDateFormatter *dateFormatter = nil;
	if (dateFormatter == nil) {
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateFormat:@"LLL-dd HH:mm"];
	}
	
  FeedCache *feed = [self.feeds objectAtIndex:indexPath.row];
  
	// title
  {
    UILabel *label = (UILabel *)[cell viewWithTag:1];
    label.text = feed.title;
    if ([feed unreadCount] == 0) {
      label.textColor = [UIColor grayColor];
    } else {
      label.textColor = [UIColor blackColor];
    }
  }
  
	// count
  {
    UILabel *label = (UILabel *)[cell viewWithTag:2];
    if ([feed unreadCount] > 0) {
      label.text = [NSString stringWithFormat:@"%d", [feed unreadCount]];
    } else {
      label.text = @"";
    }
  }
}    


#pragma mark - Table view data source


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return [self.feeds count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *CellIdentifier = @"Cell";
  
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
		cell = [self tableViewCellWithReuseIdentifier:CellIdentifier];
  }
  
  [self configureCell:cell forIndexPath:indexPath];
  return cell;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
  return YES;
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
  if (editingStyle == UITableViewCellEditingStyleDelete) {
    // Delete the row from the data source
    NSString *url = [[feeds objectAtIndex:indexPath.row] urlString];
    NSDictionary *defaults_dict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"Feeds"];
    NSMutableDictionary *updatedDict = [NSMutableDictionary dictionaryWithDictionary:defaults_dict];
    [updatedDict removeObjectForKey:url];
    
    [[NSUserDefaults standardUserDefaults] setObject:updatedDict forKey:@"Feeds"];
    
    [feeds removeObjectAtIndex:indexPath.row];
    [feedControllers removeObjectAtIndex:indexPath.row];
    
    // Remove row from table view
    [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
  }   
  else if (editingStyle == UITableViewCellEditingStyleInsert) {
    // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
  }
}


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  FeedViewController *vc = [self.feedControllers objectAtIndex:indexPath.row];
  [self.navigationController pushViewController:vc animated:YES];
}


#pragma mark - UIActionSheetDelegate


- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
  if (buttonIndex == 0) {
    for (FeedCache *feed in self.feeds) {
      [feed markAllRead];
    }
    [self.tableView reloadData];    
  }
}


@end
