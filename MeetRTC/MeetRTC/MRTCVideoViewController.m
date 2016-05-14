//
//  MRTCVideoViewController.m
//  MeetRTC
//
//  Copyright 2015 Comcast Cable Communications Management, LLC.
//

#import "MRTCVideoViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface MRTCVideoViewController () <WebRTCStackDelegate,WebRTCSessionDelegate,UIAlertViewDelegate>
@property (nonatomic , strong) NSMutableArray *cellsReference;
@end

@implementation MRTCVideoViewController

@synthesize roomId,sessionId,isSecured;


- (void)viewDidLoad {
    [super viewDidLoad];
    self.cellsReference=[[NSMutableArray alloc]init];
    self.urlLabel.text=[NSString stringWithFormat:@"%@/%@",self.serverId,roomId];
    self.isZoom = NO;
    participantsDetails=[[NSMutableArray alloc]init];
    participantsTempDetails=[[NSMutableArray alloc]init];
    self.muteFlag=NO;
    self.videoControlFlag=NO;
    //Add Tap to hide/show controls
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleButtonContainer)];
    [tapGestureRecognizer setNumberOfTapsRequired:1];
    [self.remoteView addGestureRecognizer:tapGestureRecognizer];
    
    //Add Double Tap to zoom
//    tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(zoomRemote)];
//    [tapGestureRecognizer setNumberOfTapsRequired:2];
//    [self.view addGestureRecognizer:tapGestureRecognizer];
    
    //RTCEAGLVideoViewDelegate provides notifications on video frame dimensions
    [self.remoteView setDelegate:self];
    
    //Getting Orientation change
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationChanged:)
                                                 name:@"UIDeviceOrientationDidChangeNotification"
                                               object:nil];
    
    
    [self startAllServices];
    
    //Conference - more than one participant
    
    _myCollectionView.dataSource=self;
    _myCollectionView.delegate=self;
    
    
    //for speaker
     _builtinAudioDevices = true;
}
-(void)startAllServices
{
    //defaults
    
    //Stack configuration
    stackConfigParam = [[WebRTCStackConfig alloc] initRTCGWithDefaultValue:self.serverId _userId:@"" _usingRTC20:true];
    //stackConfigParam.userName = @"My Name";
    //stackConfigParam.portNumber = 80;
    stack = [[WebRTCStack alloc] initWithRTCG:stackConfigParam  _appdelegate:self];
    [stack setVideoBridgeEnable:TRUE];
    
    //Session configuration
    sessionConfigParam = [[WebRTCSessionConfig alloc]init];
    sessionConfigParam.deviceID =[[[UIDevice currentDevice] identifierForVendor] UUIDString];
    sessionConfigParam.appName = @"MeetRTC";
    sessionConfigParam.displayName = self.displayName;
    sessionConfigParam.rtcgSessionId = roomId;
    sessionConfigParam.isSecured=isSecured;
    sessionConfigParam.isConfigChange = false;
    sessionConfigParam.notificationRequired = false;
    
    //Stream configuration
    streamConfigParam = [[WebRTCStreamConfig alloc]init];
    streamConfigParam.camType = CAM_TYPE_FRONT;
    /*streamConfigParam.hMinResolution = 300;
     streamConfigParam.vMinResolution = 200;
     streamConfigParam.hMaxResolution = 400;
     streamConfigParam.vMaxResolution = 300;*/
    streamConfigParam.maxFrameRate = 30;
    streamConfigParam.minFrameRate = 20;
    
    sessionConfigParam.streamConfig = streamConfigParam;
    
    stream = [stack createStream:streamConfigParam _recordingDelegate:self];
    [self startSession];
}
-(void)startSession
{
    WebrtcSessionOptions_t opt;
    sessionConfigParam.sessionOptions = &opt;
    sessionConfigParam.callType = outgoing;
    session = [stack createSession:stream _appdelegate:self _configParam:sessionConfigParam];
    [session setDTLSFlag:TRUE];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    
    [[self navigationController] setNavigationBarHidden:YES animated:YES];
    
    self.myCollectionView.hidden=YES;
    //XMPP
    //Display the Local View full screen while connecting to Room
    [self.localViewBottomConstraint setConstant:0.0f];
    [self.localViewRightConstraint setConstant:0.0f];
    [self.localViewHeightConstraint setConstant:self.view.frame.size.height];
    [self.localViewWidthConstraint setConstant:self.view.frame.size.width];
    [self.footerViewBottomConstraint setConstant:0.0f];
    [self.view bringSubviewToFront:self.footerView];
    
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    if (participantsTempDetails.count<=1) {
        return 0;
    }
    else
    {
        return participantsTempDetails.count;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString *identifier = @"Cell";
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    
    RTCEAGLVideoView *collectionVideoView = (RTCEAGLVideoView *)[cell viewWithTag:10];
    
    [self resetCells:collectionVideoView];
    [collectionVideoView renderFrame:nil];

    [[participantsTempDetails objectAtIndex:indexPath.row] addRenderer:collectionVideoView];

    return cell;
    
}
- (void)collectionView:(UICollectionView *) collectionView didSelectItemAtIndexPath:(NSIndexPath *) indexPath {
    
    [self resetViews];
    [[participantsTempDetails objectAtIndex:indexPath.row] addRenderer:self.remoteView];
    [_myCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row inSection:0]
                              atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                      animated:YES];
    
}
//TODO:handle remote disconnect
- (void)applicationWillResignActive:(UIApplication*)application {
    [self disconnect];
}

