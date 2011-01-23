//
//  RootViewController.m
//  AbsReader
//
//  Created by Sven A. Schmidt on 27.12.10.
//  Copyright 2010 abstracture GmbH & Co. KG. All rights reserved.
//

#import "FeedViewController.h"
#import "SettingsViewController.h"
#import "WebViewController.h"


@implementation FeedViewController

@synthesize activityIndicator;
@synthesize articles;


#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.title = @"AbsReader";
  /*
  self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refresh)] autorelease];
   */
  self.navigationItem.leftBarButtonItem.isAccessibilityElement = YES;
  self.navigationItem.leftBarButtonItem.accessibilityLabel = @"refresh";
  self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"gear.png"] style:UIBarButtonItemStylePlain target:self action:@selector(settingsButtonPressed)] autorelease];
  
  self.activityIndicator = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge]autorelease];
  CGFloat x = newsTable.bounds.size.width/2;
  CGFloat y = newsTable.bounds.size.height/2;
  CGPoint pos = CGPointMake(x, y);
  activityIndicator.center = pos;

  self.articles = [[[FeedCache alloc] init] autorelease];
  NSString *url = @"https://dev.abstracture.de/projects/abstracture/timeline?ticket=on&ticket_details=on&changeset=on&milestone=on&wiki=on&max=50&daysback=90&format=rss";
  self.articles.url = [NSURL URLWithString:url];
  self.articles.delegate = self;
  
  newsTable.rowHeight = 90;
  [self refresh];
  
  {
    UITapGestureRecognizer *gr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    gr.numberOfTapsRequired = 2;
    gr.delaysTouchesBegan = YES;
    [newsTable addGestureRecognizer:gr];
    [gr release];
  }
  {
    UISwipeGestureRecognizer *gr = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
    gr.delaysTouchesBegan = YES;
    [newsTable addGestureRecognizer:gr];
    [gr release];
  }
  
  NSMutableArray *buttons = [NSMutableArray array];
  [buttons addObject:[[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"check.png"] style:UIBarButtonItemStylePlain target:self action:@selector(markAllRead)] autorelease]];
  [buttons addObject:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease]];
  [buttons addObject:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refresh)] autorelease]];
  self.toolbarItems = buttons;
}


- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
  [self safeRefresh];
  [self.navigationController setToolbarHidden:NO animated:animated];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  return YES;
}


#pragma mark -
#pragma mark Table view data source

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return [self.articles.stories count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
  static NSString *CellIdentifier = @"Cell";
    
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
		cell = [self tableViewCellWithReuseIdentifier:CellIdentifier];
  }
    
  [self configureCell:cell forIndexPath:indexPath];
  return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source.
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }   
}
*/


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark -
#pragma mark Workers


- (void)safeRefresh {
  if (self.articles.lastRefresh == nil) {
    [self refresh];
  } else {
    static double refreshInterval = 15*60; // seconds
    NSDate *now = [NSDate date];
    NSTimeInterval diff = [now timeIntervalSinceDate:self.articles.lastRefresh];
    if (diff > refreshInterval) {
      [self refresh];
    }
  }
}


- (void)refresh {
  if (self.articles.refreshInProgress) {
    return;
  }
  NSString *user = [[NSUserDefaults standardUserDefaults] stringForKey:@"Username"];
  NSString *pass = [[NSUserDefaults standardUserDefaults] stringForKey:@"Password"];
  if (user == nil || pass == nil) {
    [self showSettings];
    return;
  }
  [self.articles refresh];
  [newsTable reloadData];
  [newsTable addSubview:self.activityIndicator];
  newsTable.scrollEnabled = NO;
  [self.activityIndicator startAnimating];
}


- (void)settingsButtonPressed {
  [self showSettings];
}


- (void)showSettings {
  SettingsViewController *vc = [[SettingsViewController alloc] initWithNibName:@"SettingsViewController" bundle:nil];
  [self.navigationController pushViewController:vc animated:YES];
  [vc release];
}


- (NSUInteger)unreadCount {
  return [self.articles unreadCount];
}


- (void)markCellAsRead:(NSIndexPath *)indexPath {
  NSString *guid = [[self.articles.stories objectAtIndex:[indexPath row]] objectForKey:@"guid"];
  NSDate *date = [[self.articles.stories objectAtIndex:[indexPath row]] objectForKey:@"pubDate"];
  [self.articles markGuidRead:guid forDate:date];
  NSArray *indexes = [NSArray arrayWithObject:indexPath];
	[newsTable reloadRowsAtIndexPaths:indexes withRowAnimation:NO];
}


- (void)markAllRead {
  [self.articles markAllRead];
  [newsTable reloadData];
}

#pragma mark -
#pragma mark Gesture Handlers


- (void)handleDoubleTap:(UIGestureRecognizer *)sender {
  CGPoint p = [sender locationInView:newsTable];
  NSIndexPath *indexPath = [newsTable indexPathForRowAtPoint:p];
  [self markCellAsRead:indexPath];
}


- (void)handleSwipe:(UIGestureRecognizer *)sender {
	CGPoint p = [sender locationInView:newsTable];
  NSIndexPath *indexPath = [newsTable indexPathForRowAtPoint:p];
  [self markCellAsRead:indexPath];
}


#pragma mark -
#pragma mark ArticleCacheDelegate


