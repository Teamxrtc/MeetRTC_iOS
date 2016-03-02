//
//  WebRTCSession.h
//  meet-webrtc-sdk
//
//  Created by Pankaj on 26/08/14.
//  Copyright 2014 Comcast Cable Communications Management, LLC.
//

#ifndef WEBRTC_SESSION_H
#define WEBRTC_SESSION_H

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "RTCSessionDescriptionDelegate.h"
#import "RTCPeerConnectionFactory.h"
#import "RTCPeerConnectionDelegate.h"
#import "RTCVideoTrack.h"
#import "RTCICEServer.h"
#import "RTCMediaStream.h"
#import "WebRTCStack.h"
#import "DTMF.h"
#import "WebRTCStatsCollector.h"
#import "RTCStatsDelegate.h"
#import "WebRTCStatReport.h"
#import "WebRTCSessionConfig.h"
#import "WebRTCStackConfig.h"
#import "RTCDataChannel.h"
@class WebRTCStatsCollector,WebRTCStatReport,WebRTCSessionConfig,WebRTCStackConfig;

typedef enum
{
    starting,
    active,
    call_connecting,
    ice_connecting,
    inactive
} State;

typedef enum
{
    WebRTCBadNetwork = 1,
    WebRTCPoorNetwork = 2,
    WebRTCFairNetwork = 3,
    WebRTCGoodNetwork = 4,
    WebRTCExcellentNetwork = 5
    
} NetworkQuality;

typedef enum
{
    NetworkQualityIndicator
    
} EventType;

/* Keys for setting network data info */
extern NSString * const WebRTCNetworkQualityLevelKey;
extern NSString * const WebRTCNetworkQualityReasonKey;

@protocol WebRTCSessionDelegate <NSObject>

- (void) onSessionEnd:(NSString*) msg;
- (void) onSessionConnecting;
- (void) onDisplayMsg:(NSString*)msg;
- (void) onSessionRenegotiation;
- (void) onSessionConnect;
- (void) onSessionAck:(NSString *)SessiondId;

- (void) sessionHasVideoTrack:(RTCMediaStream *)media :(int)position;
- (void) sessionHasMedia:(RTCMediaStream *)media :(NSArray *)allmedias;
- (void) sessionRemoveMedia:(RTCMediaStream *)media :(NSArray *)allmedias;
- (void) sessionRemoveVideoTrack;
- (void) onSessionError:(NSString*)error errorCode:(NSInteger)code additionalData:(NSDictionary *)additionalData;
- (void) onReceiveStats:(NSDictionary*)toApp;
- (void) onReceivingSdkLogs:(NSString*)str severity:(int)sev;
- (void) onImageReceived:(NSString*)filePath;
- (void) finalStats:(NSMutableDictionary*)obj streamInfo:(NSMutableDictionary*)streamInfo ;

/*
 Event Type - Provide different session event e.g. NetworkQualityChanged
 Event Data -  Provide the network state (e.g. WebRTCWeakNetwork,WebRTCStrongNetwork etc)  and
 reason for the state */
- (void) onSessionEvent:(EventType)eventType eventData:(NSDictionary*)eventData;


/* Session delegate for data channel*/

//Delegate to recieve filepath of the recived image using data channel
- (void) onSessionDataWithImage:(NSString*)filePath;
//Delegate to recieve text data using data channel
- (void) onSessionDataWithText:(NSString*)filePath;
- (void) onConfigMessage_xcmav:(NSString*) msg;

// XMPP delegates
- (void) onRoomJoined:(NSString *)RoomName;
@end


@interface WebRTCSession : NSObject <RTCSessionDescriptionDelegate,RTCPeerConnectionDelegate,RTCStatsDelegate,RTCDataChannelDelegate>
{
    // Signalling server related parameters
//    NSString *FromCaller;
//    NSString *ToCaller;
    NSString *clientSessionId;
    NSString *rtcgSessionId;
    NSString *rtcgid;
    NSString *Uid;
    NSString *DisplayName;
    NSString *ApplicationContext;
    NSString *AppId;
    NSString *peerConnectionId ;
    NSString *dtlsFlagValue;
    NSTimer *_statsTimer;
    // Peerconnection related parameters
    RTCPeerConnectionFactory *factory;
    RTCPeerConnection *peerConnection;
    //RTCVideoRenderer *renderer;
    RTCVideoTrack *videoTrack;
    RTCMediaConstraints *mediaConstraints, *pcConstraints;
    RTCMediaStream *lms;
    NSMutableArray *updatedIceServers;
    NSMutableArray *queuedRemoteCandidates;
    
    NSData *options;
    State state;
    RTCICEConnectionState newICEConnState;
    
    // Internal parameters
    WebrtcSessionCallTypes callType;
    //WebrtcSessionOptions_t sessionOptions;
    
    WebRTCStack *webrtcstack;
    WebRTCStream *localstream;
    
    //sdp parameter
    NSDictionary *initialSDP;
    