//- (void)orientationChanged:(NSNotification *)notification{
//    [self videoView:self.remoteView didChangeVideoSize:self.localVideoSize];
//    [self videoView:self.remoteView didChangeVideoSize:self.remoteVideoSize];
//}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)disconnect {
    
    [self resetViews];
    [self.remoteView renderFrame:nil];

    if (stream)
    {
        [stream stop];
        stream = nil;
    }
    if (session)
    {
        [session disconnect];
    }
    [stack disconnect];
    stream = nil;
    session = nil;
    stack = nil;
    streamConfigParam = nil;
    sessionConfigParam = nil;
    stackConfigParam = nil;
    
}

//TODO:handle remote disconnect
- (void)remoteDisconnected {
    
}

- (void)toggleButtonContainer {
    [UIView animateWithDuration:0.3f animations:^{
        
        //Adjust the values to hide or show views
        if (self.buttonContainerViewLeftConstraint.constant <= -40.0f) {
            [self.buttonContainerViewLeftConstraint setConstant:20.0f];
            [self.buttonContainerView setAlpha:1.0f];
        } else {
            [self.buttonContainerViewLeftConstraint setConstant:-40.0f];
            [self.buttonContainerView setAlpha:0.0f];
        }
        
        if (self.thumbviewbottonConstraint.constant<=-150.0f)
        {
            [self.thumbviewbottonConstraint setConstant:22.0f];
            [self.myCollectionView setAlpha:1.0f];
        }
        else {
            [self.thumbviewbottonConstraint setConstant:-150.0f];
            [self.buttonContainerView setAlpha:0.0f];
        }
        [self.view layoutIfNeeded];
    }];
}

//- (void)zoomRemote {
//    //Toggle Aspect Fill or Fit
//    self.isZoom = !self.isZoom;
//    [self videoView:self.remoteView didChangeVideoSize:self.remoteVideoSize];
//}

- (IBAction)endButtonClicked:(id)sender
{
    //Clean up
    [self disconnect];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

#pragma mark - RTCEAGLVideoViewDelegate

- (void)videoView:(RTCEAGLVideoView *)videoView didChangeVideoSize:(CGSize)size {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
        
        if (orientation == UIDeviceOrientationLandscapeLeft || orientation == UIDeviceOrientationLandscapeRight)
        {
            NSLog(@"orientation landscape");
        }
        else
        {
            NSLog(@"orientation protrait");
        }
        self.remoteVideoSize=size;
        CGSize defaultAspectRatio = CGSizeMake(4, 3);
        CGSize remoteAspectRatio = CGSizeEqualToSize(self.remoteVideoSize, CGSizeZero) ?
        defaultAspectRatio : self.remoteVideoSize;
        
        // This is needed as the resolution has to be divisible by 16 for perfect decoding
        // so in order to fit in the screen, the following code is required
        float aspectRatioOfBounds = (self.view.bounds.size.width/self.view.bounds.size.height);
        float aspectRatioOfRemote = (remoteAspectRatio.width/remoteAspectRatio.height);
        if((aspectRatioOfRemote <= (aspectRatioOfBounds * 1.05)) && (aspectRatioOfRemote >= (aspectRatioOfBounds * 0.95)))
        {
            self.remoteView.frame = self.view.bounds;
        }
        else
        {
            CGRect remoteVideoFrame =
            AVMakeRectWithAspectRatioInsideRect(remoteAspectRatio,
                                                self.view.bounds);
            self.remoteView.frame = remoteVideoFrame;
            
        }
        [self.view layoutIfNeeded];
        [self.myCollectionView reloadData];
    });
}
#pragma mark - WebRTCStack Delegate

