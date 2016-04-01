//
//  WebRTCStack.h
//  meet-webrtc-sdk
//
//  Created by Pankaj on 26/08/14.
//  Copyright 2014 Comcast Cable Communications Management, LLC.
//
#ifndef WEBRTC_STACK_H
#define WEBRTC_STACK_H

#import <Foundation/Foundation.h>
#import "RTCPeerConnectionFactory.h"
#import "WebRTCUtil.h"
#import "WebRTCStream.h"
#import "WebRTCStatsCollector.h"
#import "WebRTCHTTP.h"
#import "WebRTCSessionConfig.h"
#import "WebRTCStackConfig.h"
#import "Reachability.h"


@class WebRTCSession,WebRTCHTTP,WebRTCStatsCollector, WebRTCStackConfig;
@protocol WebRTCSessionDelegate;

typedef enum
{
    rtc_server_message,
    reg_server_message,
    auth_server_message,
} EventTypes;

typedef enum : NSInteger
{
    nonetwork,
    cellular2g,
    cellular3g,
    cellular4g,
    cellularLTE,
    wifi
    
} NetworkTypes;

typedef enum : NSInteger {
    Disconnected = 0,
    SocketConnecting,
    SocketConnected,
    SocketDisconnect,
    SocketReconnecting,
    SocketReconnected
} NetworkState;

@protocol WebRTCStackDelegate <NSObject>

- (void) onOffer : (NSString*)from to:(NSString*)to;
- (void) onReady:(NSArray*) alias;
- (void) onDisconnect:(NSString*)msg;
- (void) onStackError:(NSString*)error errorCode:(NSInteger)code;
- (void) startLocalDisplay:(RTCVideoTrack *)videoTrack;
- (void) onRegister;
- (BOOL)isVideoEnable;
- (void) showStatus:(NSString*)msg;
- (void) onStateChange:(NetworkState)state;

//for speaker
- (void) onAudioSessionRouteChanged:(NSNotification*)notification;
@end

@interface WebRTCStack : NSObject<WebRTCStreamDelegate,WebRTCHTTPDelegate>
{
    NSDictionary *sessions;
    WebRTCHTTP* httpconn;
    NSData *wsToken;
    NSString *emailId;
    NSString *clientSessionId;
    NSDictionary *offerMsg;
    NSDictionary *iceservermsg;
    NSString *to;
    NSString *from;
    BOOL isChannelAPIEnable;
    BOOL isXMPPEnable;
    
	NSString* username;
	NSString *path;
	NSString* encodedcredential;
    BOOL isReconnecting;
    NSTimer *_reconnectTimer;
	WebRTCStatsCollector *statsCollector;
    
    WebRTCStackConfig* stackConfig;
    Reachability* reachability;	
    NetworkState nwState;
	NetworkStatus oldStatus;
    BOOL isNetworkAvailable;
    BOOL isNetworkStateUpdated;
    NSTimer *_reconnectTimeoutTimer;
    BOOL isWifiModePrev;
    BOOL isWifiMode;
    BOOL _dataFlag;
}

@property(nonatomic,assign) id<WebRTCStackDelegate> delegate;
@property(nonatomic) BOOL isCapabilityExchangeEnable;
@property(nonatomic) BOOL isVideoBridgeEnable;
@property (nonatomic) NetworkTypes networkType;

/* Below set of API's are called from the application */

- (id)initWithDefaultValue:(WebRTCStackConfig*)_stackConfig _appdelegate:(id<WebRTCStackDelegate>)_appdelegate;
- (id)initWithRTCG:(WebRTCStackConfig*)_stackConfig _appdelegate:(id<WebRTCStackDelegate>)_appdelegate;
- (id)createSession:(WebRTCStream *)_stream _appdelegate:(id<WebRTCSessionDelegate>)_appdelegate _configParam:(WebRTCSessionConfig *)_sessionConfig;
- (id)createIncomingSession:(WebRTCStream *)_stream _appdelegate:(id<WebRTCSessionDelegate>)_appdelegate _configParam:(WebRTCSessionConfig *)_sessionConfig;
- (id)createStream:(WebRTCStreamConfig*)_streamConfig _recordingDelegate:(id<WebRTCSessionDelegate>)appDelegate;
- (id)createAudioOnlyStream;
- (void)disconnect;
- (void)setVideoBridgeEnable: (bool) flag;

// DataChannel: Create session for data channel for sending image/text data
- (id)createDataSession:(id<WebRTCSessionDelegate>)_appdelegate _configParam:(WebRTCSessionConfig *)_sessionConfig;

//XMPP
- (void)dial:(NSString*)toPhone from:(NSString*)fromPhone;
- (void)hangup;
- (void)record:(NSString*)state;


/* Below set of API's are used for internal purpose */

- (void)onRTCServerMessage:(NSString*)msg;
- (void)onRegMessage:(NSString*)msg;
- (void)onAuthMessage:(NSString*)msg;
- (void)sendRTCMessage:(id)msg;
- (void)rejectCall;
- (void)registerOnServer;
- (void)sendRegMessage:(id)msg;
- (void)OnLocalStream:(RTCVideoTrack *)videoTrack;
-(NSMutableDictionary*)getMetaData;
-(NSString*)getNetworkConnectionType;
-(void)onStackError:(NSString*)error errorCode:(NSInteger)code;
- (int) getMachineID;
- (void) initiateReconnect;
- (NSString *) platformType:(NSString *)platform;
- (void)sendpreferredH264:(BOOL)preferH264;
- (void)reconnectTimeout;

//XMPP
-(void)initilizeXMPP : (NSDictionary *)input;


//for speaker
-(int) switchMic:(BOOL)builtin;
-(int) switchSpeaker:(BOOL)builtin;
-(void) addAudioRouteNotification;
-(BOOL) isHeadsetAvailable;
@end
#endif

