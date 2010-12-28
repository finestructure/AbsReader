//
//  RootViewController.m
//  AbsReader
//
//  Created by Sven A. Schmidt on 27.12.10.
//  Copyright 2010 abstracture GmbH & Co. KG. All rights reserved.
//

#import "RootViewController.h"
#import "SettingsViewController.h"
#import "WebViewController.h"


@implementation RootViewController

@synthesize activityIndicator;
@synthesize stories;
@synthesize rssParser;
@synthesize item;
@synthesize currentElement, currentTitle, currentDate, currentSummary, currentLink, currentAuthor, currentCategory;
@synthesize rssData;


#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.title = @"AbsReader";
  self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refresh)] autorelease];
  //self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Config" style:UIBarButtonItemStylePlain target:self action:@selector(settingsButtonPressed)] autorelease];
  self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"gear.png"] style:UIBarButtonItemStylePlain target:self action:@selector(settingsButtonPressed)] autorelease];
  
  self.activityIndicator = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge]autorelease];
  CGFloat x = newsTable.bounds.size.width/2;
  CGFloat y = newsTable.bounds.size.height/2;
  CGPoint pos = CGPointMake(x, y);
  activityIndicator.center = pos;

  newsTable.rowHeight = 90;
}


/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/


- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [self refresh];
}


/*
- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}
*/

/*
 // Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations.
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
 */


#pragma mark -
#pragma mark Table view data source

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return [self.stories count];
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


- (void)refresh {
  [newsTable addSubview:self.activityIndicator];
  [self.activityIndicator startAnimating];
  NSString *user = [[NSUserDefaults standardUserDefaults] stringForKey:@"Username"];
  NSString *pass = [[NSUserDefaults standardUserDefaults] stringForKey:@"Password"];
  if (user == nil || pass == nil) {
    [self showSettings];
    return;
  }
  NSString *url = @"https://dev.abstracture.de/projects/abstracture/timeline?ticket=on&ticket_details=on&changeset=on&milestone=on&wiki=on&max=50&daysback=90&format=rss";
  [self parseXMLFileAtURL:url];
}


- (void)settingsButtonPressed {
  [self showSettings];
}


- (void)showSettings {
  SettingsViewController *vc = [[SettingsViewController alloc] initWithNibName:@"SettingsViewController" bundle:nil];
  [self.navigationController pushViewController:vc animated:YES];
  [vc release];
}


#pragma mark -
#pragma mark XML Parsing


- (void)parseXMLFileAtURL:(NSString *)url {	
	self.stories = [NSMutableArray array];
  self.rssData = [NSMutableData data];
  NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
  [[[NSURLConnection alloc] initWithRequest:request delegate:self] autorelease];  
}


- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
	[activityIndicator stopAnimating];
	[activityIndicator removeFromSuperview];	

	NSString * errorString = [NSString stringWithFormat:@"Unable to download story feed from web site (Error code %i )", [parseError code]];
	NSLog(@"error parsing XML: %@", errorString);
	
	UIAlertView * errorAlert = [[UIAlertView alloc] initWithTitle:@"Error loading content" message:errorString delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[errorAlert show];
}


- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict{			
  //NSLog(@"found this element: %@", elementName);
	self.currentElement = elementName;
	if ([elementName isEqualToString:@"item"]) {
		// clear out our story item caches...
		self.item = [NSMutableDictionary dictionary];
		self.currentTitle = [NSMutableString string];
		self.currentDate = [NSMutableString string];
		self.currentSummary = [NSMutableString string];
		self.currentLink = [NSMutableString string];
    self.currentAuthor = [NSMutableString string];
    self.currentCategory = [NSMutableString string];
	}
	
}


- (NSString *)cleanup:(NSString *)string {
  NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
  return [string stringByTrimmingCharactersInSet:whitespace];
}


- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName{     
	if ([elementName isEqualToString:@"item"]) {
		[self.item setObject:[self cleanup:self.currentTitle] forKey:@"title"];    
		[self.item setObject:[self cleanup:self.currentLink] forKey:@"link"];
		[self.item setObject:[self cleanup:self.currentSummary] forKey:@"summary"];
		[self.item setObject:[self cleanup:self.currentDate] forKey:@"date"];
    [self.item setObject:[self cleanup:self.currentAuthor] forKey:@"author"];
    [self.item setObject:[self cleanup:self.currentCategory] forKey:@"category"];
		
    [self.stories addObject:self.item];
	}
	
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string{
	//NSLog(@"found characters: %@", string);
	// save the characters for the current item...
	if ([self.currentElement isEqualToString:@"title"]) {
		[self.currentTitle appendString:string];
	} else if ([self.currentElement isEqualToString:@"link"]) {
		[self.currentLink appendString:string];
	} else if ([self.currentElement isEqualToString:@"description"]) {
		[self.currentSummary appendString:string];
	} else if ([self.currentElement isEqualToString:@"pubDate"]) {
		[self.currentDate appendString:string];
	} else if ([self.currentElement isEqualToString:@"dc:creator"]) {
    [self.currentAuthor appendString:string];
	} else if ([self.currentElement isEqualToString:@"category"]) {
    [self.currentCategory appendString:string];
  }
	
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
	[newsTable reloadData];
	[self.activityIndicator stopAnimating];
	[self.activityIndicator removeFromSuperview];	
}


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  NSString * link = [[stories objectAtIndex:[indexPath row]] objectForKey: @"link"];

  WebViewController *vc = [[WebViewController alloc] initWithNibName:@"WebViewController" bundle:nil];
  vc.link = link;
  [self.navigationController pushViewController:vc animated:YES];
  [vc release];

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
	
  NSDictionary *info = [self.stories objectAtIndex:[indexPath row]];
  
	// author
  {
    UILabel *label = (UILabel *)[cell viewWithTag:1];
    label.text = [info objectForKey:@"author"];
  }
	
	// date
	{
    UILabel *label = (UILabel *)[cell viewWithTag:2];
    label.text = [info objectForKey:@"date"]; //[dateFormatter stringFromDate:[info objectForKey:@"date"]];
  }
  
	// title
  {
    UILabel *label = (UILabel *)[cell viewWithTag:3];
    label.text = [info objectForKey:@"title"];
  }
  
	// summary
  {
    UILabel *label = (UILabel *)[cell viewWithTag:4];
    label.text = [info objectForKey:@"summary"];
  }
}    


#pragma mark -
#pragma mark NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
  NSLog(@"got auth challange");
  
  if ([challenge previousFailureCount] == 0) {
    NSString *user = [[NSUserDefaults standardUserDefaults] stringForKey:@"Username"];
    NSString *pass = [[NSUserDefaults standardUserDefaults] stringForKey:@"Password"];

    [[challenge sender] useCredential:[NSURLCredential credentialWithUser:user password:pass persistence:NSURLCredentialPersistencePermanent] forAuthenticationChallenge:challenge];
  } else {
    [[challenge sender] cancelAuthenticationChallenge:challenge]; 
  }
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
  NSLog(@"received data: %d", [data length]);
  [self.rssData appendData:data];
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
  NSLog(@"finished loading");

  rssParser = [[[NSXMLParser alloc] initWithData:self.rssData] autorelease];
  [rssParser setDelegate:self];
  [rssParser setShouldProcessNamespaces:NO];
  [rssParser setShouldReportNamespacePrefixes:NO];
  [rssParser setShouldResolveExternalEntities:NO];
  [rssParser parse];
}


- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	NSString * errorString = [NSString stringWithFormat:@"%@ (Error code %i)", [error description], [error code]];
	NSLog(@"Error loading feed: %@", errorString);
	
	UIAlertView * errorAlert = [[UIAlertView alloc] initWithTitle:@"Error loading feed" message:errorString delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[errorAlert show];
}


- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection {
  return NO;
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