- (void) startLocalDisplay:(RTCVideoTrack *)videoTrack
{
    //changes for handling camera flip
    if (participantsTempDetails.count>0)
    {
        [participantsTempDetails removeObjectAtIndex:0];
        [participantsTempDetails insertObject:videoTrack atIndex:0];
        
        [self resetViews];
        [[participantsTempDetails lastObject] addRenderer:self.remoteView];
    }
    else
    {
        [videoTrack addRenderer:self.remoteView];
        [participantsTempDetails addObject:videoTrack];
    }
   
    [self.myCollectionView reloadData];
}
- (void) showStatus:(NSString *)msg
{
    NSLog(@"showStatus %@", msg);
}
- (void) onDisconnect:(NSString *)msg
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"Disconnected due to %@", msg);
        [self disconnect];
        [self.navigationController popToRootViewControllerAnimated:YES];
    });
}

- (void) onStackError:(NSString *)error errorCode:(NSInteger)code
{
    NSLog(@"onStackError %@", error);
}

#pragma mark - WebRTCSession Delegate

- (void) onSessionConnect
{
    NSLog(@"onSessionConnect");
}
- (void) onSessionConnecting
{
    NSLog(@"onSessionConnecting");
}
- (void) onSessionEnd:(NSString*) msg
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"Disconnected due to %@", msg);
        if ([msg caseInsensitiveCompare:@"Remote disconnection"]==NSOrderedSame || [msg caseInsensitiveCompare:@"Remote left room"]==NSOrderedSame) {
            [self remoteDisconnected];
        }
        else
        {
            [self disconnect];
            [self.navigationController popToRootViewControllerAnimated:YES];
        }
        
    });

}
- (void) onSessionError:(NSString*)error errorCode:(NSInteger)code additionalData:(NSDictionary *)additionalData
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"Disconnected due to %@", error);
        [self disconnect];
        [self.navigationController popToRootViewControllerAnimated:YES];
    });
}
-(void)sessionHasMedia:(RTCMediaStream *)media :(NSArray *)allmedias
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        participantsDetails= [allmedias mutableCopy];
        self.myCollectionView.hidden=NO;
        for (int i=0; i<participantsDetails.count; i++)
        {
            RTCMediaStream *media = [[participantsDetails objectAtIndex:i] objectForKey:@"streamInfo"];
            
            if ((participantsTempDetails.count-1)>i)
            {
                [participantsTempDetails replaceObjectAtIndex:i+1 withObject:[media.videoTracks objectAtIndex:0]];
            }
            else
            {
                [participantsTempDetails addObject:[media.videoTracks objectAtIndex:0]];
            }
            
        }
        [self resetViews];
        [[media.videoTracks objectAtIndex:0] addRenderer:self.remoteView];
        
        [self.myCollectionView reloadData];
        [self.myCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:(participantsTempDetails.count-1) inSection:0]
                                  atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                          animated:YES];

        
//        [self.view bringSubviewToFront:self.buttonContainerView];
        [self.view bringSubviewToFront:self.myCollectionView];
        if (allmedias.count==0)
        {
            self.myCollectionView.hidden=YES;
            self.footerView.hidden=NO;
        }
        else
        {
            self.myCollectionView.hidden=NO;
            self.footerView.hidden=YES;
        }
    });
}
-(void)sessionRemoveMedia:(RTCMediaStream *)media :(NSArray *)allmedias
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        participantsDetails= [allmedias mutableCopy];
        for (int i=1; i<participantsTempDetails.count; i++)
        {
            
            if (participantsDetails.count>=i)
            {
                RTCMediaStream *media = [[participantsDetails objectAtIndex:(i-1)] objectForKey:@"streamInfo"];
                [participantsTempDetails replaceObjectAtIndex:i withObject:[media.videoTracks objectAtIndex:0]];
            }
            else
            {
                [participantsTempDetails removeObjectAtIndex:i];
            }
            
        }
        [self resetViews];
        [[participantsTempDetails objectAtIndex:(participantsTempDetails.count-1)] addRenderer:self.remoteView];
        [self.myCollectionView reloadData];
       //[self.view bringSubviewToFront:self.buttonContainerView];
        
        if (allmedias.count==0)
        {
            self.myCollectionView.hidden=YES;
            self.footerView.hidden=NO;
        }
        else
        {
            [self.view bringSubviewToFront:self.myCollectionView];
            [self.myCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:(participantsTempDetails.count-1) inSection:0]
                                          atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                                  animated:YES];
            self.myCollectionView.hidden=NO;
            self.footerView.hidden=YES;
        }
    });
}
-(void)resetViews
{
    for (int i=0; i<participantsTempDetails.count; i++)
    {
        [[participantsTempDetails objectAtIndex:i] removeRenderer:self.remoteView];
    }
    [self.remoteView renderFrame:nil];
}
-(void)resetCells :(RTCEAGLVideoView *)collectionVideoView
{
    for (int i=0; i<participantsTempDetails.count; i++)
    {
        [[participantsTempDetails objectAtIndex:i] removeRenderer:collectionVideoView];
    }
    [self.remoteView renderFrame:nil];
}
#pragma mark - XMPP Delegate