    // Incoming parameter
   // BOOL incoming;
   
   //For local sdp
    RTCSessionDescription* localsdp;
    NSMutableArray* allcandidates;
    BOOL isCandidateSent;
    
    BOOL isChannelAPIEnable;
    BOOL isXMPPEnable;
	WebRTCStatsCollector *statcollector;
    WebRTCStatReport* lastSr;
    
    WebRTCSessionConfig* sessionConfig;
    NSDictionary* eligibilityToken;
    NSDictionary* _iceServers;
    NSString* serverURL;
    NSURLSessionDataTask *dataTask;
    BOOL isVideoSuspended;
    BOOL isReOffer;
    NSString* turnIPToStat;
    NSString* turnUsedToStat;
    BOOL dataFlagEnabled;
    int conferenceFlag;
	NSString *fromJid;
    NSMutableArray *msidsSession;
    NSMutableArray *streamsSession;
}


@property(nonatomic,assign) id<WebRTCSessionDelegate>delegate;


/* Below API's are called from the application for configuring the session*/

- (void)setDTLSFlag:(BOOL)value;
-(void)applySessionConfigChanges:(WebRTCSessionConfig*)configParam;
- (void)onUserConfigSelection:(NSDictionary*)json;
- (void)disconnect;
- (NSDictionary *)getRemotePartyInfo;

// DataChannel: API's to send image and text data using data channel
-(void)sendDataWithImage:(NSString*)filePath;
-(void)sendDataWithText:(NSString*)_textMsg;




/* Below API's are used for internal purpose only */

- (WebRTCSession *)initWithDefaultValue:(WebRTCStack *)stack arClientSessionId:(NSString*)arClientSessionId  _configParam:(WebRTCSessionConfig *)_sessionConfig _stream:(WebRTCStream *)_stream _appdelegate:(id<WebRTCSessionDelegate>)_appdelegate  _statcollector:(WebRTCStatsCollector *)_statcollector;
- (WebRTCSession *)initRTCGSessionWithDefaultValue:(WebRTCStack *)stack arClientSessionId:(NSString*)arClientSessionId  _configParam:(WebRTCSessionConfig *)_sessionConfig _stream:(WebRTCStream *)_stream _appdelegate:(id<WebRTCSessionDelegate>)_appdelegate  _statcollector:(WebRTCStatsCollector *)_statcollector _serverURL:(NSString*)_serverURL;
- (WebRTCSession *)initWithXMPPValue:(WebRTCStack *)stack  _configParam:(WebRTCSessionConfig *)_sessionConfig _stream:(WebRTCStream *)_stream _appdelegate:(id<WebRTCSessionDelegate>)_appdelegate  _statcollector:(WebRTCStatsCollector *)_statcollector;

- (WebRTCSession *)initWithIncomingSession:(WebRTCStack *)stack arClientSessionId:(NSString*)arClientSessionId  _stream:(WebRTCStream *)_stream _appdelegate:(id<WebRTCSessionDelegate>)_appdelegate channelapi:(BOOL)_isChannelAPIEnable _statcollector:(WebRTCStatsCollector *)_statcollector _configParam:(WebRTCSessionConfig *)_sessionConfig;
- (void)start;
- (void)start:(NSDictionary *)iceServers;
- (void)sendMessage:(NSData*)msg;
- (void)onSessionSignalingMessage:(NSDictionary*)msg;
- (void)onSignalingMessage:(id)msg;
-(void)sendToChannel:(NSDictionary*)msg;
-(void)closeSession;
-(void)reconnectSession;
- (void)sendDTMFTone:(Tone)_tone;
-(NSString*)getClientSessionId;
-(void)getStreamStatsTimer;
-(void)sendCapability;
-(NSDictionary *) getCapabilityData;
-(void)bandwidthCheck:(NSInteger)BW;
-(void)sendFlag:(BOOL)statFlag;
-(void)updateMediaConstraints:(NSInteger)min max:(NSInteger)max;
-(void)onCapabilityMessage:(NSDictionary*)msg;
-(void)getLogToApp;
//For checking network state
-(void)networkReconnected;
-(void)checkNetworkState;
-(NetworkQuality)checkNetworkState_IncomingStats;
-(void)updateRTTLevel:(NSInteger)rttValue;
-(void)updatePacketLossLevel:(NSInteger)packetLossValue;
-(void)updateSendBWLevel:(NSInteger)sendBWValue;
-(void)sendMessage:(NSString*)targetId json:(NSDictionary*)json;
-(void)dataFlagEnabled:(BOOL)_dataFlag;

//Below API's used to create and send data using data channel
-(void)createDataChannel:(NSString*)channelLabel;
-(void)sendCompressedImageData:(NSData*)imgData;

-(void)setXMPPEnable:(BOOL)val;
-(void)setFromJid:(NSString*)jidFrom;
-(void)setRoomId:(NSString*)roomId;
@end
#endif
