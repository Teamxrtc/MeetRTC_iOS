//
//  WebRTCStream.m
//
//  Created by Ganvir, Manish on 5/29/14.
//  Copyright 2014 Comcast Cable Communications Management, LLC.
//

#import "WebRTCStream.h"
#import "WebRTCFactory.h"
#import "RTCVideoCapturer.h"
#import "RTCPair.h"
#import "RTCMediaConstraints.h"
#import "WebRTCError.h"
#import "WebRTCLogHandler.h"
#import "WebRTCLogging.h"

NSString* const Stream= @"Stream";

NSString * const WebRTCRecordEventKey = @"WebRTCRecordEventKey";
NSString * const WebRTCRecordEventDetailKey = @"WebRTCRecordEventDetailKey";

@interface WebRTCStream ()
//<RTCMediaStreamRecordingDelegate> v47 changes
    @property (nonatomic) BOOL isRecordingEnabled;
    @property (nonatomic) NSMutableDictionary* recordState;
@property (nonatomic) BOOL isRecordingStarted;
@end


@implementation WebRTCStream

NSString* const TAG6 = @"WebRTCStream";

- (id)initWithDefaultValue:(WebRTCStreamConfig*)_streamConfig;
{
    self = [super init];
    if (self!=nil) {
        streamConfig = _streamConfig;
        camType = streamConfig.camType;
        isStarted = false;
        _recordState = [[NSMutableDictionary alloc]init];
        _isRecordingStarted = false;
        _isRecordingEnabled = false;
    // Get capture device
    cameraID = nil;

    
    // If the camera type is auto, first try back camera and then try front camera
    if ((camType == CAM_TYPE_AUTO) || (camType == CAM_TYPE_BACK))
        requiredPos = AVCaptureDevicePositionBack;
    else
        requiredPos = AVCaptureDevicePositionFront;
    
        cameraID = [self getCameraId:requiredPos];
    
    // Try front camera for auto mode
    if (cameraID == nil)
    {
        // Try front camera
        requiredPos = AVCaptureDevicePositionFront;
        cameraID = [self getCameraId:requiredPos];
        
    }
    
    // If camera not found throw an error
    if (cameraID == nil)
    {
	    /* // To be added later: As the delegate is not yet set, this cannot be done
		   // delegate should be as part of the parameter 
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"The specified camera was busy or not found" forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:Stream
                                             code:ERR_CAMERA_NOT_FOUND
                                            userInfo:details];
        [self.delegate onStreamError:error.description errorCode:error.code]; */
        return NULL;
    }
    
    }
    return self;

}


-(NSString*)getCameraId:(NSInteger)position
{
    NSString* camID;
    AVCaptureDevice *captureDevice;
    for (captureDevice in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo])
    {
        if (captureDevice.position == position) {
            camID = [captureDevice localizedName];
            
            
            break;
        }
    }
    captureDevice = nil;
    return camID;
}
- (id)initWithDefaultValue
{
    self = [super init];
    if (self!=nil) {
        camType = CAM_TYPE_NONE;
        isStarted = false;
    }
    
    return self;
    
}

