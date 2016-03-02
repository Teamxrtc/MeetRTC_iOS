//
//  WebRTCStream.h
//
//  Created by Ganvir, Manish on 5/29/14.
//  Copyright 2014 Comcast Cable Communications Management, LLC.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "RTCSessionDescriptionDelegate.h"
#import "RTCPeerConnectionFactory.h"
#import "RTCPeerConnectionDelegate.h"
#import "RTCVideoTrack.h"
#import "RTCICEServer.h"
#import "RTCMediaStream.h"
#import "WebRTCStreamConfig.h"
#import "WebRTCAVRecordingDelegate.h"

// Error codes returned by APIs
#define WEBRTC_ERR_INCORRECT_PARAMETERS -1
#define WEBRTC_ERR_INCORRECT_STATE      -2

@protocol WebRTCStreamDelegate <NSObject>

- (void) OnLocalStream:(RTCVideoTrack *)videoTrack;
- (void) onStreamError:(NSString*)error errorCode:(NSInteger)code;
- (BOOL) isStreamVideoEnable;
@end
@interface WebRTCStream : NSObject
{
    bool isStarted;
    WebRTCCamera_type_e camType;
    RTCPeerConnectionFactory *pcfactory;
    RTCVideoCapturer *capturer;
    RTCMediaStream *lms;
    NSString * cameraID;
    RTCVideoTrack *localVideoTrack;
    WebRTCStreamConfig* streamConfig;
    AVCaptureDevicePosition requiredPos;

}
@property(nonatomic,assign) id<WebRTCStreamDelegate> delegate;
@property(nonatomic,assign) id<WebRTCAVRecordingDelegate> recordingDelegate;
//@property (nonatomic) WebRTCAVRecording* avRecording;
//Below API's are called from the application for configuring the stream

-(void)applyStreamConfigChange:(WebRTCStreamConfig*)configParam;
- (int)start;
- (int)stop;
- (int)stopVideo;
- (int)startVideo;
- (int)muteAudio;
- (int)unmuteAudio;
//Below API's used for start and stop recording
-(int)startRecording;
-(int)stopRecording;
-(NSDictionary*)getRecordingStatus;
-(void)setAspectRatio43:(BOOL)value;


//Below mentioned API's are for internal purpose only

- (id)initWithDefaultValue:(WebRTCStreamConfig*)_streamConfig;
- (id)initWithDefaultValue;
- (BOOL)isAudioMuted;
- (BOOL)isVideoStarted;
- (bool)IsStarted;
- (RTCMediaStream *)getMediaStream;
-(NSString*)getCameraId:(NSInteger)position;
- (WebRTCStreamConfig*) getStreamConfig;

@end
