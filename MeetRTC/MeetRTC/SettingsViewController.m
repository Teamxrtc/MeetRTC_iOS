//
//  SettingsViewController.m
//  AppRTC
//
//  Copyright 2015 Comcast Cable Communications Management, LLC.
//

#define kOFFSET_FOR_KEYBOARD 100.0
#import "SettingsViewController.h"

@interface SettingsViewController ()<UITextFieldDelegate>

@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.tapToDismiss = [[UITapGestureRecognizer alloc]
                         initWithTarget:self
                         action:@selector(dismissKeyboardOnFav)];
    [self.view addGestureRecognizer:self.tapToDismiss];
    self.username.delegate=self;
    self.websocket.delegate=self;
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"config"])
    {
        NSDictionary *urls=[[NSUserDefaults standardUserDefaults] objectForKey:@"config"];
        self.username.text=[urls objectForKey:@"displayName"];
        self.websocket.text=[urls objectForKey:@"socket"];
        if ([[urls objectForKey:@"secured"] caseInsensitiveCompare:@"YES"]==NSOrderedSame)
        {
            [self.securedToggle setOn:YES animated:YES];
        }
        else
        {
            [self.securedToggle setOn:NO animated:YES];
        }
    }
}

-(BOOL)textFieldShouldReturn:(UITextField*)textField;
{
    NSInteger checkNextTag = textField.tag + 1;
    
    // Try to find next responder
    UIResponder* nextResponder = [textField.superview viewWithTag:checkNextTag];
    if (nextResponder)
    {
        // Found next responder
        [nextResponder becomeFirstResponder];
    } else
    {
        // Not found
        [textField resignFirstResponder];
    }

    return NO;
}

- (IBAction)cancelButton:(id)sender
{
    [self.view endEditing:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)saveButton:(id)sender
{
    [self.view endEditing:YES];
    NSString *securedValue=@"NO";
    if (self.securedToggle.isOn)
    {
        securedValue=@"YES";
    }
    NSDictionary *urls=[[NSDictionary alloc]initWithObjectsAndKeys:self.username.text,@"displayName",self.websocket.text,@"socket",securedValue,@"secured", nil];
    
    [[NSUserDefaults standardUserDefaults] setObject:urls forKey:@"config"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self dismissViewControllerAnimated:YES completion:nil];
}
-(void)dismissKeyboardOnFav
{
    [self.view endEditing:YES];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
