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
    [feed refresh];
  }
  [(UITableView *)self.view reloadData];
}


- (void)refreshFeedList:(NSNotification *)notification {
  [self loadFeedList];
}


- (void)articleLoaded:(NSNotification *)notification {
  [self.tableView reloadData];
}


#pragma mark - View lifecycle


- (void)viewDidLoad {
  [super viewDidLoad];

  self.title = @"AbsReader";

  self.navigationItem.leftBarButtonItem = self.editButtonItem;
  self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addFeed:)] autorelease];

  [self loadFeedList];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshFeedList:) name:kFeedInfoUpdated object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(articleLoaded:) name:kArticleLoaded object:nil];
}


- (void)viewDidUnload {
  [super viewDidUnload];
}


- (void)viewWillAppear:(BOOL)animated{
  [super viewWillAppear:animated];
}


- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
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
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
  }
  
  FeedCache *feed = [self.feeds objectAtIndex:indexPath.row];
  cell.textLabel.text = [NSString stringWithFormat:@"%@ (%d)", feed.title, [feed unreadCount]];
  
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

@end