-(void)localTrack
{
    LogDebug( @" localTrack******");
    
    // Create media stream and add audio track
    lms = [pcfactory mediaStreamWithLabel:@"ARDAMS"];
    [lms addAudioTrack:[pcfactory audioTrackWithID:@"ARDAMSa0"]];
    
    if (camType != CAM_TYPE_NONE)
    {
        BOOL IsVideoCall = [self.delegate isStreamVideoEnable];
        if(IsVideoCall)
        {
       LogDebug(@" localTrack Inside iVideoEnable Check");
            
            //Create Video Capturer
            capturer = [RTCVideoCapturer capturerWithDeviceName:cameraID];
            
            if(!capturer)
            {
                NSError *error = [NSError errorWithDomain:Stream
                                                     code:ERR_VIDEO_CAPTURE
                                                 userInfo:nil];
                [self.delegate onStreamError:error.description errorCode:error.code];
            }
            
            else
            {
                
                NSString *hMinStr = [NSString stringWithFormat: @"%d", (int)streamConfig.hMinResolution];
                NSString *vMinStr = [NSString stringWithFormat: @"%d", (int)streamConfig.vMinResolution];
                NSString *hMaxStr = [NSString stringWithFormat: @"%d", (int)streamConfig.hMaxResolution];
                NSString *vMaxStr = [NSString stringWithFormat: @"%d", (int)streamConfig.vMaxResolution];
                NSString *minFraRateStr = [NSString stringWithFormat: @"%d", (int)streamConfig.minFrameRate];
                NSString *maxFraRateStr = [NSString stringWithFormat: @"%d", (int)streamConfig.maxFrameRate];
                
                //Peer connection constraints
                NSArray * constraintPairs = @[[[RTCPair alloc] initWithKey:@"minHeight" value:vMinStr],
                                              [[RTCPair alloc] initWithKey:@"minWidth"  value:hMinStr],
                                              [[RTCPair alloc] initWithKey:@"maxHeight" value:vMaxStr],
                                              [[RTCPair alloc] initWithKey:@"maxWidth"  value:hMaxStr],
                                              [[RTCPair alloc] initWithKey:@"minFrameRate"  value:minFraRateStr],
                                              [[RTCPair alloc] initWithKey:@"maxFrameRate"  value:maxFraRateStr],

                                              ];
                
                //Peer connection constraints
                //NSArray * constraintPairs = @[[[RTCPair alloc] initWithKey:@"minAspectRatio" value:@"1.6"]];
                RTCMediaConstraints *localMediaConstrains = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:constraintPairs optionalConstraints:nil];
                
                // Enable 4:3 video aspect ratio
                [self setAspectRatio43:streamConfig.aspectRatio43];
                
                //Create Video source
                RTCVideoSource *videoSource = [pcfactory videoSourceWithCapturer:capturer constraints:localMediaConstrains];
                if(!videoSource)
                {
                    NSMutableDictionary* details = [NSMutableDictionary dictionary];
                    [details setValue:@"Unable to apply the constraints" forKey:NSLocalizedDescriptionKey];
                    
                    NSError *error = [NSError errorWithDomain:Stream code:ERR_INVALID_CONSTRAINTS userInfo:details];
                    
                    [self.delegate onStreamError:error.description errorCode:error.code];
                }
                
                else
                {
                    //Create video track
                    localVideoTrack = [pcfactory videoTrackWithID:@"ARDAMSv0" source:videoSource];
                    
                    //Add video track to media stream
                    if (localVideoTrack) {
                    LogDebug(@"Calling localvideo track");
                        //int *p=NULL; *p=1;
                        [lms addVideoTrack:localVideoTrack];
                        [self.delegate OnLocalStream:localVideoTrack];
                        
                        _isRecordingEnabled = true;
                        
                    }
                    else
                    {
                        NSError *error = [NSError errorWithDomain:Stream
                                                         code:ERR_LOCAL_TRACK
                                                     userInfo:nil];
                        [self.delegate onStreamError:error.description errorCode:error.code];
                    }
                }
            
            }

        }
    }
    isStarted = true;
}

- (int)start
{
    // Get the factory to access other PC methods
    pcfactory = [WebRTCFactory getPeerConnectionFactory];
    
    if (pcfactory == nil)
    {
        LogError(@" Error creating peerconnection factory");
        NSError *error = [NSError errorWithDomain:Stream
                                             code:ERR_PC_FACTORY
                                         userInfo:nil];
        [self.delegate onStreamError:error.description errorCode:error.code];
        return -1;
    }
    
    [self localTrack];
    return 0;
}
- (int)stop
{
    //[WebRTCFactory DestroyPeerConnectionFactory];
    if (camType != CAM_TYPE_NONE)
    {
        if(!capturer)
            return ERR_INCORRECT_STATE;
        
        //[capturer stop];
        //capturer= nil;
    }
    _isRecordingEnabled = false;
    lms = nil;
    localVideoTrack = nil;
    isStarted = false;
    cameraID = nil;
    streamConfig = nil;
    pcfactory = nil;
    //[WebRTCFactory DestroyPeerConnectionFactory];

    return OK_NO_ERROR;
}
- (bool)IsStarted
{
    return isStarted;
}

