//
//  MRTCViewController.m
//  MeetRTC
//
//  Copyright 2015 Comcast Cable Communications Management, LLC.
//

#import "MRTCViewController.h"
#import "Reachability.h"

@interface MRTCViewController ()<UITextFieldDelegate>

@end

@implementation MRTCViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    videoView=[[MRTCVideoViewController alloc]init];
    configView = [[SettingsViewController alloc] initWithNibName:@"SettingsViewController" bundle:nil];
    self.settingsDetails=[[NSDictionary alloc]init];
    self.roomNameField.delegate=self;
    [self.roomNameField addTarget:self
                         action:@selector(textFieldDidChange:)
               forControlEvents:UIControlEventEditingChanged];
    

}
//Internet Connectivity
-(BOOL)internetAvailability
{
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    [reachability startNotifier];
    NetworkStatus remoteHostStatus = [reachability currentReachabilityStatus];
    
    if(remoteHostStatus == ReachableViaWiFi || remoteHostStatus == ReachableViaWWAN)
    {
        return YES;
    }
    else
    {
        return NO;
    }
    
}
-(void)refreshName
{
    NSArray *wordsArray=[[NSArray alloc]initWithObjects:@"infosys",@"comcast",@"simple",@"random",@"testing",@"meeting",@"client",@"people",@"message",@"notes",@"online",@"offline",@"secure",@"member",@"bridge",@"caller",@"mobile",@"learn",@"share",@"screen",@"apple",@"monday",@"camera",@"books",@"store",@"flight",@"friend",@"sunday",@"world",@"target", nil];
    self.roomNameField.text = [wordsArray objectAtIndex:(arc4random() % 30)];

}
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self refreshName];
    [[self navigationController] setNavigationBarHidden:NO animated:YES];
    self.settingsDetails=[[NSUserDefaults standardUserDefaults] objectForKey:@"config"];
    if (self.roomNameField.text.length>=5)
    {
        [self enableUIState];
    }
    else
    {
        [self resetUIState];
    }
}

- (IBAction)configButton:(id)sender
{
    [self presentViewController:configView animated:YES completion:nil];
}

- (IBAction)joinButton:(id)sender
{
    if ([self internetAvailability])
    {
        NSDictionary *details=[[NSDictionary alloc]initWithObjectsAndKeys:self.roomNameField.text,@"room",[self.settingsDetails objectForKey:@"socket"],@"socket",[self.settingsDetails objectForKey:@"displayName"],@"displayName",[self.settingsDetails objectForKey:@"secured"],@"secured", nil];
        
        [self performSegueWithIdentifier:@"videoView" sender:details];
    }
    else
    {
        
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Check Internet Connectivity"
                                                                       message:@"Turn On wifi/Mobile data"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* ok = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {}];
    
        
        [alert addAction:ok];

        [self presentViewController:alert animated:YES completion:nil];
    }
   
}

- (IBAction)refreshButton:(id)sender
{
    [self refreshName];
}

//disabling ui elements with animation
-(void)resetUIState
{
    [UIView animateWithDuration:0.3f animations:^{
        [self.roomValidateHeight setConstant:25.0f];
        [self.view layoutIfNeeded];
    }];
    [self.joinButtonOutlet setBackgroundColor:[UIColor grayColor]];
    [self.joinButtonOutlet setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [self.joinButtonOutlet setEnabled:NO];
    [self.roomValidationField setHidden:NO];
    
}

//enabling ui elements with animation
-(void)enableUIState
{
    [UIView animateWithDuration:0.3f animations:^{
        [self.roomValidateHeight setConstant:0.0f];
        [self.view layoutIfNeeded];
    }];
    [self.roomValidationField setHidden:YES];
    [self.joinButtonOutlet setEnabled:YES];
    [self.joinButtonOutlet setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.joinButtonOutlet setBackgroundColor:[UIColor colorWithRed:66.0f/255.0f green:133.0f/255.0f blue:244.0f/255.0f alpha:1.0f]];
}

#pragma mark - UITextField Delegate

-(BOOL)textFieldShouldReturn:(UITextField*)textField;
{
    [textField resignFirstResponder];
    return NO;
}
-(void)textFieldDidChange :(UITextField *)theTextField
{
    if (theTextField.text.length>=5)
    {
        [self enableUIState];
    }
    else
    {
        [self resetUIState];
    }
}
#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    videoView= (MRTCVideoViewController *)[segue destinationViewController];
    NSDictionary *loadDetails=(NSDictionary *)sender;
    [videoView setServerId:[loadDetails objectForKey:@"socket"]];
    [videoView setIncomingFlag:NO];
    [videoView setRoomId:[loadDetails objectForKey:@"room"]];
    if ([[loadDetails objectForKey:@"secured"] caseInsensitiveCompare:@"YES"]==NSOrderedSame)
    {
        [videoView setIsSecured:YES];
    }
    else
    {
        [videoView setIsSecured:NO];
    }
    [videoView setDisplayName:[loadDetails objectForKey:@"displayName"]];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
