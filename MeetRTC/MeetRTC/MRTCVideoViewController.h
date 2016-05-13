//
//  MRTCVideoViewController.h
//  MeetRTC
//
//  Copyright 2015 Comcast Cable Communications Management, LLC.
//

#import <UIKit/UIKit.h>
#import "RTCEAGLVideoView.h"
#import "RTCVideoTrack.h"
//meetrtc sdk
#import "WebRTCSession.h"
#import "WebRTCSessionConfig.h"
#import "WebRTCStackConfig.h"

@interface MRTCVideoViewController : UIViewController <RTCEAGLVideoViewDelegate,UICollectionViewDataSource,UICollectionViewDelegate>
{
    //meetrtc sdk
    WebRTCStack *stack;
    WebRTCSessionConfig* sessionConfigParam;
    WebRTCStackConfig* stackConfigParam;
    WebRTCStreamConfig* streamConfigParam;
    WebRTCStream *stream;
    WebRTCSession *session;
    NSMutableArray *participantsDetails;
    NSMutableArray *participantsTempDetails;
    
}

typedef enum
{
    WebRTCVideoCall,
    WebRTCIncomingOneWay,
    WebRTCIncomingTwoWay
}callType;


@property (strong, nonatomic) IBOutlet RTCEAGLVideoView *remoteView;

@property (strong, nonatomic) IBOutlet UIView *footerView;
@property (strong, nonatomic) IBOutlet UILabel *urlLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (strong, nonatomic) IBOutlet UIView *buttonContainerView;
@property (strong, nonatomic) IBOutlet UIButton *endCallButton;
@property (weak, nonatomic) IBOutlet UIButton *muteButton;
@property (weak, nonatomic) IBOutlet UIButton *videoControlButton;
@property (weak, nonatomic) IBOutlet UIButton *speakerButton;

- (IBAction)videoControlButtonClicked:(id)sender;
- (IBAction)muteButtonClicked:(id)sender;
- (IBAction)speakerButtonClicked:(id)sender;
- (IBAction)flipButtonClicked:(id)sender;


@property (strong, nonatomic) NSString *roomUrl;

@property (weak, nonatomic) IBOutlet UICollectionView *myCollectionView;
@property (assign, nonatomic) CGSize localVideoSize;
@property (assign, nonatomic) CGSize remoteVideoSize;
@property (assign, nonatomic) BOOL isZoom; //used for double tap remote view
- (IBAction)endButtonClicked:(id)sender;

//Auto Layout Constraints used for animations
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *remoteViewTopConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *remoteViewRightConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *remoteViewLeftConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *remoteViewBottomConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *localViewWidthConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *localViewHeightConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *localViewRightConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *localViewBottomConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *footerViewBottomConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *buttonContainerViewLeftConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *thumbviewbottonConstraint;


//meetrtc sdk

@property(nonatomic) BOOL incomingFlag;
@property(nonatomic) callType callTypeValue;
@property(nonatomic) BOOL muteFlag,videoControlFlag;
@property (nonatomic) BOOL isSecured;
@property(nonatomic,retain) NSString *serverId;
@property(nonatomic,retain) NSString *roomId;
@property(nonatomic,retain) NSString *sessionId;
@property(nonatomic,retain) NSString *displayName;
@property(nonatomic,retain) NSString *incomingCallType;
@property (nonatomic , strong) NSDictionary *settingsDetails;

//for speaker
@property(nonatomic) BOOL builtinAudioDevices;
@end