- (RTCMediaStream *)getMediaStream
{
    return lms;
}

-(int)StateErrorCheck
{
    // Check if the stream has been initialised
    if (self == nil)
    {
        LogDebug(@" Stream not initialized !!!");
        return WEBRTC_ERR_INCORRECT_STATE;
    }
    // Check if the stream is started
    if (!isStarted)
    {
        LogDebug(@" Stream not started !!!");
        return WEBRTC_ERR_INCORRECT_STATE;
    }
    
    // Check if the local media stream is available
    if (!lms)
    {
        LogWarn(@" Local media stream not available !!!");
        return WEBRTC_ERR_INCORRECT_STATE;
    }

    return 0;
}
// API to mute the current running track
- (int)muteAudio
{
    int errCode=0;
    LogDebug(@" muteAudio!!!" );

    // Error check
    errCode = [self StateErrorCheck];
    if (errCode != 0)
        return errCode;
    
    LogDebug(@" go through the tracks !!!");

    // Get tracks
    for (RTCMediaStreamTrack *track in lms.audioTracks)
    {
        LogDebug(@" muteAudio, track label %@", track.label );

        if (![track.label compare:@"ARDAMSa0"])  {
            [track setEnabled:false];
            LogInfo(@" muteAudio, track found, muting !!!");
            return 0;
        }
    }
    return WEBRTC_ERR_INCORRECT_STATE;
}
- (int)unmuteAudio
{
    int errCode=0;
    
    // Error check
    errCode = [self StateErrorCheck];
    if (errCode != 0)
        return errCode;
    
    // Get Camera
    for (RTCMediaStreamTrack *track in lms.audioTracks)
    {
        if (![[track label] compare:@"ARDAMSa0"])  {
            [track setEnabled:true];
            LogInfo(@" muteAudio, track found, unmuting !!!" );
            return 0;
        }
    }
    return WEBRTC_ERR_INCORRECT_STATE;
}
- (int)stopVideo
{
    int errCode=0;
    
    // Error check
    errCode = [self StateErrorCheck];
    if (errCode != 0)
        return errCode;
    if (camType == CAM_TYPE_NONE)
        return WEBRTC_ERR_INCORRECT_STATE;
    // Get Camera
    for (RTCMediaStreamTrack *track in lms.videoTracks)
    {
        if (![[track label] compare:@"ARDAMSv0"])  {
            [track setEnabled:false];
            LogInfo(@" muteAudio, track found, stopping video !!!");
            return 0;
        }
    }
    return WEBRTC_ERR_INCORRECT_STATE;
}
- (int)startVideo
{
    int errCode=0;
    
    // Error check
    errCode = [self StateErrorCheck];
    if (errCode != 0)
        return errCode;
    
    if (camType == CAM_TYPE_NONE)
        return WEBRTC_ERR_INCORRECT_STATE;
    
    // Get Camera
    for (RTCMediaStreamTrack *track in lms.videoTracks)
    {

        if (![[track label] compare:@"ARDAMSv0"])  {
            [track setEnabled:true];
            LogInfo(@" startVideo, track found, start video !!!");
            return 0;
        }
    }
    return WEBRTC_ERR_INCORRECT_STATE;
}
- (BOOL)isAudioMuted
{
    int errCode=0;
    
    // Error check
    errCode = [self StateErrorCheck];
    if (errCode != 0)
        return false;
    
    // Get Camera
    for (RTCMediaStreamTrack *track in lms.audioTracks)
    {
        if ([[track label] compare:@"ARDAMSa0"])  {
            return [track isEnabled];
        }
    }
    return false;
}
- (BOOL)isVideoStarted
{
    int errCode=0;
    
    
    // Error check
    errCode = [self StateErrorCheck];
    if (errCode != 0)
        return false;
    
    if (camType == CAM_TYPE_NONE)
        return WEBRTC_ERR_INCORRECT_STATE;
    // Get Camera
    for (RTCMediaStreamTrack *track in lms.videoTracks)
    {
        if ([[track label] compare:@"ARDAMSv0"])  {
            return [track isEnabled];
        }
    }
    return false;
}