- (void) onRoomJoined:(NSString *)RoomName
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@" room %@",RoomName);
        self.statusLabel.text=@"Waiting for someone to join this room:";
    });
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UIDeviceOrientationDidChangeNotification" object:nil];
    [self disconnect];
    [participantsDetails removeAllObjects];
    self.muteFlag=NO;
    self.videoControlFlag=NO;
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)videoControlButtonClicked:(id)sender {
    if (self.videoControlFlag==NO)
    {
        [_videoControlButton setImage:[UIImage imageNamed:@"videoOff.png"] forState:UIControlStateNormal];
        [stream stopVideo];
        NSDictionary *json = @{@"type" : @"configselection" , @"reason" : @"Remote party has shuttered"};
        [session onUserConfigSelection:json];
        self.videoControlFlag=YES;
    }
    else
    {
        [_videoControlButton setImage:[UIImage imageNamed:@"videoOn.png"] forState:UIControlStateNormal];
        [stream startVideo];
        NSDictionary *json = @{@"type" : @"configselection" , @"reason" : @"Remote party has Unshuttered"};
        [session onUserConfigSelection:json];
        self.videoControlFlag=NO;
        
    }
}
- (IBAction)muteButtonClicked:(id)sender {
    if (self.muteFlag==NO)
    {
        self.muteFlag=YES;
        [_muteButton setBackgroundImage:[UIImage imageNamed:@"mute.png"] forState:UIControlStateNormal];
        [stream muteAudio];
        NSDictionary *json = @{@"type" : @"configselection" , @"reason" : @"Remote party has Muted"};
        [session onUserConfigSelection:json];
    }
    else
    {
        self.muteFlag=NO;
        [_muteButton setBackgroundImage:[UIImage imageNamed:@"unmute.png"] forState:UIControlStateNormal];
        [stream unmuteAudio];
        NSDictionary *json = @{@"type" : @"configselection" , @"reason" : @"Remote party has Unmuted"};
        [session onUserConfigSelection:json];
        
    }
}

- (IBAction)speakerButtonClicked:(id)sender {
    if(_builtinAudioDevices)
    {
        [stack switchSpeaker:_builtinAudioDevices];
        [self.speakerButton setBackgroundImage:[UIImage imageNamed:@"speakerOff"] forState:UIControlStateNormal];
        _builtinAudioDevices = false;
    }
    else
    {
        [stack switchSpeaker:_builtinAudioDevices];
        [self.speakerButton setBackgroundImage:[UIImage imageNamed:@"speakerOn"] forState:UIControlStateNormal];
        _builtinAudioDevices = true;
    }
}

- (IBAction)flipButtonClicked:(id)sender {
    
    sessionConfigParam.isConfigChange = true;
    streamConfigParam.isFlipCamera = true;
    sessionConfigParam.streamConfig = streamConfigParam;
    
    dispatch_async(dispatch_get_main_queue(), ^(void){
        if(session != nil)
        {
            [session applySessionConfigChanges:sessionConfigParam];
        }
        else
        {
            [stream applyStreamConfigChange:streamConfigParam];
        }
        
    });

}
-(void) onAudioSessionRouteChanged:(NSNotification*)notification
{
    if(stack.isHeadsetAvailable)
    {
        [self.speakerButton setBackgroundImage:[UIImage imageNamed:@"speakerOn"] forState:UIControlStateNormal];
        _builtinAudioDevices = true;
        [stack switchMic:false];
    }
    else
    {
        [stack switchMic:true];
    }
    
}
- (void)orientationChanged:(NSNotification *)notification{
    
    [self videoView:self.remoteView didChangeVideoSize:self.remoteVideoSize];
}
@end