- (void)errorOccurred:(NSError *)error {
	[activityIndicator stopAnimating];
	[activityIndicator removeFromSuperview];	
  newsTable.scrollEnabled = YES;

	NSString * errorString = [NSString stringWithFormat:@"Error fetching feed (Error code %i )", [error code]];
	NSLog(@"%@", errorString);
	
	UIAlertView * errorAlert = [[UIAlertView alloc] initWithTitle:@"Error fetching feed" message:[error localizedDescription] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[errorAlert show];
}


- (void)didEndDocument {
	[newsTable reloadData];
	[self.activityIndicator stopAnimating];
	[self.activityIndicator removeFromSuperview];
  newsTable.scrollEnabled = YES;
}


#pragma mark -
#pragma mark NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	NSString * errorString = [NSString stringWithFormat:@"%@ (Error code %i)", [error description], [error code]];
	NSLog(@"Error loading feed: %@", errorString);
	
	UIAlertView * errorAlert = [[UIAlertView alloc] initWithTitle:@"Error loading feed" message:[error localizedDescription] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[errorAlert show];
}


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  NSString *link = [[self.articles.stories objectAtIndex:[indexPath row]] objectForKey: @"link"];
  
  WebViewController *vc = [[WebViewController alloc] initWithNibName:@"WebViewController" bundle:nil];
  vc.link = link;
  [self.navigationController pushViewController:vc animated:YES];
  [vc release];

  [self markCellAsRead:indexPath];

  return;
}


#pragma mark -
#pragma mark Configuring table view cells


const CGFloat kRowWidth = 320;
const CGFloat kTopOffset = 10;

const CGFloat kRightOffset = 24;
const CGFloat kLeftOffset = 10;

const CGFloat kTopHeight = 15;
const CGFloat kMiddleHeight = 40;
const CGFloat kBottomHeight = 15;


- (UITableViewCell *)tableViewCellWithReuseIdentifier:(NSString *)identifier {
	
	UITableViewCell *cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier] autorelease];
  
  // author
  {
    CGFloat x = kLeftOffset +2;
    CGFloat y = kTopOffset;
    CGFloat width = 80;
    CGFloat height = kTopHeight;
    CGRect rect = CGRectMake(x, y, width, height);
    UILabel *label = [[[UILabel alloc] initWithFrame:rect] autorelease];
    label.tag = 1;
    label.font = [UIFont systemFontOfSize:12];
    label.adjustsFontSizeToFitWidth = NO;
    label.textColor = [UIColor grayColor];
    label.highlightedTextColor = [UIColor whiteColor];
    [cell.contentView addSubview:label];
  }
  
  // date
  {
    CGFloat x = 100;
    CGFloat y = kTopOffset;
    CGFloat width = kRowWidth - x - kRightOffset;
    CGFloat height = kTopHeight;
    CGRect rect = CGRectMake(x, y, width, height);
    UILabel *label = [[[UILabel alloc] initWithFrame:rect] autorelease];
    label.tag = 2;
    label.font = [UIFont systemFontOfSize:12];
    label.adjustsFontSizeToFitWidth = NO;
    label.textColor = [UIColor grayColor];
    label.highlightedTextColor = [UIColor whiteColor];
    label.textAlignment = UITextAlignmentRight;
    [cell.contentView addSubview:label];
  }
  
  // desc
  {
    CGFloat x = kLeftOffset;
    CGFloat y = kTopOffset + kTopHeight;
    CGFloat width = kRowWidth - x - kRightOffset;
    CGFloat height = kMiddleHeight;
    CGRect rect = CGRectMake(x, y, width, height);
    UILabel *label = [[[UILabel alloc] initWithFrame:rect] autorelease];
    label.tag = 3;
    label.font = [UIFont boldSystemFontOfSize:16];
    label.adjustsFontSizeToFitWidth = NO;
    label.highlightedTextColor = [UIColor whiteColor];
    [cell.contentView addSubview:label];
  }
  
  // summary
  {
    CGFloat x = kLeftOffset +2;
    CGFloat y = kTopOffset + kTopHeight + kMiddleHeight;
    CGFloat width = kRowWidth - x - kRightOffset;
    CGFloat height = kBottomHeight;
    CGRect rect = CGRectMake(x, y, width, height);
    UILabel *label = [[[UILabel alloc] initWithFrame:rect] autorelease];
    label.tag = 4;
    label.font = [UIFont boldSystemFontOfSize:12];
    label.adjustsFontSizeToFitWidth = NO;
    label.textColor = [UIColor grayColor];
    label.highlightedTextColor = [UIColor whiteColor];
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
	
  NSDictionary *info = [self.articles.stories objectAtIndex:[indexPath row]];
  
	// author
  {
    UILabel *label = (UILabel *)[cell viewWithTag:1];
    label.text = [info objectForKey:@"dc:creator"];
  }
	
	// date
	{
    UILabel *label = (UILabel *)[cell viewWithTag:2];
    label.text = [dateFormatter stringFromDate:[info objectForKey:@"pubDate"]];
  }
  
	// title
  {
    UILabel *label = (UILabel *)[cell viewWithTag:3];
    label.text = [info objectForKey:@"title"];
    NSString *guid = [info objectForKey:@"guid"];
    if ([self.articles alreadyVisited:guid]) {
      label.textColor = [UIColor grayColor];
    } else {
      label.textColor = [UIColor blackColor];
    }
  }
  
	// summary
  {
    UILabel *label = (UILabel *)[cell viewWithTag:4];
    label.text = [info objectForKey:@"description"];
  }
}    


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}


@end


