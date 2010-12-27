//
//  RootViewController.m
//  AbsReader
//
//  Created by Sven A. Schmidt on 27.12.10.
//  Copyright 2010 abstracture GmbH & Co. KG. All rights reserved.
//

#import "RootViewController.h"
#import "SettingsViewController.h"


@implementation RootViewController

@synthesize activityIndicator;
@synthesize stories;
@synthesize rssParser;
@synthesize item;
@synthesize currentElement, currentTitle, currentDate, currentSummary, currentLink;


#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.title = @"dev.abstracture.de";
  self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refresh)] autorelease];
  self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Config" style:UIBarButtonItemStylePlain target:self action:@selector(settingsButtonPressed)] autorelease];
  
  self.activityIndicator = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge]autorelease];
  CGFloat x = newsTable.bounds.size.width/2;
  CGFloat y = newsTable.bounds.size.height/2;
  CGPoint pos = CGPointMake(x, y);
  activityIndicator.center = pos;
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
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
  }
    
	// Configure the cell.
  cell.textLabel.text = [[self.stories objectAtIndex:[indexPath row]] objectForKey:@"title"];
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
  NSString *url = [NSString stringWithFormat:@"https://%@:%@@dev.abstracture.de/projects/abstracture/timeline?ticket=on&ticket_details=on&changeset=on&milestone=on&wiki=on&max=50&daysback=90&format=rss", user, pass];
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
	
  //you must then convert the path to a proper NSURL or it won't work
  NSURL *xmlURL = [NSURL URLWithString:url];
	
  // here, for some reason you have to use NSClassFromString when trying to alloc NSXMLParser, otherwise you will get an object not found error
  // this may be necessary only for the toolchain
  rssParser = [[[NSXMLParser alloc] initWithContentsOfURL:xmlURL] autorelease];
	
  // Set self as the delegate of the parser so that it will receive the parser delegate methods callbacks.
  [rssParser setDelegate:self];
	
  // Depending on the XML document you're parsing, you may want to enable these features of NSXMLParser.
  [rssParser setShouldProcessNamespaces:NO];
  [rssParser setShouldReportNamespacePrefixes:NO];
  [rssParser setShouldResolveExternalEntities:NO];
	
  [rssParser parse];
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
	}
	
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName{     
	//NSLog(@"ended element: %@", elementName);
	if ([elementName isEqualToString:@"item"]) {
		[self.item setObject:currentTitle forKey:@"title"];
		[self.item setObject:currentLink forKey:@"link"];
		[self.item setObject:currentSummary forKey:@"summary"];
		[self.item setObject:currentDate forKey:@"date"];
		
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
  NSString * storyLink = [[stories objectAtIndex:[indexPath row]] objectForKey: @"link"];
  
  // clean up the link - get rid of spaces, returns, and tabs...
  storyLink = [storyLink stringByReplacingOccurrencesOfString:@" " withString:@""];
  storyLink = [storyLink stringByReplacingOccurrencesOfString:@"\n" withString:@""];
  storyLink = [storyLink stringByReplacingOccurrencesOfString:@"	" withString:@""];
  
  NSLog(@"link: %@", storyLink);
  // open in Safari
  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:storyLink]];
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


