//
//  PreferencesViewController.m
//  Preferences
//
//  Created by MTel on 22/01/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PreferencesViewController.h"

@implementation PreferencesViewController

NSString *kPreferencesEmailAddress = @"userInputText";

/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/



// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	if ([[NSUserDefaults standardUserDefaults] stringForKey:kPreferencesEmailAddress]) {
		userInput.text = [[NSUserDefaults standardUserDefaults] stringForKey:kPreferencesEmailAddress];
	} else {
		userInput.text = @"No define";
	}
}



/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}

-(IBAction)saveText{
	[[NSUserDefaults standardUserDefaults] setObject:userInput.text forKey:kPreferencesEmailAddress];
	NSLog(@"save text : %@", userInput.text);
	// Return the results of attempting to write the preferences to system
	[[NSUserDefaults standardUserDefaults] synchronize];
}

@end
