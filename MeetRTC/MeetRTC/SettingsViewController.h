//
//  SettingsViewController.h
//  AppRTC
//
//  Copyright 2015 Comcast Cable Communications Management, LLC.
//

#import <UIKit/UIKit.h>

@interface SettingsViewController : UIViewController
@property (strong, nonatomic) UITapGestureRecognizer *tapToDismiss;
- (IBAction)cancelButton:(id)sender;
- (IBAction)saveButton:(id)sender;
@property (weak, nonatomic) IBOutlet UITextField *username;
@property (weak, nonatomic) IBOutlet UITextField *websocket;
@property (weak, nonatomic) IBOutlet UISwitch *securedToggle;
@end