-(void)applyStreamConfigChange:(WebRTCStreamConfig*)configParam
{
    LogDebug(@"Inside applyStreamConfigChange");
    for (RTCMediaStreamTrack *track in lms.videoTracks)
    {
        if (![[track label] compare:@"ARDAMSv0"])  {
            
            RTCVideoTrack *newtrack=(RTCVideoTrack *)track;
            [lms removeVideoTrack:newtrack]; //v47 changes
        }
    }
    
    /*for (RTCMediaStreamTrack *track in lms.audioTracks)
    {
        if (![[track label] compare:@"ARDAMSv0"])  {
            [lms removeAudioTrack:track];
        }
    }*/
    
    if(configParam.isFlipCamera)
    {
        if (requiredPos == AVCaptureDevicePositionBack)
            requiredPos = AVCaptureDevicePositionFront;
        else
            requiredPos  = AVCaptureDevicePositionBack;
        
        for (AVCaptureDevice *captureDevice in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo])
        {
            if (captureDevice.position == requiredPos) {
                cameraID = [captureDevice localizedName];
                break;
            }
        }

    }
    
    capturer = [RTCVideoCapturer capturerWithDeviceName:cameraID];
    
    if(!capturer)
    {
        NSError *error = [NSError errorWithDomain:Stream
                                             code:ERR_VIDEO_CAPTURE
                                         userInfo:nil];
        [self.delegate onStreamError:error.description errorCode:error.code];
    }
    
    else
    {
        
        NSString *hMinStr = [NSString stringWithFormat: @"%d", (int)configParam.hMinResolution];
        NSString *vMinStr = [NSString stringWithFormat: @"%d", (int)configParam.vMinResolution];
        NSString *hMaxStr = [NSString stringWithFormat: @"%d", (int)configParam.hMaxResolution];
        NSString *vMaxStr = [NSString stringWithFormat: @"%d", (int)configParam.vMaxResolution];
        NSString *minFraRateStr = [NSString stringWithFormat: @"%d", (int)streamConfig.minFrameRate];
        NSString *maxFraRateStr = [NSString stringWithFormat: @"%d", (int)streamConfig.maxFrameRate];
        
        //Peer connection constraints
        NSArray * constraintPairs = @[[[RTCPair alloc] initWithKey:@"minHeight" value:vMinStr],
                                      [[RTCPair alloc] initWithKey:@"minWidth"  value:hMinStr],
                                      [[RTCPair alloc] initWithKey:@"maxHeight" value:vMaxStr],
                                      [[RTCPair alloc] initWithKey:@"maxWidth"  value:hMaxStr],
                                      [[RTCPair alloc] initWithKey:@"minFrameRate"  value:minFraRateStr],
                                      [[RTCPair alloc] initWithKey:@"maxFrameRate"  value:maxFraRateStr],
                                      
                                      ];
        
        //Peer connection constraints
        //NSArray * constraintPairs = @[[[RTCPair alloc] initWithKey:@"minAspectRatio" value:@"1.6"]];
        RTCMediaConstraints *localMediaConstrains = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:constraintPairs optionalConstraints:nil];
        //Create Video source
        RTCVideoSource *videoSource = [pcfactory videoSourceWithCapturer:capturer constraints:localMediaConstrains];
        if(!videoSource)
        {
            NSMutableDictionary* details = [NSMutableDictionary dictionary];
            [details setValue:@"Unable to apply the constraints" forKey:NSLocalizedDescriptionKey];
            
            NSError *error = [NSError errorWithDomain:Stream code:ERR_INVALID_CONSTRAINTS userInfo:details];
            
            [self.delegate onStreamError:error.description errorCode:error.code];
        }
        
        else
        {
            //Create video track
            localVideoTrack = [pcfactory videoTrackWithID:@"ARDAMSv0" source:videoSource];
            
            //Add video track to media stream
            if (localVideoTrack) {
                [lms addVideoTrack:localVideoTrack];
                [self.delegate OnLocalStream:localVideoTrack];
            }
            else
            {
                NSError *error = [NSError errorWithDomain:Stream
                                                     code:ERR_LOCAL_TRACK
                                                 userInfo:nil];
                [self.delegate onStreamError:error.description errorCode:error.code];
            }
        }
    }
}

