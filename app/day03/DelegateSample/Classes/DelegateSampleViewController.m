

#import "DelegateSampleViewController.h"
#import "ValueInputView.h"

@implementation DelegateSampleViewController

- (void)dealloc {
    
    [super dealloc];
}
- (IBAction)buttonClick:(id)sender
{
    ValueInputView *valueView = [[ValueInputView alloc] initWithNibName:@"ValueInputView" bundle:[NSBundle mainBundle]];
    valueView.delegate = self;
    [self setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
    [self presentModalViewController:valueView animated:YES];
}


- (void)passValue:(NSString *)value
{
	label.text = value;
    NSLog(@"the get value is %@", value);
}

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


/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/


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




@end
