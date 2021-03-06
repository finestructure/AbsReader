//
//  WebViewController.m
//  AbsReader
//
//  Created by Sven A. Schmidt on 27.12.10.
//  Copyright 2010 abstracture GmbH & Co. KG. All rights reserved.
//

#import "WebViewController.h"


@implementation WebViewController

@synthesize webView;
@synthesize link;
@synthesize data;

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
    }
    return self;
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
  [super viewDidLoad];

  self.data = [NSMutableData data];
  NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:self.link]];
  [self.webView setDelegate:self];
  [self.webView loadRequest:request];
}


- (void)viewWillDisappear:(BOOL)animated {
  [self.webView setDelegate:nil];
  [self.webView stopLoading];
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}


- (void)viewDidAppear:(BOOL)animated {
  [self.navigationController setToolbarHidden:YES animated:animated];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  return YES;
}


#pragma mark -
#pragma mark UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView {
  [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}


- (void)webViewDidFinishLoad:(UIWebView *)webView {
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}


- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
	NSString * errorString = [NSString stringWithFormat:@"%@ (Error code %i)", [error description], [error code]];
	NSLog(@"Error loading page: %@", errorString);
	
	UIAlertView * errorAlert = [[UIAlertView alloc] initWithTitle:@"Error loading page" message:[error localizedDescription] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[errorAlert show];
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}


#pragma mark -
#pragma mark Memory Management

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
