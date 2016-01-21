//
//  MRTCViewController.h
//  MeetRTC
//
//  Copyright 2015 Comcast Cable Communications Management, LLC.
//

#import <UIKit/UIKit.h>
#import "MRTCVideoViewController.h"
#import "SettingsViewController.h"

@interface MRTCViewController : UIViewController
{
    MRTCVideoViewController *videoView;
    SettingsViewController *configView;
}
@property (nonatomic , strong) NSDictionary *roomDetails;
@property (nonatomic , strong) NSDictionary *settingsDetails;
@property (weak, nonatomic) IBOutlet UITextField *roomNameField;
@property (weak, nonatomic) IBOutlet UIButton *joinButtonOutlet;
@property (weak, nonatomic) IBOutlet UILabel *roomValidationField;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *roomValidateHeight;
- (IBAction)configButton:(id)sender;
- (IBAction)joinButton:(id)sender;
- (IBAction)refreshButton:(id)sender;
@end