- (WebRTCStreamConfig*) getStreamConfig
{
    return streamConfig;
}

- (int)startRecording
{
    //TODO: Implement startRecording functionality
    if(!_isRecordingEnabled)
    {
        LogDebug(@"WebRTC::startRecording Stream has not started yet!!!" );
        return ERR_INCORRECT_STATE;
    }
    
    // Check if recording has already started
    if (_isRecordingStarted)
    {
        LogDebug(@"WebRTC::startRecording recording has already started!!!" );
        return ERR_INCORRECT_STATE;
    }
    
    // Call media stream recording API
    //v47 changes
//    [lms startRecording:streamConfig.recordedFilePath videoquality:(int)streamConfig.recordingQuality videoHeight:[localVideoTrack getVideoHeight] videoWidth:[localVideoTrack getVideoWidth ]  delegate:self];
    
    _isRecordingStarted = true;
    
    return 0;
}

- (int)stopRecording
{
    // Check if recording has already started
    if (!_isRecordingStarted)
    {
        LogDebug(@"WebRTC::startRecording recording has already stopped!!!" );
        return ERR_INCORRECT_STATE;
    }
    
    _isRecordingStarted = false;
    //v47 changes
//    [lms stopRecording];
    
    return 0;
}

- (NSDictionary*)getRecordingStatus
{
    return nil;
}

#pragma mark - RTCMediaStreamRecordingDelegate delegates

// Call back to receive recording events
- (void) onLmsRecordingEvent:(NSDictionary *)state
{
    LogDebug(@"WebRTC::onLmsRecordingEvent state %@", state.description );

    if([self.recordingDelegate conformsToProtocol:@protocol(WebRTCAVRecordingDelegate)] && [self.recordingDelegate respondsToSelector:@selector(onRecordingEvent:)]) {
        
        [_recordState setValuesForKeysWithDictionary:state];
        if ([state[@"Event"] isEqualToString:@"Started"])
        {
            [_recordState setValue:[NSNumber numberWithInteger:WebRTCAVRecordingStarted] forKey:WebRTCRecordEventKey];
        }
        else if ([state[@"Event"] isEqualToString:@"Finished"])
        {
            [_recordState setValue:[NSNumber numberWithInteger:WebRTCAVRecordingEnded] forKey:WebRTCRecordEventKey];
        }
        [self.recordingDelegate onRecordingEvent:_recordState];
    }
}

// Call back to receive recording errors
- (void) onLmsRecordingError:(NSString*)error errorCode:(NSInteger)code
{
    LogDebug(@"WebRTC::onLmsRecordingError error %@", error);

    if([self.recordingDelegate conformsToProtocol:@protocol(WebRTCAVRecordingDelegate)] && [self.recordingDelegate respondsToSelector:@selector(onRecordingError:errorCode:)]) {
        [self.recordingDelegate onRecordingError:error errorCode:code ];
    }
}

// Enable 4:3 video aspect ratio
-(void)setAspectRatio43:(BOOL)value
{
    NSMutableDictionary *aspect = [[NSMutableDictionary alloc]init];
    [aspect setValue:[NSNumber numberWithBool:value]  forKey:@"aspectRatio"];
    [[NSNotificationCenter defaultCenter]postNotificationName:@"AspectRatioChangeNotification" object:nil userInfo:aspect];
}

@end
