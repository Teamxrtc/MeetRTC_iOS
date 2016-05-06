//
//  WebRTCSession.m
//  meet-webrtc-sdk
//
//  Created by Pankaj on 26/08/14.
//  Copyright 2014 Comcast Cable Communications Management, LLC.
//
#import "WebRTCSession.h"
#import "WebRTCFactory.h"
#import "RTCICEServer.h"
#import "RTCVideoCapturer.h"
#import "RTCPair.h"
#import "RTCMediaConstraints.h"
#import "RTCPeerConnectionFactory.h"
#import "RTCPeerConnection.h"
#import "RTCSessionDescription.h"
#import "RTCICECandidate.h"
#import "RTCAudioTrack.h"
#import "WebRTCError.h"
#import "WebRTCStatReport.h"
#import "WebRTCJSON.h"
#import "WebRTCLogHandler.h"
#import "WebRTCLogging.h"
#import "XMPPWorker.h"
#import "XMPPJingle.h"

#import <AssetsLibrary/AssetsLibrary.h>//;
#import <UIKit/UIKit.h>

//Test
NSString* const Session = @"Session";
BOOL BWflag = false ;
BOOL StatFlag = false;

int timeCounter = 10;
#define ICE_SERVER_TIMEOUT 3
#define OFFER_TIMEOUT 60
#define ICE_CONNECTION_TIMEOUT 120
#define STREAM_STATS_TIMEOUT 1
#define NETWORK_CHECK_VAL 5

#define NETWORK_CHECK_VAL 5

/* Keys for setting network data info */
NSString * const WebRTCNetworkQualityLevelKey = @"WebRTCNetworkQualityLevelKey";
NSString * const WebRTCNetworkQualityReasonKey = @"WebRTCNetworkQualityReasonKey";


@interface WebRTCSession () <XMPPWorkerSignalingDelegate, XMPPRoomDelegate, XMPPJingleDelegate>
@property(nonatomic ) NSInteger rttValCounter;
@property(nonatomic ) NSInteger packetLossValCounter;
@property(nonatomic ) NetworkQuality networkQualityLevel;
@property(nonatomic ) NetworkQuality oldNetworkQualityLevel;
@property(nonatomic ) NetworkQuality currentRTTLevel;
@property(nonatomic ) NetworkQuality currentPacketLossLevel;
@property(nonatomic ) NetworkQuality currentBWLevel;
@property(nonatomic ) NetworkQuality newRTTLevel;
@property(nonatomic ) NetworkQuality newPacketLossLevel;
@property(nonatomic ) NetworkQuality newBWLevel;

@property(nonatomic ) NSInteger offsetTotalPacket;
@property(nonatomic ) NSInteger offsetPacketLoss;

@property(nonatomic ) NSMutableArray* rttArray;
@property(nonatomic ) NSMutableArray* packetLossArray;
@property(nonatomic ) NSMutableArray* bandwidthArray;
@property(nonatomic ) NSMutableArray* rxPacketLossArray;
@property(nonatomic ) NSMutableArray* ReceivedBWArray;
@property(nonatomic ) NSInteger arrayIndex;

@property(nonatomic ) BOOL isReceivedPingResponse;
@property(nonatomic ) BOOL isSendingPingPongMsg;
@property(nonatomic ) NSTimer* checkPingResponseTime;
@property(nonatomic)RTCDataChannel* dataChannel;

// XCMAV: Incoming stats
@property(nonatomic ) NSInteger offsetTotalPacket_Rx;
@property(nonatomic ) NSInteger offsetPacketLoss_Rx;
@property(nonatomic ) NSMutableArray* packetLossArray_Rx;
@property(nonatomic ) NSMutableArray* bandwidthArray_Rx;
@end

@implementation WebRTCSession
{
    BOOL isAnswerSent;
    BOOL isDataChannelOpened;
    NSMutableData *concatenatedData;
    NSUInteger dataChunkSize;
    NSString* recievedDataId;
    NSString* startTimeForDataSentStr;
    NSDateFormatter* dateFormatter;
    BOOL cancelSendData;
    
    // XMPP
    XMPPJID * targetJid;
}

NSString* const TAG4 = @"WebRTCSession";

- (WebRTCSession *)initWithDefaultValue:(WebRTCStack *)stack arClientSessionId:(NSString*)arClientSessionId  _configParam:(WebRTCSessionConfig *)_sessionConfig _stream:(WebRTCStream *)_stream _appdelegate:(id<WebRTCSessionDelegate>)_appdelegate  _statcollector:(WebRTCStatsCollector *)_statcollector
{
    // Error check
    if ((arClientSessionId == NULL) || (_sessionConfig.displayName == NULL) || (_sessionConfig.deviceID == NULL))
    {
        LogDebug(@"Init with invalid parameters");
        return nil;
    }
    sessionConfig = _sessionConfig;
    callType = sessionConfig.callType;
    clientSessionId = arClientSessionId;
    state = starting;
    webrtcstack = stack;
    
    DisplayName = sessionConfig.displayName;
    localstream = _stream;
    self.delegate = _appdelegate;
    dtlsFlagValue = @"false";
    allcandidates = [[NSMutableArray alloc]init];
    updatedIceServers =[[NSMutableArray alloc]init];
    //v47 changes
    [updatedIceServers addObject:[[RTCICEServer alloc] initWithURI:[NSURL URLWithString:@"stun:stun.l.google.com:19302"]
                                                 username:@""
                                                 password:@""]];
    isCandidateSent = false;
    isChannelAPIEnable = false;
    statcollector = _statcollector;
    eligibilityToken = nil;
    isVideoSuspended = false ;

    //Assign current state with strong
    _networkQualityLevel = WebRTCGoodNetwork;
    _oldNetworkQualityLevel = WebRTCBadNetwork;
    _currentRTTLevel = WebRTCGoodNetwork;
    _currentPacketLossLevel = WebRTCGoodNetwork;
    _currentBWLevel = WebRTCGoodNetwork;
    
    _rttValCounter = 0;
    _packetLossValCounter = 0;
    _offsetTotalPacket = 0;
    _offsetPacketLoss = 0;
    
    // XCMAV: Incoming stats
    _offsetTotalPacket_Rx = 0;
    _offsetPacketLoss_Rx = 0;
    _packetLossArray_Rx = [[NSMutableArray alloc]init];
    _bandwidthArray_Rx = [[NSMutableArray alloc]init];

    
    isReOffer = false;
    isAnswerSent = false;
    
    /* Declaring array to hold five values for each RTT/ Send-Recv BW/Packet loss
     at any point of time for quality calculation */
    
    _rttArray = [[NSMutableArray alloc]init];
    _packetLossArray = [[NSMutableArray alloc]init];
    _bandwidthArray = [[NSMutableArray alloc]init];
    _arrayIndex = 0;
    
    _isReceivedPingResponse = false;
    _isSendingPingPongMsg = false;
    _checkPingResponseTime = nil;
    isDataChannelOpened = false;
    dataChunkSize = _sessionConfig.dataChunkSize;
    concatenatedData = [NSMutableData data];
     dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    return self;
}

- (WebRTCSession *)initRTCGSessionWithDefaultValue:(WebRTCStack *)stack arClientSessionId:(NSString*)arClientSessionId  _configParam:(WebRTCSessionConfig *)_sessionConfig _stream:(WebRTCStream *)_stream _appdelegate:(id<WebRTCSessionDelegate>)_appdelegate  _statcollector:(WebRTCStatsCollector *)_statcollector _serverURL:(NSString*)_serverURL
{
    
    // Error check
    if ((arClientSessionId == NULL)  || (_sessionConfig.displayName == NULL) || (_sessionConfig.deviceID == NULL))
    {
        LogDebug(@" Init with invalid parameters");
        return nil;
    }
    sessionConfig = _sessionConfig;
    callType = sessionConfig.callType;
    clientSessionId = arClientSessionId;
    state = starting;
    webrtcstack = stack;
    isAnswerSent = false;
    DisplayName = sessionConfig.displayName;
    localstream = _stream;
    self.delegate = _appdelegate;
    dtlsFlagValue = @"false";
    allcandidates = [[NSMutableArray alloc]init];
    updatedIceServers =[[NSMutableArray alloc]init];
    
    //v47
    [updatedIceServers addObject:[[RTCICEServer alloc] initWithURI:[NSURL URLWithString:@"stun:stun.l.google.com:19302"]
                                                          username:@""
                                                          password:@""]];
    isCandidateSent = false;
    isChannelAPIEnable = true;
    statcollector = _statcollector;
    eligibilityToken = nil;
    serverURL = _serverURL;
    isVideoSuspended = false ;
    //Assign current state with strong
    _networkQualityLevel = WebRTCGoodNetwork;
    _oldNetworkQualityLevel = WebRTCBadNetwork;
    _currentRTTLevel = WebRTCGoodNetwork;
    _currentPacketLossLevel = WebRTCGoodNetwork;
    _currentBWLevel = WebRTCGoodNetwork;
    _rttValCounter = 0;
    _packetLossValCounter = 0;
    _offsetTotalPacket = 0;
    _offsetPacketLoss = 0;

    // XCMAV: Incoming stats
    _offsetTotalPacket_Rx = 0;
    _offsetPacketLoss_Rx = 0;
    _packetLossArray_Rx = [[NSMutableArray alloc]init];
    _bandwidthArray_Rx = [[NSMutableArray alloc]init];
    
    isReOffer = false;
    _dataChannel = nil;
    
    /* Declaring array to hold five values for each RTT/SendBW/Packet loss
     at any point of time for quality calculation */
    
    _rttArray = [[NSMutableArray alloc]init];
    _packetLossArray = [[NSMutableArray alloc]init];
    _bandwidthArray = [[NSMutableArray alloc]init];
    _arrayIndex = 0;
    
    _isReceivedPingResponse = false;
    _isSendingPingPongMsg = false;
    _checkPingResponseTime = nil;
    isDataChannelOpened = false;
    dataChunkSize = _sessionConfig.dataChunkSize;
    concatenatedData = [NSMutableData data];
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    return self;

}

- (WebRTCSession *)initWithXMPPValue:(WebRTCStack *)stack _configParam:(WebRTCSessionConfig *)_sessionConfig _stream:(WebRTCStream *)_stream _appdelegate:(id<WebRTCSessionDelegate>)_appdelegate  _statcollector:(WebRTCStatsCollector *)_statcollector
{
    // reset flag
    conferenceFlag=0;
    msidsSession=[[NSMutableArray alloc]init];
    streamsSession=[[NSMutableArray alloc]init];
    
    if ((_sessionConfig.displayName == NULL) || (_sessionConfig.deviceID == NULL))
    {
        NSLog(@"Webrtc:Session:: Init with invalid parameters");
        return nil;
    }
    sessionConfig = _sessionConfig;
    callType = sessionConfig.callType;

    state = starting;
    webrtcstack = stack;

    DisplayName = sessionConfig.displayName;
    localstream = _stream;
    self.delegate = _appdelegate;
    [XMPPWorker sharedInstance].signalingDelegate = self;
    dtlsFlagValue = @"true";
    allcandidates = [[NSMutableArray alloc]init];
    updatedIceServers =[[NSMutableArray alloc]init];
    //v47
    [updatedIceServers addObject:[[RTCICEServer alloc] initWithURI:[NSURL URLWithString:@"stun:stun.l.google.com:19302"]
                                                          username:@""
                                                          password:@""]];
    isCandidateSent = false;
    isChannelAPIEnable = false;
    isXMPPEnable = true;
    statcollector = _statcollector;
    eligibilityToken = nil;
    isReOffer = false;
    
    return self;
}

- (WebRTCSession *)initWithIncomingSession:(WebRTCStack *)stack arClientSessionId:(NSString*)arClientSessionId  _stream:(WebRTCStream *)_stream _appdelegate:(id<WebRTCSessionDelegate>)_appdelegate channelapi:(BOOL)_isChannelAPIEnable _statcollector:(WebRTCStatsCollector *)_statcollector _configParam:(WebRTCSessionConfig *)_sessionConfig
{
    // Error check
    if ((arClientSessionId == NULL) || (_sessionConfig.deviceID == NULL) )
    {
        LogDebug(@"Init with invalid parameters");
        return nil;
    }
    callType = incoming;
    clientSessionId = arClientSessionId;
    state = inactive;
    webrtcstack = stack;
    sessionConfig = _sessionConfig;
    _dataChannel = nil;
        
   // Parse notification data
    //Parse SDP string
//    FromCaller = [sessionConfig.callerID lowercaseString];
//    ToCaller = [sessionConfig.targetID lowercaseString];
    DisplayName = sessionConfig.displayName;
    rtcgSessionId = sessionConfig.rtcgSessionId;
    isAnswerSent = false;
//    if ((FromCaller == NULL) || (ToCaller == NULL) )
//    {
//        LogDebug(@" Notification does not contain required parameters");
//        return nil;
//    }
    localstream = _stream;
    self.delegate = _appdelegate;
    [XMPPWorker sharedInstance].signalingDelegate = self;
    dtlsFlagValue = @"false";
    allcandidates = [[NSMutableArray alloc]init];
    isCandidateSent = false;
    isChannelAPIEnable = _isChannelAPIEnable;
    
    statcollector = _statcollector;    _packetLossValCounter = 0;
    _offsetTotalPacket = 0;
    lastSr = nil;
    updatedIceServers =[[NSMutableArray alloc]init];
    //v47
    [updatedIceServers addObject:[[RTCICEServer alloc] initWithURI:[NSURL URLWithString:@"stun:stun.l.google.com:19302"]
                                                          username:@""
                                                          password:@""]];
    isVideoSuspended = false ;
    //Assign current state with strong
    _networkQualityLevel = WebRTCGoodNetwork;
    _oldNetworkQualityLevel = WebRTCBadNetwork;
    
    /* In case of incoming call, As there is no RTT value in stat,
     So, setting RTT level to excellent to neutralize 
     its effect for deciding final network level */
    
    _currentRTTLevel = WebRTCExcellentNetwork;
    _currentPacketLossLevel = WebRTCGoodNetwork;
    _currentBWLevel = WebRTCGoodNetwork;
    _rttValCounter = 0;

    _offsetPacketLoss = 0;
    
    // XCMAV: Incoming stats
    _offsetTotalPacket_Rx = 0;
    _offsetPacketLoss_Rx = 0;
    _packetLossArray_Rx = [[NSMutableArray alloc]init];
    _bandwidthArray_Rx = [[NSMutableArray alloc]init];
    
    isReOffer = false;
    /* Declaring array to hold five values for each RTT/SendBW/Packet loss
     at any point of time for quality calculation */
    
    _rttArray = [[NSMutableArray alloc]init];
    _packetLossArray = [[NSMutableArray alloc]init];
    _bandwidthArray = [[NSMutableArray alloc]init];
    _arrayIndex = 0;
    
    _isReceivedPingResponse = false;
    _isSendingPingPongMsg = false;
    _checkPingResponseTime = nil;
    isDataChannelOpened = false;
    concatenatedData = [NSMutableData data];
     dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    return self;

}

-(void)setRoomId:(NSString*)roomId
{
    clientSessionId = roomId;
}
-(void) setXMPPEnable:(BOOL)val
{
    isChannelAPIEnable = !val;
    isXMPPEnable = val;
}

-(void)setFromJid:(NSString*)jidFrom
{
    fromJid = jidFrom;
}

// Start the webrtc session
- (void)_timerCallback:(NSTimer *)timer{
    
    LogDebug(@" _timerCallback");

    // Check if we are still in iceconnecting sTAG4e
    if (state == ice_connecting)
    {
        // if not incoming
        if (!callType) {
            [self startSession:updatedIceServers];
        }
    }
    
}

// Start the webrtc session
- (void)start
{
    // TBD: If ice server times out, go back to STUN
    state = ice_connecting;
 
    // Start a timer to monitor the timeout of ice server request
    // If the iceserver reply doesnt come from a server, use google's STUN server
    NSTimer *_icetimer;
    _icetimer = [NSTimer scheduledTimerWithTimeInterval:ICE_SERVER_TIMEOUT
                                                target:self
                                                selector:@selector(_timerCallback:)
                                                userInfo:nil
                                                repeats:NO
                                                ];
    [self requestIceServers];
    
    
}

-(void)dataFlagEnabled:(BOOL)_dataFlag{
 
    dataFlagEnabled = _dataFlag;
}

// Method to join XMPP room
- (void)doJoinRoom:(NSString *)name
{
    // In order to join the room, first we should create a room name
    // Room name is <random string>@conference.<servername>
    NSString *roomName;
    
    if (name == nil)
    {
        // muc changes
        if(!webrtcstack.isVideoBridgeEnable)
        {
            roomName = [NSString stringWithFormat:@"%@@conference",
                          [[[NSUUID UUID] UUIDString] substringToIndex:8].lowercaseString];
        }
        else{
            // New DNS related changes
            roomName = [NSString stringWithFormat:@"%@@",
                        [[[NSUUID UUID] UUIDString] substringToIndex:8].lowercaseString];
        }

    }
    else
    {
        if(!webrtcstack.isVideoBridgeEnable)
        {
            roomName = [NSString stringWithFormat:@"%@@conference",
                            name];
        }
        else{
            // New DNS related changes
            roomName = [NSString stringWithFormat:@"%@@",
                    name];
        }
    }
    
    if (webrtcstack.isVideoBridgeEnable){
        
        [[XMPPWorker sharedInstance] allocateConferenceFocus:roomName];
    }
    else{
    
        NSLog(@"XMPP Stack : State is Joining room %@", roomName);
        
        [[XMPPWorker sharedInstance] joinRoom:roomName appDelegate:self];
        
        // muc changes
        [[XMPPWorker sharedInstance] sendPresenceAlive];
    }

}

// Start the webrtc session
- (void)start:(NSDictionary *)iceServers
{
    // TBD: If ice server times out, go back to STUN
    _iceServers = iceServers;
    
    
    // Manish for xmpp, first step is to join the room

        if (callType == incoming)
        {
            // For xmpp, rtcgsessionid is the room name
            [self doJoinRoom:rtcgSessionId];
            
            if(webrtcstack.isVideoBridgeEnable)
            {
                // muc changes
                [self startSession:updatedIceServers];
            }
        }
        else
        {
            [self doJoinRoom:clientSessionId];
            [self startSession:updatedIceServers];
        }

}



-(void)sendMessage:(NSData *)msg
{
    
    NSError* error;
    NSDictionary* json =[WebRTCJSONSerialization JSONObjectWithData:msg options:kNilOptions error:&error];
 
    NSMutableDictionary* jsonm = [NSMutableDictionary dictionaryWithDictionary:json];
    
    if(!clientSessionId)
        clientSessionId = [NSString stringWithFormat:@"%d", arc4random() % 1000000];
 
//    [jsonm setValue:ToCaller forKey:@"target"];
//    [jsonm setValue:FromCaller forKey:@"from"];
    [jsonm setValue:sessionConfig.appName forKey:@"appId"];
//    [jsonm setValue:FromCaller forKey:@"uid"];
    [jsonm setValue:DisplayName forKey:@"fromDisplay"];
    [jsonm setValue:peerConnectionId forKey:@"peerConnectionId"];
    [jsonm setValue:@"default" forKey:@"applicationContext"];
    [jsonm setValue:clientSessionId forKey:@"clientSessionId"];
    
    LogDebug(@"sendMessage of type = %@",[jsonm objectForKey:@"type"]);
    
    // Add additional options for a offer message
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonm options:0 error:&error];
        NSString *jsonStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

    
        if ([[jsonm objectForKey:@"type"]  isEqual: @"candidate"])
        {
            [[XMPPWorker sharedInstance] sendJingleMessage:@"transport-info" data:jsonm target:targetJid];
        }
    
 
}

- (void)onSignalingMessage:(id)msg
{
 
        [self onSessionSignalingMessage:msg];

}

// Called when a signaling message is received
- (void)onSessionSignalingMessage:(NSDictionary *)msg
{
    LogDebug(@" onSignalingMessage %@",msg);
    NSString *type;
    
    /*//Parse into JSON object
    NSError *error = nil;
    NSDictionary *messageJSON = [WebRTCJSONSerialization
                                 JSONObjectWithData:[msg dataUsingEncoding:NSNonLossyASCIIStringEncoding]
                                 options:0 error:&error];
    
    // Check for errors
    NSAssert(!error, @"%@", [NSString stringWithFormat:@"Webrtc:Session:: Error handling message: %@", error.description]);
    NSAssert([messageJSON count] > 0, @"Webrtc:Session:: Invalid JSON object");
    
    // Get message type
    NSArray * args = [messageJSON objectForKey:@"args"];
    NSDictionary * objects = args[0];*/
    type = [[msg objectForKey:@"type"] lowercaseString];

    LogDebug(@" type:: %@",type );
    
    // Check the type of the message
    if (![type compare:@"offer"])
    {
        [self onOfferMessage:msg];
    }
    else if (![type compare:@"answer"])
    {
        [self onAnswerMessage:msg];
    }
    else if (![type compare:@"reoffer"])
    {
        [self onReOfferMessage:msg];
    }
    else if (![type compare:@"reanswer"])
    {
        [self onReAnswerMessage:msg];
    }
    else if (![type compare:@"candidate"])
    {
        [self onCandidateMessage:msg];
    }
    else if (![type compare:@"candidates"])
    {
        [self onCandidatesMessage:msg];
    }
    else if (![type compare:@"bye"])
    {
        [self onByeMessage:msg];
    }
    else if (![type compare:@"cancel"])
    {
        [self onCancelMessage:msg];
    }
    else if (![type compare:@"notification"])
    {
        [self onNotificationMessage:msg];
    }
    else if (![type compare:@"ping"])
    {
        [self onPingMessage:msg];
    }
    else if (![type compare:@"pong"])
    {
        [self onPongMessage:msg];
    }
    else if (![type compare:@"iceservers"])
    {
        [self onIceServers:msg];
    }
    else if (![type compare:@"capability"])
    {
        //if (webrtcstack.isCapabilityExchangeEnable)
           [self onCapabilityMessage:msg];
    }
    else if (![type compare:@"icefinished"])
    {
         LogDebug(@"Ice candidate finished");
    }
    else if (![type compare:@"configselection"])
    {
        if([[msg objectForKey:@"reason"] lowercaseString])
        {
            LogDebug(@"%@", [[msg objectForKey:@"reason"] lowercaseString]);
            
            // XCMAV: this can help handle Remote Video Pause state.
            NSString* configMsg = [[msg objectForKey:@"reason"] lowercaseString];
            LogDebug(@"[XCMAV]: sending config message to Application: %@", configMsg);
            [self.delegate onConfigMessage_xcmav:configMsg];
        }
    }
    else if (![type compare:@"appmsg"])
    {
        [self.delegate onDisplayMsg:[[msg objectForKey:@"reason"] lowercaseString]];
    }
    else if (![type compare:@"remotereconnect"])
    {
        [self onRemoteReconnectedMessage:msg];
    }
    else if (![type compare:@"requesticeservers"]) //xmpp
    {
         NSLog(@"requesticeservers");
    }
    else
    {
        NSLog(@"Got Unknown server msg = %@",msg);
        //NSError *error = [NSError errorWithDomain:Session code:ERR_UNKNOWN_SERVER_MSG userInfo:nil];
        //[self.delegate onSessionError:error.description errorCode:error.code additionalData:nil];
    }
}

#pragma mark - Internal methods

// Request ICEservers from signaling server
-(void)requestIceServers
{
    // Form JSON
    NSDictionary *reqIceD = @{ @"type" : @"requestIceServers" };
    NSError *jsonError = nil;
    NSData *reqIce = [WebRTCJSONSerialization dataWithJSONObject:reqIceD options:0 error:&jsonError];
    
    // Sending ice server request
     LogDebug(@" Sending iceServer request");
    [self sendMessage:reqIce];
}

-(void)onOfferMessage:(NSDictionary*)msg
{
     LogDebug(@" Got an offer message");
    
    // Storing the data to retrieve further after recieving iceserver
    peerConnectionId = [msg objectForKey:@"peerConnectionId"];
    initialSDP = msg;
    
    [statcollector startMetric:self _statName:@"mediaConnectionTime"];

        [self answer];
	
}

-(void)onAnswerMessage:(NSDictionary*)msg
{
     LogDebug(@" Got an answer message");
    state = active;
    [statcollector startMetric:self _statName:@"mediaConnectionTime"];
    
    [statcollector startMetric:@"callDuration"];
    //Parse SDP string
    NSString *tempSdp = [msg objectForKey:@"sdp"];
    LogDebug(@"sdp Before %@",tempSdp);
    //NSString *backslashString = [tempSdp stringByReplacingOccurrencesOfString:@"\\\\" withString:@"\\"];
    NSString *sdpString = [tempSdp stringByReplacingOccurrencesOfString:@"\\\\r" withString:@"\r"];
    NSString *sdpString2 = [sdpString stringByReplacingOccurrencesOfString:@"\\\\n" withString:@"\n"];
    NSString *sdpString3 = [sdpString2 stringByReplacingOccurrencesOfString:@"\\/" withString:@"/"];
    NSString *sdpString4 = [sdpString3 stringByReplacingOccurrencesOfString:@"\\r" withString:@"\r"];
    NSString *sdpString5 = [sdpString4 stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
    LogDebug(@"SDP After %@",sdpString3);
    //Harish:: Reverting back the changes as call is getting crash with 3.53 sdk
    /*NSString *backslashrString = [backslashString stringByReplacingOccurrencesOfString:@"\\r" withString:@"\r"];
    NSString *forwardslashrString = [backslashrString stringByReplacingOccurrencesOfString:@"\\/" withString:@"/"];

    NSString *sdpString = [forwardslashrString stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];*/

    
   
    // Create session description
    RTCSessionDescription *sdp = [[RTCSessionDescription alloc]
                                  initWithType:@"answer" sdp:[self preferISAC:sdpString5]];
                                  //initWithType:@"answer" sdp:sdpString5];

    
    [peerConnection setRemoteDescriptionWithDelegate:self sessionDescription:sdp];

    if (self.delegate != nil)
        [self.delegate onSessionConnect];
}

-(void)onReOfferMessage:(NSDictionary*)msg
{
     LogDebug(@" Got an reoffer message");
}

-(void)onReAnswerMessage:(NSDictionary*)msg
{
     LogDebug(@" Got an reanswer message");
}

-(void)onCandidateMessage:(NSDictionary*)msg
{
     LogDebug(@" Got a candidate message");
    NSString *mid = [msg objectForKey:@"id"];
    NSString *sdpLineIndex = [msg objectForKey:@"label"];
    NSString *sdp = [msg objectForKey:@"candidate"];
    
    // Ignore missing sdp
    if(sdp == NULL)
        return;
    
    // Create ICE candidate
    RTCICECandidate *candidate = [[RTCICECandidate alloc] initWithMid:mid
                                                                index:sdpLineIndex.intValue
                                                                  sdp:sdp];
    
    // Add to queued or peer connection candidates
    if (peerConnection != nil)
    {
         LogDebug(@" Adding candidates to peerconnection");
        [peerConnection addICECandidate:candidate];
    }
    else
        [queuedRemoteCandidates addObject:candidate];

}

-(void)onCandidatesMessage:(NSDictionary*)msg
{
     LogDebug(@" Got a candidates message");
}

-(void)onByeMessage:(NSDictionary*)msg
{
    
    // Check if the message has a failure
    BOOL isFailure = [[msg valueForKey:@"failure"]boolValue];

    LogInfo(@" Got bye message for state:: %d Failure %d " , state ,isFailure);
    
    if(isFailure)
    {
       NSMutableDictionary* details = [NSMutableDictionary dictionary];
       [details setValue:@"RTCG Error" forKey:NSLocalizedDescriptionKey];
       NSError *error = [NSError errorWithDomain:Session code:ERR_RTCG_ERROR userInfo:details];
       [self.delegate onSessionError:error.description errorCode:error.code additionalData:msg];
    }
    else
    {
        [self.delegate onSessionEnd:@"Remote disconnection"];
        [statcollector stopMetric:@"callDuration"];
    }
    
    if(_statsTimer != nil)
        [_statsTimer invalidate];
    _statsTimer = nil;
    
    state = inactive;
    [self closeSession];

    [webrtcstack disconnect];
}

-(void)onCancelMessage:(NSDictionary*)msg
{
    LogDebug(@" Got cancel message");
    [self.delegate onSessionEnd:@"Remote cancel message"];
}

-(void)onNotificationMessage:(NSDictionary*)msg
{
     LogDebug(@" Got notification message");
}

-(void)onPingMessage:(NSDictionary*)msg
{
     LogDebug(@" Got ping message");
    //Form JSON
    NSDictionary *pongD = @{ @"type" : @"pong" };
    NSError *jsonError = nil;
    NSData *pong = [WebRTCJSONSerialization dataWithJSONObject:pongD options:0 error:&jsonError];
    
    [self sendMessage:pong];
}


-(void)onPongMessage:(NSDictionary*)msg
{
    LogDebug(@" Got ping Response");
    _isReceivedPingResponse = true;
    [_checkPingResponseTime invalidate];
    _checkPingResponseTime = nil;
    if(_isSendingPingPongMsg)
    {
        /*NSTimer *sendPingMsgTimer = [NSTimer scheduledTimerWithTimeInterval:sessionConfig.pingInterval
                                                                  target:self
                                                                selector:@selector(sendPingMessage)
                                                                userInfo:nil
                                                                 repeats:NO
                                  ];*/
        
        [self performSelector:@selector(sendPingMessage) withObject:self afterDelay:sessionConfig.pingInterval];
        
    }
    //[self sendPingMessage];
    
}

-(void)onPingResponseFailure
{
    if(!_isReceivedPingResponse)
    {
        LogDebug(@"Failed to get ping response");
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"Unable to ping the remote client" forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:Session code:ERR_REMOTE_UNREACHABLE userInfo:details];
        [self.delegate onSessionError:error.description errorCode:error.code additionalData:nil];

    }
}

-(void)sendPingMessage
{
    //Form JSON
    NSDictionary *pingD = @{ @"type" : @"ping" };
    NSError *jsonError = nil;
    NSData *ping = [WebRTCJSONSerialization dataWithJSONObject:pingD options:0 error:&jsonError];
    _isReceivedPingResponse = false;
    
    dispatch_async(dispatch_get_main_queue(), ^(void){
        
        //Starting timer to check if received pong message
        _checkPingResponseTime = [NSTimer scheduledTimerWithTimeInterval:sessionConfig.pingResponseTimeout                                                                  target:self
            selector:@selector(onPingResponseFailure)
            userInfo:nil
            repeats:NO];
    });

    
    [self sendMessage:ping];

}


-(void)onRemoteReconnectedMessage:(NSDictionary*)msg
{
    [self networkReconnected];
}

-(void)onIceServers:(NSDictionary*)msg
{
    
     LogDebug(@" onIceServers");
    // Check if the current state is ice_connecting, if not it means we timed out so lets skip this
    if (state == ice_connecting)
    {

        NSDictionary *iceServers = [msg objectForKey:@"iceServers"];
        NSString *username;
        if ([iceServers objectForKey:@"username"] != Nil)
        {
            username = [iceServers objectForKey:@"username"];
        }
        else
        {
            username = @"";
        }
        NSString *credential;

        if ([iceServers objectForKey:@"credential"] != Nil)
        {
            credential = [iceServers objectForKey:@"credential"];
        }
        else
        {
            credential = @"";
        }
        NSArray *uris = [iceServers objectForKey:@"uris"];
   
        if ([NSURL URLWithString:[uris lastObject]] == nil)
        {
            LogDebug(@" Incorrect turn URI");
            return;
        }
        
        NSLog(@"Webrtc:Session::  ice URL %@ username %@ credentials %@", [NSURL URLWithString:[uris lastObject]],username, credential  );
        
        for (int i=0; i < [uris count]; i++)
        {
            NSString * urlString = [uris objectAtIndex:i];
            //v47
            [updatedIceServers addObject:[[RTCICEServer alloc] initWithURI:[NSURL URLWithString:urlString]
                                                              username:username
                                                              password:credential]];
        }

        // TBD: To create a critical section so that there is no race conditon
       // updatedIceServers = [[RTCICEServer alloc] initWithURI:[NSURL URLWithString:@"stun:stun.l.google.com:19302"]
        //                                             username:@""
        //                                             password:@""];

        
//            if (!isChannelAPIEnable)
                [self startSession:updatedIceServers];
    }
}

-(void)onUnsupportedMessage:(NSDictionary*)msg
{
     LogDebug(@" Unsupported message");
}

-(void)getLogToApp {
    //[RTCPeerConnectionFactory getLogToApp];
}

-(void)startSession:(NSArray*)iceServers
{
    state = call_connecting;
    isCandidateSent = false;
     LogDebug(@" Starting webrtc session");
    dispatch_async(dispatch_get_main_queue(), ^(void){
        
    peerConnectionId = [[NSUUID UUID] UUIDString];

    factory = [WebRTCFactory getPeerConnectionFactory];
    
    // Get the access to local stream and attach to peerconnection
    [self remoteStream];
        
    if (isXMPPEnable)
    {
    	// For xmpp, offer is generated by the callee
        if ( !(webrtcstack.isVideoBridgeEnable) && (callType == incoming))
            [self createOffer];
    }
    else if(callType == dataoutgoing)
    {
        //Creating DataChannel
        [self createDataChannel];
        [self createOffer];
    }
    else if(callType != incoming)
        [self createOffer];
    
    });

    _statsTimer = [NSTimer scheduledTimerWithTimeInterval:STREAM_STATS_TIMEOUT
                                                   target:self
                                                 selector:@selector(getStreamStatsTimer)
                                                 userInfo:nil
                                                  repeats:YES
                   ];
    
    lastSr = [[WebRTCStatReport alloc]init];
    
    if (self.delegate != nil)
        [self.delegate onSessionConnecting];

}

-(void)getStreamStatsTimer
{
    [peerConnection getStatsWithDelegate:self mediaStreamTrack:nil statsOutputLevel:RTCStatsOutputLevelDebug];
}

- (void)remoteStream
{

    LogDebug(@"remoteStream DTLS Flag : %@",dtlsFlagValue );
 
    //Peer connection constraints
    NSArray * constraintPairs = @[[[RTCPair alloc] initWithKey:@"OfferToRecieveAudio" value:@"true"],
                                  [[RTCPair alloc] initWithKey:@"OfferToRecieveVideo" value:@"true"]];
    
    NSMutableArray * optionalConstraints = [[NSMutableArray alloc]init];
        [optionalConstraints addObject:[[RTCPair alloc] initWithKey:@"DtlsSrtpKeyAgreement" value:dtlsFlagValue]];
        [optionalConstraints addObject:[[RTCPair alloc] initWithKey:@"googCpuOveruseDetection" value:@"true"]];
        [optionalConstraints addObject:[[RTCPair alloc] initWithKey:@"googCpuOveruseEncodeUsage" value:@"true"]];
        [optionalConstraints addObject:[[RTCPair alloc] initWithKey:@"googCpuUnderuseThreshold" value:@"25"]];
        [optionalConstraints addObject:[[RTCPair alloc] initWithKey:@"googCpuOveruseThreshold" value:@"150"]];
    
    // Set IPv6 constraint if it is enabled
    if (sessionConfig.EnableIPv6)
        [optionalConstraints addObject:[[RTCPair alloc] initWithKey:@"googIPv6" value:@"true"]];

    if(sessionConfig.isBWCheckEnable){
        [optionalConstraints addObject:[[RTCPair alloc] initWithKey:@"googSuspendBelowMinBitrate" value:@"true"]];
    }
    
    if(webrtcstack.networkType == wifi)
    {
        //[optionalConstraints addObject:[[RTCPair alloc] initWithKey:@"googHighStartBitrate" value:@"true"]];
        //[optionalConstraints addObject:[[RTCPair alloc] initWithKey:@"googVeryHighBitrate" value:@"true"]];
        [optionalConstraints addObject:[[RTCPair alloc] initWithKey:@"googImprovedWifiBwe" value:@"true"]];
        [optionalConstraints addObject:[[RTCPair alloc] initWithKey:@"googHighStartBitrate" value:@"1500"]];
        //[optionalConstraints addObject:[[RTCPair alloc] initWithKey:@"minBitrate" value:@"50"]];
        //[optionalConstraints addObject:[[RTCPair alloc] initWithKey:@"maxBitrate" value:@"2000"]];
    }
    else if((webrtcstack.networkType == cellularLTE) || (webrtcstack.networkType == cellular4g) )
    {
        [optionalConstraints addObject:[[RTCPair alloc] initWithKey:@"googHighStartBitrate" value:@"800"]];
        //[optionalConstraints addObject:[[RTCPair alloc] initWithKey:@"minBitrate" value:@"50"]];
        //[optionalConstraints addObject:[[RTCPair alloc] initWithKey:@"maxBitrate" value:@"1000"]];

    }
    else
    {
        [optionalConstraints addObject:[[RTCPair alloc] initWithKey:@"googHighStartBitrate" value:@"500"]];
        //[optionalConstraints addObject:[[RTCPair alloc] initWithKey:@"minBitrate" value:@"50"]];
        //[optionalConstraints addObject:[[RTCPair alloc] initWithKey:@"maxBitrate" value:@"1000"]];
    }
        RTCMediaConstraints *constraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:constraintPairs
                                                                                 optionalConstraints:optionalConstraints];

    

    queuedRemoteCandidates = [NSMutableArray array];
    
    //Create peer connection
    
    if (!isReOffer)
    peerConnection = [factory peerConnectionWithICEServers:updatedIceServers
                                               constraints:constraints delegate:self];
    
    lms = [localstream getMediaStream];
    
    //Add stream to peer connection
    if (lms) {
        //[peerConnection addStream:lms constraints:constraints];
        [peerConnection addStream:lms];
    }
}

-(void)createOffer
{
     LogDebug(@" createOffer");
    if (!peerConnection) {
        [self remoteStream];
    }

    isReOffer = false;
    //Peer connection constraints
    NSArray * constraintPairs = @[[[RTCPair alloc] initWithKey:@"googUseRtpMUX" value:@"true"],
                                  ];
    
    
    RTCMediaConstraints *constraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:constraintPairs
                                                                             optionalConstraints:nil];
   // [peerConnection createOfferWithDelegate:self constraints:nil];
    [peerConnection createOfferWithDelegate:self constraints:nil];


}

-(NSString*)getClientSessionId
{
    return clientSessionId;
}
-(void)answer
{
    state = active;
    LogDebug(@" answer");
    factory = [WebRTCFactory getPeerConnectionFactory];
    [self remoteStream];
    NSString *tempSdp = [initialSDP objectForKey:@"sdp"];
    NSLog(@"session initiate SDp %@",tempSdp);
    if(sessionConfig.isBroadcast)
    {
        if(callType == incoming)
            tempSdp = [tempSdp stringByReplacingOccurrencesOfString:@"sendrecv" withString:@"sendonly"];
        else
            tempSdp = [tempSdp stringByReplacingOccurrencesOfString:@"sendrecv" withString:@"recvonly"];
    }
    NSString *backslashString = [tempSdp stringByReplacingOccurrencesOfString:@"\\\\" withString:@"\\"];
    NSString *backslashrString = [backslashString stringByReplacingOccurrencesOfString:@"\\r" withString:@"\r"];
    NSString *forwardslashrString = [backslashrString stringByReplacingOccurrencesOfString:@"\\/" withString:@"/"];
    NSString *sdpString = [forwardslashrString stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];

    // Create session description
    RTCSessionDescription *sdp = [[RTCSessionDescription alloc]
                                  initWithType:@"offer" sdp:[self preferISAC:sdpString]];
                                  //initWithType:@"offer" sdp:sdpString];
    
    [peerConnection setRemoteDescriptionWithDelegate:self sessionDescription:sdp];
    
    [self createAnswer];
    
        
}

-(void)createAnswer
{
    LogDebug(@" createAnswer");
    if (!peerConnection) {
        [self remoteStream];
    }
    
    [peerConnection createAnswerWithDelegate:self constraints:nil];
    
    
    _statsTimer = [NSTimer scheduledTimerWithTimeInterval:STREAM_STATS_TIMEOUT
                                                   target:self
                                                 selector:@selector(getStreamStatsTimer)
                                                 userInfo:nil
                                                  repeats:YES
                   ];
    
    lastSr = [[WebRTCStatReport alloc]init];
    [statcollector startMetric:@"callDuration"];
    
    isReOffer = true;
}

- (NSString *)preferH264:(NSString *)origSDP
{
    int mLineIndex = -1;
    NSString* isac16kRtpMap = nil;
    NSArray* lines = [origSDP componentsSeparatedByString:@"\r\n"];
    NSRegularExpression* isac16kRegex = [NSRegularExpression
                                         regularExpressionWithPattern:@"^a=rtpmap:(\\d+) H264/90000[\r]?$"
                                         options:0
                                         error:nil];
    for (int i = 0; (i < [lines count]) && (mLineIndex == -1 || isac16kRtpMap == nil); ++i) {
        
        NSString* line = [lines objectAtIndex:i];
        
        if ([line hasPrefix:@"m=video "]) {
            mLineIndex = i;
            continue;
        }
        
        NSTextCheckingResult* result = [isac16kRegex firstMatchInString:line options:0 range:NSMakeRange(0, [line length])];
        if (!result)
            isac16kRtpMap = nil;
        else
            isac16kRtpMap =  [line substringWithRange:[result rangeAtIndex:1]];
    }
    
    if (mLineIndex == -1) {
        LogDebug(@" No m=audio line, so can't prefer iSAC");
        return origSDP;
    }
    if (isac16kRtpMap == nil) {
        LogDebug(@" No ISAC/16000 line, so can't prefer iSAC");
        return origSDP;
    }
    NSArray* origMLineParts =
    [[lines objectAtIndex:mLineIndex] componentsSeparatedByString:@" "];
    NSMutableArray* newMLine =
    [NSMutableArray arrayWithCapacity:[origMLineParts count]];
    int origPartIndex = 0;
    // Format is: m=<media> <port> <proto> <fmt> ...
    [newMLine addObject:[origMLineParts objectAtIndex:origPartIndex++]];
    [newMLine addObject:[origMLineParts objectAtIndex:origPartIndex++]];
    [newMLine addObject:[origMLineParts objectAtIndex:origPartIndex++]];
    [newMLine addObject:isac16kRtpMap];
    for (; origPartIndex < [origMLineParts count]; ++origPartIndex) {
        if ([isac16kRtpMap compare:[origMLineParts objectAtIndex:origPartIndex]]
            != NSOrderedSame) {
            [newMLine addObject:[origMLineParts objectAtIndex:origPartIndex]];
        }
    }
    NSMutableArray* newLines = [NSMutableArray arrayWithCapacity:[lines count]];
    [newLines addObjectsFromArray:lines];
    [newLines replaceObjectAtIndex:mLineIndex
                        withObject:[newMLine componentsJoinedByString:@" "]];
    return [newLines componentsJoinedByString:@"\n"];
}

- (NSString *)preferISAC:(NSString *)origSDP {
    int mLineIndex = -1;
    NSString* isac16kRtpMap = nil;
    NSArray* lines = [origSDP componentsSeparatedByString:@"\\n"];
    NSRegularExpression* isac16kRegex = [NSRegularExpression
                                         regularExpressionWithPattern:@"^a=rtpmap:(\\d+) ISAC/16000[\r]?$"
                                         options:0
                                         error:nil];
    for (int i = 0; (i < [lines count]) && (mLineIndex == -1 || isac16kRtpMap == nil); ++i) {
        
        NSString* line = [lines objectAtIndex:i];
        
        if ([line hasPrefix:@"m=audio "]) {
            mLineIndex = i;
            continue;
        }
        
        NSTextCheckingResult* result = [isac16kRegex firstMatchInString:line options:0 range:NSMakeRange(0, [line length])];
        if (!result)
            isac16kRtpMap = nil;
        else
            isac16kRtpMap =  [line substringWithRange:[result rangeAtIndex:1]];
    }
    
    if (mLineIndex == -1) {
         LogDebug(@" No m=audio line, so can't prefer iSAC");
        return origSDP;
    }
    if (isac16kRtpMap == nil) {
         LogDebug(@" No ISAC/16000 line, so can't prefer iSAC");
        return origSDP;
    }
    NSArray* origMLineParts =
    [[lines objectAtIndex:mLineIndex] componentsSeparatedByString:@" "];
    NSMutableArray* newMLine =
    [NSMutableArray arrayWithCapacity:[origMLineParts count]];
    int origPartIndex = 0;
    // Format is: m=<media> <port> <proto> <fmt> ...
    [newMLine addObject:[origMLineParts objectAtIndex:origPartIndex++]];
    [newMLine addObject:[origMLineParts objectAtIndex:origPartIndex++]];
    [newMLine addObject:[origMLineParts objectAtIndex:origPartIndex++]];
    [newMLine addObject:isac16kRtpMap];
    for (; origPartIndex < [origMLineParts count]; ++origPartIndex) {
        if ([isac16kRtpMap compare:[origMLineParts objectAtIndex:origPartIndex]]
            != NSOrderedSame) {
            [newMLine addObject:[origMLineParts objectAtIndex:origPartIndex]];
        }
    }
    NSMutableArray* newLines = [NSMutableArray arrayWithCapacity:[lines count]];
    [newLines addObjectsFromArray:lines];
    [newLines replaceObjectAtIndex:mLineIndex
                        withObject:[newMLine componentsJoinedByString:@" "]];
    return [newLines componentsJoinedByString:@"\n"];
}
/*
- (NSString *)SetMinMaxBandwidth:(NSString *)origSDP minRate:(NSInteger)minRate maxRate:(NSInteger)MaxRate {
    int mLineIndex = -1;
    NSString* isac16kRtpMap = nil;
    NSArray* lines = [origSDP componentsSeparatedByString:@"\\n"];
    NSRegularExpression* isac16kRegex = [NSRegularExpression
                                         regularExpressionWithPattern:@"^a=rtpmap:(\\d+) VP8/90000[\r]?$"
                                         options:0
                                         error:nil];
    for (int i = 0; (i < [lines count]) && (mLineIndex == -1 || isac16kRtpMap == nil); ++i) {
        
        NSString* line = [lines objectAtIndex:i];
        
        if ([line hasPrefix:@"m=video "]) {
            mLineIndex = i;
            continue;
        }
        
        NSTextCheckingResult* result = [isac16kRegex firstMatchInString:line options:0 range:NSMakeRange(0, [line length])];
        if (!result)
            isac16kRtpMap = nil;
        else
            isac16kRtpMap =  [line substringWithRange:[result rangeAtIndex:1]];
    }
    
    if (mLineIndex == -1) {
        LogDebug(@"Webrtc:Session:: No m=video line, so can't set bitrate");
        return origSDP;
    }
    if (isac16kRtpMap == nil) {
        LogDebug(@"Webrtc:Session:: No VP8/90000 line, so can't set bitrate");
        return origSDP;
    }
    NSArray* origMLineParts =
    [[lines objectAtIndex:mLineIndex] componentsSeparatedByString:@" "];
    NSMutableArray* newMLine =
    [NSMutableArray arrayWithCapacity:[origMLineParts count]];
    int origPartIndex = 0;
    // Format is: m=<media> <port> <proto> <fmt> ...
    [newMLine addObject:[origMLineParts objectAtIndex:origPartIndex++]];
    [newMLine addObject:[origMLineParts objectAtIndex:origPartIndex++]];
    [newMLine addObject:[origMLineParts objectAtIndex:origPartIndex++]];
    [newMLine addObject:isac16kRtpMap];
    for (; origPartIndex < [origMLineParts count]; ++origPartIndex) {
        if ([isac16kRtpMap compare:[origMLineParts objectAtIndex:origPartIndex]]
            != NSOrderedSame) {
            [newMLine addObject:[origMLineParts objectAtIndex:origPartIndex]];
        }
    }
    NSMutableArray* newLines = [NSMutableArray arrayWithCapacity:[lines count]];
    [newLines addObjectsFromArray:lines];
    [newLines replaceObjectAtIndex:mLineIndex
                        withObject:[newMLine componentsJoinedByString:@" "]];
    return [newLines componentsJoinedByString:@"\n"];
}
*/
- (void)setDTLSFlag:(BOOL)value
{
    if (value == true)
    {
        dtlsFlagValue = @"true";
    }
    else
    {
        dtlsFlagValue = @"false";
    }
}

- (void)closeSession
{
    dispatch_async(dispatch_get_main_queue(), ^(void)
                   {
                       // LogDebug(@"DataTask cancel is done ");
                       //Closing data channel
                       cancelSendData = true;
                       [_dataChannel close];
                       _dataChannel = nil;
                       
                       [dataTask cancel];
                       //[localstream stop];
                       [peerConnection close];
                       
                       peerConnection = nil;
                       
                       //renderer = nil;
                       videoTrack = nil;
                       mediaConstraints = nil;
                       pcConstraints = nil;
                       lms =nil;
                       state = inactive;
                       _delegate = nil;
                       webrtcstack = nil;
                       localstream = nil;
                       factory = nil;
                       updatedIceServers = nil;
                       queuedRemoteCandidates = nil;
                       localsdp = nil;
                       allcandidates = nil;
                       lastSr = nil;
                       statcollector = nil;
                       sessionConfig = nil;
                       eligibilityToken = nil;
                       _iceServers = nil;
                       serverURL = nil;
                       initialSDP = nil;
                      // [RTCPeerConnectionFactory deinitializeSSL];
                   });
}

- (void)disconnect
{
    if(_statsTimer != nil)
    [_statsTimer invalidate];
    [self closeSession];
    [self sendMessage:[@"{\"type\" : \"bye\"}" dataUsingEncoding:NSUTF8StringEncoding]];
   // if (state == active)
        [statcollector stopMetric:@"callDuration"];

      [[XMPPWorker sharedInstance] leaveRoom];
    
    //[self finalStats];
    
}

- (void)sendDTMFTone:(Tone)_tone
{
    if ( state != active ) {
        LogDebug(@"Connect not send DTMF tone while not in a session");
        //return;
    }
    NSString *toneValue = toneValueString(_tone);
    LogInfo(@"Sending DTMF Tone %@",toneValue);
    //NSDictionary *initialDtmf = @{@"type":@"sessionMessage"};
    NSDictionary *sessionMessage = @{@"type": @"dtmf", @"tone": toneValue};
    NSDictionary *initialDtmf = @{@"type":@"sessionMessage", @"sessionMessage":sessionMessage};
    //[initialDtmf setValue:sessionMessage forKey:@"sessionMessage"];
    NSError *jsonError = nil;
    NSData *dtmf = [WebRTCJSONSerialization dataWithJSONObject:initialDtmf options:0 error:&jsonError];
    LogDebug(@"check4");
    [self sendMessage:dtmf];
    
}
-(void)streamAndParticipantMapping : (NSString *)type :(NSArray *)msidInput
{

    if ([type caseInsensitiveCompare:@"Remove"]==NSOrderedSame)
    {
        for (int i=0; i<msidInput.count; i++)
        {
            NSString *tempName=[msidInput objectAtIndex:i];
            
            for (int j=0; j<streamsSession.count; j++)
            {
                NSDictionary *tempStreams=[streamsSession objectAtIndex:j];
                
                if ([[tempStreams objectForKey:@"name"] caseInsensitiveCompare:tempName]==NSOrderedSame)
                {
                    RTCMediaStream *stream=[[streamsSession objectAtIndex:j] objectForKey:@"streamInfo"];
                    
                    if (stream)
                    {
                        [peerConnection removeStream:stream];
                    }
                    [streamsSession removeObjectAtIndex:j];
                    [msidsSession removeObject:tempName];
                    
                }
                
            }
            
        }
        if ([self.delegate respondsToSelector:@selector(sessionRemoveMedia::)]) {
            
            [self.delegate sessionRemoveMedia:nil:streamsSession];
        }
        conferenceFlag=(int)streamsSession.count;
    }
    
}
#pragma mark - Sample RTCSessionDescriptonDelegate delegate
// Called when creating a session.
- (void)peerConnection:(RTCPeerConnection *)arPeerConnection
didCreateSessionDescription:(RTCSessionDescription *)arSdp
                 error:(NSError *)error
{
    if(error)
    {
         LogDebug(@" didCreateSessionDescription SDP onFailure %@.", [arSdp description]);
        //NSAssert(NO, error.description);
        state = inactive;
        [self.delegate onSessionError:error.description errorCode:ERR_INVALID_SDP additionalData:nil];
        return;
    }
    
    //NSString * modifiedSDP = [self preferISAC:arSdp.description];
    NSMutableString * modifiedSDP = [arSdp.description mutableCopy];

    NSRange lineindex;
    lineindex = [modifiedSDP rangeOfString:@"a=rtpmap:100 VP8/90000\r\n"];
    
   // [modifiedSDP insertString:@"a=fmtp:100 x-google-min-bitrate=1500; x-google-max-bitrate=4096\r\n" atIndex:(lineindex.length+lineindex.location)];
    
   //  LogDebug(@"Webrtc:Session:: Local SDP onFailure %@.",modifiedSDP);

    // Create SDP and set local description
    RTCSessionDescription* sdp = [[RTCSessionDescription alloc] initWithType:arSdp.type sdp:modifiedSDP];
    [peerConnection setLocalDescriptionWithDelegate:self sessionDescription:sdp];
    
    // Convert description and replace with broadcast or two way
    NSString * sdpDesc = sdp.description;
    /*if(sessionConfig.isBroadcast) {
        sdpDesc = [sdpDesc stringByReplacingOccurrencesOfString:@"sendrecv" withString:@"sendonly"];
    }*/
    
    // Set this to prefer H264 instead VP8
    /*if(sessionConfig.preferredH264)
    {
        [localstream setAspectRatio43:true]; // For now we support 4:3 for H264
        sdpDesc = [self preferH264:sdpDesc];
    }*/
    
    // Form JSON
    NSDictionary *json = @{ @"type" : sdp.type, @"sdp" : sdpDesc };
    NSError *jsonError = nil;
    NSData *data = [WebRTCJSONSerialization dataWithJSONObject:json options:0 error:&jsonError];
    
    NSAssert(!jsonError, @"%@", [NSString stringWithFormat:@"Error: %@", jsonError.description]);
    
    dispatch_async(dispatch_get_main_queue(), ^(void){
        
        /* NSTimer *_offertimer;
         _offertimer = [NSTimer scheduledTimerWithTimeInterval:OFFER_TIMEOUT
         target:self
         selector:@selector(_timerOffer:)
         userInfo:nil
         repeats:NO
         ];*/
        
        if ([sdp.type isEqualToString:@"answer"])
        {
            isAnswerSent = true;
        }
	if (isXMPPEnable && !(webrtcstack.isVideoBridgeEnable) && (callType == incoming))
        {
            NSDictionary *json = @{ @"sdp" : sdpDesc };
            [[XMPPWorker sharedInstance] sendJingleMessage:@"session-initiate" data:json target:targetJid];
            
            //Sending all candidates together
            NSDictionary* allcandidatesD = [allcandidates mutableCopy];

            for (int i=0; i < [allcandidates count]; i++)
            {
                NSDictionary *dict = allcandidates[i];
                [[XMPPWorker sharedInstance] sendJingleMessage:@"transport-info" data:dict target:targetJid];
            }

        }
        else if (isXMPPEnable)
        {
            NSDictionary *json = @{ @"sdp" : sdpDesc };
            [[XMPPWorker sharedInstance] sendJingleMessage:@"session-accept" data:[json copy] target:targetJid];
            
            if (webrtcstack.isVideoBridgeEnable)
            [[XMPPWorker sharedInstance] sendVideoInfo:@"session-accept" data:[json copy] target:targetJid];
            
        }

        else
        {
            // Send data
            [self sendMessage:data];
	}
        
    });


}

- (void)_timerOffer:(NSTimer *)timer{
    
     LogDebug(@"Webrtc:Stack:: _timerOffer");
    
}

//- (NSDictionary *)getRemotePartyInfo
//{
//    NSDictionary *json = @{ @"alias" : ToCaller };
//    return json;
//}

// Called when setting a local or remote description.
- (void)peerConnection:(RTCPeerConnection *)arPeerConnection
didSetSessionDescriptionWithError:(NSError *)error
{
    if(error)
    {
        LogDebug(@" didSetSessionDescriptionWithError SDP onFailure.");
        state = inactive;
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"Unable to set local or remote SDP" forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:Session code:ERR_INVALID_SDP userInfo:details];
        [self.delegate onSessionError:error.description errorCode:error.code additionalData:nil];
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^(void){
       
        //Add ICE candidates
        if (peerConnection.remoteDescription)
        {
            for (RTCICECandidate *candidate in queuedRemoteCandidates)
            {
                BOOL isICECandidateAdded = [peerConnection addICECandidate:candidate];
                if(!isICECandidateAdded)
                {
                    NSError *error = [NSError errorWithDomain:Session code:ERR_ICE_CANDIDATE userInfo:nil];
                    [self.delegate onSessionError:error.description errorCode:error.code additionalData:nil];
                }
            }
            queuedRemoteCandidates = nil;
        }
    });
}

#pragma mark - Sample RTCPeerConnectionDelegate delegate
// Triggered when there is an error.
- (void)peerConnectionOnError:(RTCPeerConnection *)peerConnection
{
    NSAssert(NO, @"Webrtc:Session:: PeerConnection error");
    state = inactive;
    NSError *error = [NSError errorWithDomain:Session code:ERR_UNSPECIFIED_PEERCONNECTION userInfo:nil];
    [self.delegate onSessionError:error.description errorCode:error.code additionalData:nil];
}

// Triggered when the SignalingState changed.
- (void)peerConnection:(RTCPeerConnection *)peerConnection
 signalingStateChanged:(RTCSignalingState)stateChanged
{
    LogInfo(@"PCO onSignalingStateChange: %d",stateChanged);
}

// Triggered when media is received on a new stream from remote peer.
- (void)peerConnection:(RTCPeerConnection *)peerConnection
           addedStream:(RTCMediaStream *)stream
{
     LogDebug(@" PCO onAddStream");
    
   // NSAssert([stream.audioTracks count] >= 1,
    //         @"Expected at least 1 audio stream");
    //NSAssert([stream.videoTracks count] >= 1,
    //         @"Expected at least 1 video stream");
   
    if ([stream.videoTracks count] > 0)
    {
        //stream changes - arunkavi
        NSDictionary *tempStream=[[NSDictionary alloc]initWithObjectsAndKeys:stream.label,@"name",stream,@"streamInfo", nil];
        if (streamsSession.count==1)
        {
            NSString *streamName=[[streamsSession objectAtIndex:0] objectForKey:@"name"];
            if([streamName caseInsensitiveCompare:@"default"]==NSOrderedSame)
            {
                [streamsSession replaceObjectAtIndex:0 withObject:tempStream];
            }
            else
            {
                if(![streamsSession containsObject:tempStream])
                {
                    [streamsSession addObject:tempStream];
                }
            }
        }
        else if(![streamsSession containsObject:tempStream])
        {
            [streamsSession addObject:tempStream];
        }

        conferenceFlag=(int)streamsSession.count;

        [self streamAndParticipantMapping:@"Add" :nil];
        
        if ([self.delegate respondsToSelector:@selector(sessionHasMedia::)]) {
            
            
            [self.delegate sessionHasMedia:stream:streamsSession];
        }
        
    }
    
}

// Triggered when a remote peer close a stream.
- (void)peerConnection:(RTCPeerConnection *)peerConnection
         removedStream:(RTCMediaStream *)stream
{
     LogDebug(@" PCO onRemoveStream");
    if (stream.videoTracks.count>0)
    {
        [stream removeVideoTrack:[stream.videoTracks objectAtIndex:0]];
        
        if ([self.delegate respondsToSelector:@selector(sessionRemoveVideoTrack)]) {
            [self.delegate sessionRemoveVideoTrack];
        }
    }
    
}

// Triggered when renegotation is needed, for example the ICE has restarted.
- (void)peerConnectionOnRenegotiationNeeded:(RTCPeerConnection *)peerConnection
{
     LogDebug(@" PCO onRenegotiationNeeded");
}


- (void)_timerICEConnCheck:(NSTimer *)timer{
    
    LogDebug(@"Webrtc:Stack:: _timerICEConnCheck");
    if(newICEConnState != RTCICEConnectionConnected){
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"ICE Connection Timeout" forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:Session code:ERR_ICE_CONNECTION_TIMEOUT userInfo:details];
        [self.delegate onSessionError:error.description errorCode:error.code additionalData:nil];
    }
    
}

// Called any time the ICEConnectionState changes.
- (void)peerConnection:(RTCPeerConnection *)peerConnection
  iceConnectionChanged:(RTCICEConnectionState)newState
{
    LogDebug(@"PCO onIceConnectionChange.%d", newState );
    LogDebug(@"Current State. %d", state);
    newICEConnState = newState;
    if (newState == RTCICEConnectionConnected)
    {
        // Change the audio session type to video chat as it has better audio processing logic
        AVAudioSession * audioSession = [AVAudioSession sharedInstance];
        if (audioSession != nil)
        {
            [audioSession setMode:AVAudioSessionModeVideoChat
                            error:nil];
            LogDebug(@"Webrtc:Session:: Audio mode is %@", audioSession.mode);
        }

        LogDebug(@"ICE Connection connected.");
        [statcollector stopMetric:self _statName:@"mediaConnectionTime"];
        
        //Set flag for updating turn server IP
        [WebRTCStatReport setTurnIPAvailabilityStatus:false];
        
        //Stop sending ping pong message as connection as established.
        _isSendingPingPongMsg = false;
    }
    else if(newState == RTCICEConnectionDisconnected)
    {
        LogDebug(@"ICE Connection disconnected");
        /*NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"ICE Connection disconnected" forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:Session code:ERR_ICE_CONNECTION_ERROR userInfo:details];
        [self.delegate onSessionError:error.description errorCode:error.code additionalData:nil];*/
        
        LogDebug(@"Sending ping messages on ICE disconnected");
	    _isSendingPingPongMsg = true;
        [self sendPingMessage];
        
        
    }
    
    else if(newState == RTCICEConnectionChecking)
    {
        NSTimer *_iceConnCheckTimer;
        _iceConnCheckTimer = [NSTimer scheduledTimerWithTimeInterval:ICE_CONNECTION_TIMEOUT
                                                       target:self
                                                     selector:@selector(_timerICEConnCheck:)
                                                     userInfo:nil
                                                      repeats:NO
        ];

    }
    else if(newState == RTCICEConnectionFailed)
    {
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"ICE Connection Couldn't be established" forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:Session code:ERR_ICE_CONNECTION_ERROR userInfo:details];
        [self.delegate onSessionError:error.description errorCode:error.code additionalData:nil];
     
    }
    
   // NSAssert(newState != RTCICEConnectionFailed, @"ICE Connection failed!");

}

// Called any time the ICEGatheringState changes.
- (void)peerConnection:(RTCPeerConnection *)peerConnection
   iceGatheringChanged:(RTCICEGatheringState)newState
{
    LogDebug(@"PCO onIceGatheringChange.%d",newState  );
    if (newState == RTCICEGatheringComplete)
    {

    }
}


// New Ice candidate have been found.
- (void)peerConnection:(RTCPeerConnection *)peerConnection
       gotICECandidate:(RTCICECandidate *)candidate
{
    // Form JSON
    NSDictionary *json =
    @{ @"type" : @"candidate",
       @"label" : [NSNumber numberWithInt:candidate.sdpMLineIndex],
       @"id" : candidate.sdpMid,
       @"candidate" : candidate.sdp };
   
    // Create data object
    NSError *error;
    NSData *data = [WebRTCJSONSerialization dataWithJSONObject:json options:0 error:&error];
    
    if (!error) {
        [self sendMessage:data];
    }
    else {
        NSAssert(NO, @"Unable to serialize candidate JSON object with error: %@",
                 error.localizedDescription);
    }
    
    // Send if we have got enough candidates
    if (isAnswerSent)
    {
        if (allcandidates.count > 10)
        {
            //[self sendCandidates:allcandidates];
            [allcandidates removeAllObjects];
        }
    }

}



//Channel delegates
-(void)onChannelOpened
{
    LogDebug(@"onChannelOpened");

    if (callType != incoming)
    {
        if (webrtcstack.isCapabilityExchangeEnable)
           [self sendCapability];
        
        [self startSession:updatedIceServers];
    }
}

-(void)onChannelMessage:(NSDictionary *)msg
{
    [self onSessionSignalingMessage:msg];
}


- (void) onChannelError:(NSString*)error errorCode:(NSInteger)code
{
    [self.delegate onSessionError:error errorCode:code additionalData:nil];
}

- (void) onChannelAck:(NSString *)sessionId
{
    if ([_delegate respondsToSelector:@selector(onSessionAck:)]) {
    
        [self.delegate onSessionAck:sessionId];
    }
    else
    {
         LogDebug(@" onChannelAck delegate not available to post");
    }
    
    rtcgid = sessionId;
    
    //Includeing rtcgsessionId as stats field
    NSDictionary *sessionIDInfo = @{ @"rtcgSessionId" :sessionId  };
    [statcollector storeReaccuring:self _statName:@"rtcgSessionId" _values:sessionIDInfo];
}

-(void)reconnectSession
{
   
}


    
- (void)peerConnection:(RTCPeerConnection*)peerConnection
      sendSuspendVideo:(BOOL)suspend_{
    
if(sessionConfig.isBWCheckEnable){
    LogDebug(@"Video is suspended :: %d",suspend_);
   
    if(suspend_ && !isVideoSuspended)
    {
        NSDictionary *json = @{@"type" : @"appmsg" , @"reason" : @"Bandwidth going down, Remote Video suspended"};
        [self onUserConfigSelection:json];
        isVideoSuspended = true;
        [self.delegate onDisplayMsg:[[json objectForKey:@"reason"] lowercaseString]];
    }
    else if(!suspend_ && isVideoSuspended)
    {
        NSDictionary *json = @{@"type" : @"appmsg" , @"reason" : @"Remote Video resumed "};
        [self onUserConfigSelection:json];
        isVideoSuspended = false;
        [self.delegate onDisplayMsg:[[json objectForKey:@"reason"] lowercaseString]];
    }
    
 }
    
}

- (void)peerConnection:(RTCPeerConnection*)peerConnection
          sendLogToApp:(NSString*)str severity:(int)sev{
    [self.delegate onReceivingSdkLogs:str severity:sev];
}


- (void)peerConnection:(RTCPeerConnection*)peerConnection
           didGetStats:(NSArray*)stats  // NSArray of RTCStatsReport*.
{
    //NSLog(@"Harish :: Complete stats = %@",stats);
    //WebRTCStatReport* sr = [[WebRTCStatReport alloc]init];
    //LogDebug(@"[XCMAV_LB]: didGetStats(): Complete Stats:: %@", stats);
    
    [lastSr parseReport:stats];
    NSDictionary *turnInfo = @{ @"turnIP" :[lastSr turnServerIP]};
    [statcollector storeReaccuring:self _statName:@"turnIP" _values:turnInfo];
    turnInfo = @{ @"turnUsed" :[NSNumber numberWithBool:[WebRTCStatReport isTurnIPAvailable]]};
    [statcollector storeReaccuring:self _statName:@"turnUsed" _values:turnInfo];
    turnIPToStat = [lastSr turnServerIP];
    turnUsedToStat = [NSString stringWithFormat:@"%d",[WebRTCStatReport isTurnIPAvailable]];
    
    
    //[self.delegate onReceiveStats:[lastSr toJSON]]; //Boomi


     
    //Need to send the stats to the server only after 10 sec.
    if(timeCounter == 10)
    {
        //lastSr = sr;
        [statcollector storeReaccuring:@"streamInfo" _values:[lastSr toJSON]];
        timeCounter = 0;
    }
    timeCounter++;
    
    NSInteger _packetLoss = 0;
    NSInteger _totalPackets = 0;
    NSInteger bandwidthInt = 0;
    
    // XCMAV: Incoming stats
    NSInteger _packetLoss_Rx = 0;
    NSInteger _totalPackets_Rx = 0;
    NSInteger bandwidthInt_Rx = 0;
    
    if((callType == incoming) && (sessionConfig.isOneWay == true))
    {
        //LogDebug(@"[XCMAV_LB]: didGetStats(): donotUpdate _rttArray. callType(%d), isOneWay(%d)", callType, sessionConfig.isOneWay);
        _packetLoss =  [lastSr packetLossRecv];
        _totalPackets = [lastSr totalPacketRecv];
        bandwidthInt = [lastSr recvBandwidth];
    }
    else
    {
        _packetLoss =  [lastSr packetLossSent];
        _totalPackets = [lastSr totalPacketSent];
        bandwidthInt = [lastSr sendBandwidth];
        
        /*LogDebug(@"[XCMAV_LB]: didGetStats(): Update _rttArray. INFO: callType(%d), isOneWay(%d): BW (send=%d, recv=%d), "
                 "_packetLoss(%d), _totalPackets(%d), rtt(%d)",
                 callType, sessionConfig.isOneWay, [lastSr sendBandwidth], [lastSr recvBandwidth], _packetLoss, _totalPackets, [lastSr rtt]);*/

        [_rttArray setObject:[NSNumber numberWithInteger:
                              [lastSr rtt]] atIndexedSubscript:_arrayIndex];
        
        // XCMAV: Incoming stats
        if (sessionConfig.isOneWay == false) {
            _packetLoss_Rx =  [lastSr packetLossRecv];
            _totalPackets_Rx = [lastSr totalPacketRecv];
            bandwidthInt_Rx = [lastSr recvBandwidth];
            //LogDebug(@"[XCMAV_LB]: didGetStats(): _packetLoss_Rx(%d), _totalPackets_Rx(%d), bandwidthInt_Rx(%d)",
                   //  _packetLoss_Rx, _totalPackets_Rx, bandwidthInt_Rx);
        }

    }
    
    //LogDebug(@"[XCMAV_LB]: didGetStats(): callType(%d) _arrayIndex(%d) _packetLoss(%d), _totalPackets(%d), bandwidthInt(%d)",
             //callType, _arrayIndex, _packetLoss, _totalPackets, bandwidthInt);

    //Converting BW to kbps
    bandwidthInt = bandwidthInt/1024;
    

    
    [_bandwidthArray setObject:[NSNumber numberWithInteger:bandwidthInt] atIndexedSubscript:_arrayIndex];
    
    NSInteger _packetLossVariance = (((_packetLoss - _offsetPacketLoss)*100)/(_totalPackets - _offsetTotalPacket));
    [_packetLossArray setObject:[NSNumber numberWithInteger:_packetLossVariance] atIndexedSubscript:_arrayIndex];
    
    //LogDebug(@"[XCMAV_LB]: didGetStats(): _packetLossVariance(%d), _packetLossArray(%@), _rttArray(%@), _bandwidthArray(%@)",
             //_packetLossVariance, _packetLossArray, _rttArray, _bandwidthArray);

    // XCMAV: Incoming stats
    if (sessionConfig.isOneWay == false) {
        _packetLossVariance = -1;
        _packetLossVariance = (((_packetLoss_Rx - _offsetPacketLoss_Rx)*100)/(_totalPackets_Rx - _offsetTotalPacket_Rx));
        [_packetLossArray_Rx setObject:[NSNumber numberWithInteger:_packetLossVariance] atIndexedSubscript:_arrayIndex];
        
        //Converting BW to kbps
        bandwidthInt_Rx = bandwidthInt_Rx/1024;
        [_bandwidthArray_Rx setObject:[NSNumber numberWithInteger:bandwidthInt_Rx] atIndexedSubscript:_arrayIndex];
        
        
        //LogDebug(@"[XCMAV_LB]: didGetStats(): _packetLossVariance(%d) _packetLossArray_Rx(%@), _rttArray(%@), _bandwidthArray_Rx(%@)",
                // _packetLossVariance, _packetLossArray_Rx, _rttArray, _bandwidthArray_Rx);
    }
    
    _arrayIndex++;
    if(_arrayIndex == NETWORK_CHECK_VAL)
    {
        _arrayIndex = 0;
    }
    
    //LogDebug(@"[XCMAV_LB]: didGetStats(): _offsetPacketLoss(%d -> %d), _offsetTotalPacket (%d -> %d), "
            // "_offsetPacketLoss_Rx(%d -> %d), _offsetTotalPacket_Rx(%d -> %d)",
            // _offsetPacketLoss, _packetLoss, _offsetTotalPacket, _totalPackets,
            // _offsetPacketLoss_Rx, _packetLoss_Rx, _offsetTotalPacket_Rx, _totalPackets_Rx);
    
    _offsetPacketLoss = _packetLoss;
    _offsetTotalPacket = _totalPackets;
    
    _offsetPacketLoss_Rx = _packetLoss_Rx;
    _offsetTotalPacket_Rx = _totalPackets_Rx;
    
    
    //NSLog(@"PacketLoss is = %@",_packetLossArray);
    //NSLog(@"RTT is = %@",_rttArray);
    //NSLog(@"AvailableSendBandwidth(kbps) is = %@",_bandwidthArray);
    
    //Determining NetworkState using packet loss and  RTT values
    //[self checkNetworkState];
    [lastSr streamStatArrayAlloc];
    [lastSr resetParams];
    
}

-(void)checkNetworkState
{
    //LogDebug(@"[XCMAV_LB]: checkNetworkState(ENTER): callType(%d), _currentRTTLevel(%d), _newRTTLevel(%d), maxRTT(%d)",
            // callType, _currentRTTLevel, _newRTTLevel, [[_rttArray valueForKeyPath:@"@max.self"]integerValue]);

    if((callType != incoming) || (sessionConfig.isOneWay == false))
    {
        //LogDebug(@"[XCMAV_LB]: checkNetworkState(): determining RTT Level: callType(%d), isOneWay(%d)", callType, sessionConfig.isOneWay);

        /* Determining RTT level */
        
        NSInteger maxRTT=[[_rttArray valueForKeyPath:@"@max.self"]integerValue];
        [self updateRTTLevel:maxRTT];
        
        if(_newRTTLevel <= _currentRTTLevel)
        {
            NSInteger minRTT=[[_rttArray valueForKeyPath:@"@min.self"]integerValue];
            [self updateRTTLevel:minRTT];
            if(_newRTTLevel < _currentRTTLevel)
                _currentRTTLevel = _newRTTLevel;
        }
        else
        {
            _currentRTTLevel = _newRTTLevel;
        }
        
         //NSLog(@"_currentRTTLevel = %u",_newRTTLevel);
    }
    
    /* Determining Packet Loss level */
    
    NSInteger maxPacketLoss=[[_packetLossArray valueForKeyPath:@"@max.self"]integerValue];
    [self updatePacketLossLevel:maxPacketLoss];
    
    /*LogDebug(@"[XCMAV_LB]: checkNetworkState(): maxPacketLoss(%d), _newPacketLossLevel(%d), _currentPacketLossLevel(%d)",
             maxPacketLoss, _newPacketLossLevel, _currentPacketLossLevel);*/

    if(_newPacketLossLevel <= _currentPacketLossLevel)
    {
        NSInteger minPacketLoss=[[_packetLossArray valueForKeyPath:@"@min.self"]integerValue];
        [self updatePacketLossLevel:minPacketLoss];
        
        //LogDebug(@"[XCMAV_LB]: checkNetworkState(): minPacketLoss(%d)", minPacketLoss);

        if(_newPacketLossLevel < _currentPacketLossLevel)
            _currentPacketLossLevel = _newPacketLossLevel;
    }
    else
    {
        _currentPacketLossLevel = _newPacketLossLevel;
    }
    //NSLog(@"_currentPacketLossLevel = %u",_currentPacketLossLevel);
    
    /* Determining Send Bandwidth level */
    
    NSInteger minBW = [[_bandwidthArray valueForKeyPath:@"@min.self"]integerValue];
    [self updateSendBWLevel:minBW];
    
    //LogDebug(@"[XCMAV_LB]: checkNetworkState(): minBW(%d), _newBWLevel(%d), _currentBWLevel(%d)", minBW, _newBWLevel, _currentBWLevel);

    if(_newBWLevel <= _currentBWLevel)
    {
        NSInteger maxSendBW=[[_bandwidthArray valueForKeyPath:@"@max.self"]integerValue];
        [self updateSendBWLevel:maxSendBW];
        
        //LogDebug(@"[XCMAV_LB]: checkNetworkState(): maxSendBW(%d)", maxSendBW);

        if(_newBWLevel < _currentBWLevel)
            _currentBWLevel = _newBWLevel;
    }
    else
    {
        _currentBWLevel = _newBWLevel;
    }
    //NSLog(@"_currentBWLevel = %u",_currentBWLevel);

    NSMutableDictionary* networkDetail = [NSMutableDictionary dictionary];
    NetworkQuality newNetworkQualityLevel;
    
    newNetworkQualityLevel =  MIN(_currentBWLevel, MIN(_currentPacketLossLevel, _currentRTTLevel));
    
    //LogDebug(@"[XCMAV_LB]: checkNetworkState(): newNetworkQualityLevel(%d):: MIN(_currentBWLevel[%d], "
            // "MIN((_currentPacketLossLevel=%d, _currentRTTLevel=%d), state(%d)",
            // newNetworkQualityLevel, _currentBWLevel, _currentPacketLossLevel, _currentRTTLevel, state);

    if(state == active)
    {
        //LogDebug(@"[XCMAV_LB]: checkNetworkState(): Network quality [new:%d old:%d], _currentBWLevel(%d), _currentPacketLossLevel(%d), _currentRTTLevel(%d) ", newNetworkQualityLevel, _oldNetworkQualityLevel, _currentBWLevel, _currentPacketLossLevel, _currentRTTLevel);

        if(newNetworkQualityLevel > _oldNetworkQualityLevel)
        {
            [networkDetail setValue:@"Network quality got improved !!!" forKey:WebRTCNetworkQualityReasonKey];
            
//            // XCMAV: This appears redundant, so move out the if-else.
//            [networkDetail setValue:[NSNumber numberWithInteger:newNetworkQualityLevel] forKey:WebRTCNetworkQualityLevelKey];
//            [self.delegate onSessionEvent:NetworkQualityIndicator eventData:networkDetail];
//            _oldNetworkQualityLevel = newNetworkQualityLevel;
        }
        else
            if(newNetworkQualityLevel != _oldNetworkQualityLevel)
            {
                if(_currentBWLevel <= _currentPacketLossLevel)
                {
                    if(_currentBWLevel <= _currentRTTLevel)
                    {
                        [networkDetail setValue:@"Network quality is weak due to low bandwidth" forKey:WebRTCNetworkQualityReasonKey];
                        newNetworkQualityLevel = _currentBWLevel;
                    }
                    else
                    {
                        [networkDetail setValue:@"Network quality is weak due to high RTT" forKey:WebRTCNetworkQualityReasonKey];
                        newNetworkQualityLevel = _currentRTTLevel;
                    }
                }
                else
                {
                    if(_currentPacketLossLevel <= _currentRTTLevel)
                    {
                        [networkDetail setValue:@"Network quality is weak due to packet loss" forKey:WebRTCNetworkQualityReasonKey];
                        newNetworkQualityLevel = _currentPacketLossLevel;
                    }
                    else
                    {
                        [networkDetail setValue:@"Network quality is weak due to high RTT" forKey:WebRTCNetworkQualityReasonKey];
                        newNetworkQualityLevel = _currentRTTLevel;
                        
                    }
                }
                
                // XCMAV: This appears redundant, so move out the if-else.
//                [networkDetail setValue:[NSNumber numberWithInteger:newNetworkQualityLevel] forKey:WebRTCNetworkQualityLevelKey];
//                [self.delegate onSessionEvent:NetworkQualityIndicator eventData:networkDetail];
//                _oldNetworkQualityLevel = newNetworkQualityLevel;
                
            }
        
        // XCMAV: Incoming stats
        if (sessionConfig.isOneWay == false) {
            // This logic keeps Incoming Stats consideration for 2wayVideo only.
            NetworkQuality nwQual_IncomingStats = [self checkNetworkState_IncomingStats];
            //LogDebug(@"[XCMAV_LB]: checkNetworkState(): Network quality: Rx(%d), Tx(%d), final(%d), state(%d)",
                 //    nwQual_IncomingStats, newNetworkQualityLevel, MIN(nwQual_IncomingStats, newNetworkQualityLevel), //state);
            
            if ([lastSr rxVideoFlag] == true) {
                // This logic delays considering Incoming stats, till Video frames are received.
                //LogDebug(@"[XCMAV_LB]: 2wayVideo checkNetworkState(): Network quality: Rx(%d)=used now, Tx(%d), //final(%d), state(%d)",
                       //  nwQual_IncomingStats, newNetworkQualityLevel, MIN(nwQual_IncomingStats, newNetworkQualityLevel), state);
                
                newNetworkQualityLevel = MIN (nwQual_IncomingStats, newNetworkQualityLevel);
            }
        }

        // XCMAV: This was redundant, so move out the if-else to here.
        [networkDetail setValue:[NSNumber numberWithInteger:newNetworkQualityLevel] forKey:WebRTCNetworkQualityLevelKey];
        [self.delegate onSessionEvent:NetworkQualityIndicator eventData:networkDetail];
        _oldNetworkQualityLevel = newNetworkQualityLevel;

    }
    
    
}

// XCMAV: Incoming stats
// This function calculates NetworkQuality for Incoming Stats (_packetLossArray, _bandwidthArray).
-(NetworkQuality)checkNetworkState_IncomingStats
{
    //NetworkQuality newNetworkQualityLevel;
    //LogDebug(@"[XCMAV_LB]: checkNetworkState_IncomingStats(ENTER): callType(%d), _packetLossArray_Rx(%@), _bandwidthArray_Rx(%@)",
             //callType, _packetLossArray_Rx, _bandwidthArray_Rx);
    
    /* Determining Packet Loss level */
    NSInteger maxPacketLoss=[[_packetLossArray_Rx valueForKeyPath:@"@max.self"]integerValue];
    [self updatePacketLossLevel:maxPacketLoss];
    
    //LogDebug(@"[XCMAV_LB]: checkNetworkState_IncomingStats(): maxPacketLoss(%d), _newPacketLossLevel(%d), _currentPacketLossLevel(%d)",
            // maxPacketLoss, _newPacketLossLevel, _currentPacketLossLevel);
    
    if(_newPacketLossLevel <= _currentPacketLossLevel)
    {
        NSInteger minPacketLoss=[[_packetLossArray_Rx valueForKeyPath:@"@min.self"]integerValue];
        [self updatePacketLossLevel:minPacketLoss];
        
        //LogDebug(@"[XCMAV_LB]: checkNetworkState_IncomingStats(): minPacketLoss(%d)", minPacketLoss);
        
        if(_newPacketLossLevel < _currentPacketLossLevel)
            _currentPacketLossLevel = _newPacketLossLevel;
    }
    else
    {
        _currentPacketLossLevel = _newPacketLossLevel;
    }
    //LogDebug(@"[XCMAV_LB]: checkNetworkState_IncomingStats(): _currentPacketLossLevel(%d)", _currentPacketLossLevel);
    
    /* Determining Receive Bandwidth level */
    NSInteger minBW = [[_bandwidthArray_Rx valueForKeyPath:@"@min.self"]integerValue];
    [self updateSendBWLevel:minBW]; // Varun: need to create a new function for ReceiveBWLevel
    
    //LogDebug(@"[XCMAV_LB]: checkNetworkState_IncomingStats(): minBW(%d), _newBWLevel(%d), _currentBWLevel(%d)", minBW, _newBWLevel, _currentBWLevel);
    
    if(_newBWLevel <= _currentBWLevel)
    {
        NSInteger maxSendBW=[[_bandwidthArray_Rx valueForKeyPath:@"@max.self"]integerValue];
        [self updateSendBWLevel:maxSendBW];
        
        //LogDebug(@"[XCMAV_LB]: checkNetworkState_IncomingStats(): maxSendBW(%d)", maxSendBW);
        
        if(_newBWLevel < _currentBWLevel)
            _currentBWLevel = _newBWLevel;
    }
    else
    {
        _currentBWLevel = _newBWLevel;
    }
    //LogDebug(@"[XCMAV_LB]: checkNetworkState_IncomingStats(): _currentBWLevel(%d)", _currentBWLevel);
    
    NetworkQuality newNetworkQualityLevel;
    newNetworkQualityLevel = MIN(_currentPacketLossLevel, _currentBWLevel);
    
    //LogDebug(@"[XCMAV_LB]: checkNetworkState_IncomingStats(): newNetworkQualityLevel(%d):: //MIN((_currentPacketLossLevel=%d, _currentBWLevel=%d)",
           //  newNetworkQualityLevel, _currentPacketLossLevel, _currentBWLevel);
    
    
    return newNetworkQualityLevel;
}



-(void)updatePacketLossLevel:(NSInteger)packetLossValue
{
    
    if(packetLossValue <  [[sessionConfig.packetLossThresholdLevels
                            objectForKey:WebRTCGoodNetworkQualityKey]integerValue])
    {
        _newPacketLossLevel = WebRTCExcellentNetwork;
    }
    else
    if((packetLossValue > [[sessionConfig.packetLossThresholdLevels
                            objectForKey:WebRTCGoodNetworkQualityKey]integerValue]) &&
        (packetLossValue < [[sessionConfig.packetLossThresholdLevels
                             objectForKey:WebRTCFairNetworkQualityKey]integerValue]))
    {
        _newPacketLossLevel = WebRTCGoodNetwork;
    }
    else
    if((packetLossValue > [[sessionConfig.packetLossThresholdLevels
                            objectForKey:WebRTCFairNetworkQualityKey]integerValue]) &&
        (packetLossValue < [[sessionConfig.packetLossThresholdLevels
                             objectForKey:WebRTCPoorNetworkQualityKey]integerValue]))
    {
        _newPacketLossLevel = WebRTCFairNetwork;
    }
    else
    if((packetLossValue > [[sessionConfig.packetLossThresholdLevels
                            objectForKey:WebRTCPoorNetworkQualityKey]integerValue]) &&
        (packetLossValue < [[sessionConfig.packetLossThresholdLevels
                             objectForKey:WebRTCBadNetworkQualityKey]integerValue]))
    {
        _newPacketLossLevel = WebRTCPoorNetwork;
    }
    else
    if(packetLossValue >  [[sessionConfig.packetLossThresholdLevels
                            objectForKey:WebRTCBadNetworkQualityKey]integerValue])
    {
        _newPacketLossLevel = WebRTCBadNetwork;
    }
    //LogDebug(@"[XCMAV_LB]: updatePacketLossLevel(): packetLossValue(%d), _newPacketLossLevel(%d)", packetLossValue, _newPacketLossLevel);
}

-(void)updateSendBWLevel:(NSInteger)sendBWValue
{
    if(sendBWValue >  [[sessionConfig.sendBWThresholdLevels
                        objectForKey:WebRTCGoodNetworkQualityKey]integerValue])
    {
        _newBWLevel = WebRTCExcellentNetwork;
    }
    else
    if((sendBWValue < [[sessionConfig.sendBWThresholdLevels
                        objectForKey:WebRTCGoodNetworkQualityKey]integerValue]) &&
        (sendBWValue > [[sessionConfig.sendBWThresholdLevels
                         objectForKey:WebRTCFairNetworkQualityKey]integerValue]))
    {
        _newBWLevel = WebRTCGoodNetwork;
    }
    else
    if((sendBWValue < [[sessionConfig.sendBWThresholdLevels
                        objectForKey:WebRTCFairNetworkQualityKey]integerValue]) &&
        (sendBWValue > [[sessionConfig.sendBWThresholdLevels
                         objectForKey:WebRTCPoorNetworkQualityKey]integerValue]))
    {
        _newBWLevel = WebRTCFairNetwork;
    }
    else
    if((sendBWValue < [[sessionConfig.sendBWThresholdLevels
                        objectForKey:WebRTCPoorNetworkQualityKey]integerValue]) &&
        (sendBWValue > [[sessionConfig.sendBWThresholdLevels
                         objectForKey:WebRTCBadNetworkQualityKey]integerValue]))
    {
        _newBWLevel = WebRTCPoorNetwork;
    }
    else
    if(sendBWValue <  [[sessionConfig.sendBWThresholdLevels
                        objectForKey:WebRTCBadNetworkQualityKey]integerValue])
    {
        _newBWLevel = WebRTCBadNetwork;
    }
    //LogDebug(@"[XCMAV_LB]: updateSendBWLevel(): sendBWValue(%d), _newBWLevel(%d)", sendBWValue, _newBWLevel);
}

-(void)updateRTTLevel:(NSInteger)rttValue
{
    
    if(rttValue <  [[sessionConfig.rttThresholdLevels
                     objectForKey:WebRTCGoodNetworkQualityKey]integerValue])
    {
        _newRTTLevel = WebRTCExcellentNetwork;
    }
    else
    if((rttValue > [[sessionConfig.rttThresholdLevels
                     objectForKey:WebRTCGoodNetworkQualityKey]integerValue]) &&
        (rttValue < [[sessionConfig.rttThresholdLevels
                      objectForKey:WebRTCFairNetworkQualityKey]integerValue]))
    {
        _newRTTLevel = WebRTCGoodNetwork;
    }
    else
    if((rttValue > [[sessionConfig.rttThresholdLevels
                     objectForKey:WebRTCFairNetworkQualityKey]integerValue]) &&
        (rttValue < [[sessionConfig.rttThresholdLevels
                      objectForKey:WebRTCPoorNetworkQualityKey]integerValue]))
    {
        _newRTTLevel = WebRTCFairNetwork;
    }
    else
    if((rttValue > [[sessionConfig.rttThresholdLevels
                     objectForKey:WebRTCPoorNetworkQualityKey]integerValue]) &&
        (rttValue < [[sessionConfig.rttThresholdLevels
                      objectForKey:WebRTCBadNetworkQualityKey]integerValue]))
    {
        _newRTTLevel = WebRTCPoorNetwork;
    }
    else
    if(rttValue >  [[sessionConfig.rttThresholdLevels
                     objectForKey:WebRTCBadNetworkQualityKey]integerValue])
    {
        _newRTTLevel = WebRTCBadNetwork;
    }
    
    //LogDebug(@"[XCMAV_LB]: updateRTTLevel(): rttValue(%d), _newRTTLevel(%d)", rttValue, _newRTTLevel);
}

-(void)bandwidthCheck:(NSInteger)BW
{
    
        if (  BW != 0 && BW < 30) {
            if (BWflag == false) {
                [localstream stopVideo];
            }
            BWflag = true;
            NSDictionary *json = @{@"type" : @"configselection" , @"reason" : @"Poor bandwidth,Video is shuttered"};
            [self onUserConfigSelection:json];
        }
        if (BW > 50 && BWflag == true) {
            [localstream startVideo];
            BWflag = false;
            NSDictionary *json = @{@"type" : @"configselection" , @"reason" : @"video is unshuttered"};
            [self onUserConfigSelection:json];
            
        }
    
    //LogDebug(@"[XCMAV_LB]: bandwidthCheck(): BW(%d), BWflag(%d)", BW, BWflag);
    
}

- (void) onUserConfigSelection:(NSDictionary*)json{

        [webrtcstack sendRTCMessage:json];

}

-(void)applySessionConfigChanges:(WebRTCSessionConfig*)configParam
{
    LogDebug(@"Inside applySessionConfigChanges");
    
    for (RTCMediaStream *stream in peerConnection.localStreams)
    {
        lms = stream;
        [peerConnection removeStream:stream];
        
    }
    
    [localstream applyStreamConfigChange:configParam.streamConfig];
    
   //[peerConnection addStream:lms constraints:nil];
   //[peerConnection addStream:lms];
     [peerConnection addStream:[localstream getMediaStream]];
    
}


- (NSDictionary *) getCapabilityData
{
    int device = webrtcstack.getMachineID;
    
    LogDebug(@"getCapabilityData::device= %d",device );
    
    NSNumber *minBlocks;
    NSNumber *maxBlocks;
    
    switch (webrtcstack.getMachineID)
    {
         case iPhone4:
            
            minBlocks = [NSNumber numberWithInt:VGA_MIN_BLOCKS];  //480p
            maxBlocks = [NSNumber numberWithInt:VGA_MAX_BLOCKS];
            break;
            
        case iPhone5:
            
            minBlocks = [NSNumber numberWithInt:HD_MIN_BLOCKS];   //720p
            maxBlocks = [NSNumber numberWithInt:HD_MAX_BLOCKS];
            break;
        
        case iPhone6:
            
            minBlocks = [NSNumber numberWithInt:FHD_MIN_BLOCKS];  //1080p
            maxBlocks = [NSNumber numberWithInt:FHD_MAX_BLOCKS];
            break;
            
        default:
            
            minBlocks = [NSNumber numberWithInt:DEFAULT_MINBLOCKS_RESOLUTION];
            maxBlocks = [NSNumber numberWithInt:DEFAULT_MAXBLOCKS_RESOLUTION];
            break;
    }
    
    NSString *secureProtocol = @"none";
    if([dtlsFlagValue isEqual:@"true"])
    {
        secureProtocol = @"srtpDtls";
    }
    
    NSDictionary *data =
    @{@"minBlocks" : minBlocks,
      @"maxBlocks" : maxBlocks,
      @"secureProtocol" : secureProtocol,
      @"video" : sessionConfig.video,
      @"audio" : sessionConfig.audio,
      @"data" : sessionConfig.data,
      @"one_way" : [NSNumber numberWithBool:sessionConfig.isOneWay],
      @"broadcast" : [NSNumber numberWithBool:sessionConfig.isBroadcast],
      @"app" : sessionConfig.appName};

    return data;
}

-(void)onCapabilityMessage:(NSDictionary*)msg
{
    /* Checking if the remote set top box is Pace platform.
        By default configured for Arris platform */
    //NSLog(@"WebRTCSession:onCapabilityMessage sessionConfig = %@",sessionConfig);
    NSDictionary* metaData = [msg objectForKey:@"meta"];
    NSString* platformType = [metaData objectForKey:@"platform"];
    bool isConfigResetRequired = false;
    NSMutableDictionary *newConfig = [[NSMutableDictionary alloc]init];
    

    
    //if ([platformType containsString:@"pace"]) {
    if ([platformType rangeOfString:@"pace"].location != NSNotFound) {
        LogDebug(@"Remote platform is Pace box, Configuring frame rate accordingly");
        localstream.getStreamConfig.maxFrameRate = 20;
        localstream.getStreamConfig.minFrameRate = 15;
        
        
        isConfigResetRequired = true;
    }
   /*else
    //if([platformType containsString:@"arris"])
    if ([platformType rangeOfString:@"arris"].location != NSNotFound)
    {
        LogDebug(@"Remote platform is Arris box, Configuring frame rate accordingly"];
        localstream.getStreamConfig.maxFrameRate = 20;
        localstream.getStreamConfig.minFrameRate = 30;
        isConfigResetRequired = true;

    }*/
    
    if(webrtcstack.isCapabilityExchangeEnable)
    {
        LogDebug(@"Inide onCapabilityMessage");
        
        NSInteger minBlocks = 0;
        NSInteger maxBlocks = 0;
        NSString *secureProtocol;
        NSString *video;
        NSString *audio;
        NSString *data;
        BOOL one_way;
        BOOL broadcast;
        
        @try{
            
            NSDictionary *dataMsg = [msg objectForKey:@"data"];
            
            if ([dataMsg objectForKey:@"minBlocks"] != Nil)
            {
                minBlocks = [[dataMsg objectForKey:@"minBlocks"] integerValue];
            }
            if ([dataMsg objectForKey:@"maxBlocks"] != Nil)
            {
                maxBlocks = [[dataMsg objectForKey:@"maxBlocks"] integerValue];
            }
            if ([dataMsg objectForKey:@"secureProtocol"] != Nil)
            {
                secureProtocol = [dataMsg objectForKey:@"secureProtocol"];
                
                if([secureProtocol  isEqual:@"srtpDtls"])
                {
                    [self setDTLSFlag:TRUE];
                }
                else if ([secureProtocol  isEqual:@"none"])
                {
                    [self setDTLSFlag:FALSE];
                }
            }
            if ([dataMsg objectForKey:@"video"] != Nil)
            {
                video = [dataMsg objectForKey:@"video"];
            }
            if ([dataMsg objectForKey:@"audio"] != Nil)
            {
                audio = [dataMsg objectForKey:@"audio"];
            }
            if ([dataMsg objectForKey:@"data"] != Nil)
            {
                data = [dataMsg objectForKey:@"data"];
            }
            if ([dataMsg objectForKey:@"one_way"] != Nil)
            {
                one_way = [[dataMsg objectForKey:@"one_way"] boolValue];
            }
            if ([dataMsg objectForKey:@"broadcast"] != Nil)
            {
                broadcast = [[dataMsg objectForKey:@"broadcast"] boolValue];
            }
            
            if ( (minBlocks == 0) || (maxBlocks == 0))
            {
                
                LogError(@"onCapabilityMessage error : empty minBlocks/maxBlocks ");
            }
            else
            {
                isConfigResetRequired = true;
                [self updateMediaConstraints:minBlocks max:maxBlocks];
            }
        }
        
        @catch(NSException *e)
        {

            LogError(@"Exception in onCapabilityMessage %@", e);
        }

    }
    
    if(isConfigResetRequired)
    {
        /*dispatch_async(dispatch_get_main_queue(), ^(void){
            
            sessionConfig.isConfigChange = true;
            localstream.getStreamConfig.isFlipCamera = false;
            for (RTCMediaStream *stream in peerConnection.localStreams)
            {
                lms = stream;
                [peerConnection removeStream:stream];
                
            }
            
            sessionConfig.isConfigChange = TRUE;
            localstream.getStreamConfig.isFlipCamera = false;
            
            [self updateMediaConstraints:minBlocks max:maxBlocks];
            
            [localstream applyStreamConfigChange:localstream.getStreamConfig];
            
            // [self applySessionConfigChanges:sessionConfig];
        });*/
        [newConfig setValue:[NSNumber numberWithInteger:localstream.getStreamConfig.maxFrameRate]  forKey:@"maxFrameRate"];
        [newConfig setValue:[NSNumber numberWithInteger:localstream.getStreamConfig.minFrameRate]  forKey:@"minFrameRate"];
        [[NSNotificationCenter defaultCenter]postNotificationName:@"ConfigurationDidChangeNotification" object:nil userInfo:newConfig];
    }
    

}

-(void)updateMediaConstraints:(NSInteger)minBlocks max:(NSInteger)maxBlocks
{
    int device = webrtcstack.getMachineID;

    LogDebug(@"updateMediaConstraints::machine ID= %d",device);
    
    switch (device)
    {
        case iPhone4:
            
            if (maxBlocks >= VGA_MAX_BLOCKS)
                [localstream.getStreamConfig setMediaConstraints:VGA];
            
            else
                [localstream.getStreamConfig setMediaConstraints:QVGA];
            
            break;
            
        case iPhone5:
            
            if (maxBlocks >= HD_MAX_BLOCKS)
                [localstream.getStreamConfig setMediaConstraints:HD];
            
            else if(maxBlocks >= VGA_MAX_BLOCKS)
                [localstream.getStreamConfig setMediaConstraints:VGA];
            
            else
                [localstream.getStreamConfig setMediaConstraints:QVGA];
            
            break;
            
        case iPhone6:
            
            if(maxBlocks >= FHD_MAX_BLOCKS)
                [localstream.getStreamConfig setMediaConstraints:FHD];
           
            else if(maxBlocks >= HD_MAX_BLOCKS)
                [localstream.getStreamConfig setMediaConstraints:HD];
            
            else if(maxBlocks  >= VGA_MAX_BLOCKS)
                [localstream.getStreamConfig setMediaConstraints:VGA];
            
            else
                [localstream.getStreamConfig setMediaConstraints:QVGA];
            
            break;
            
        default:
            
            [localstream.getStreamConfig setMediaConstraints:unknown];
            
    }
}

-(void)createReOffer
{
    LogDebug(@" createReOffer");
    
       
    isReOffer = true;
    //Peer connection constraints
    NSArray * constraintPairs = @[[[RTCPair alloc] initWithKey:@"googUseRtpMUX" value:@"true"],
                                  [[RTCPair alloc] initWithKey:@"IceRestart" value:@"true"],
                                  ];
    
    
    RTCMediaConstraints *constraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:constraintPairs
                                                                             optionalConstraints:nil];
    [peerConnection createOfferWithDelegate:self constraints:constraints];
    
}

-(void)networkReconnected
{
    
    
    if(callType != incoming)
    {
        [self createReOffer];
    }
    else
    {
        NSDictionary *reconnectD = @{ @"type" : @"remotereconnect" };
        NSError *jsonError = nil;
        NSData *reconnect = [WebRTCJSONSerialization dataWithJSONObject:reconnectD options:0 error:&jsonError];
        
        [self sendMessage:reconnect];
    }
}

-(void)sendMessage:(NSString *)targetId json:(NSDictionary *)json
{
    
    [self onUserConfigSelection:json];
}

-(void)createDataChannel
{
    RTCDataChannelInit* datainit = [[RTCDataChannelInit alloc] init];
    //datainit.streamId = 1;
    //datainit.maxRetransmits = 1;
    ///datainit.maxRetransmitTimeMs = 1;
    //datainit.
    _dataChannel = [peerConnection createDataChannelWithLabel:@"datachannel" config:nil];
    _dataChannel.delegate = self;
    cancelSendData = false;
    NSLog(@"DataChannel::Inside createDataChannel");
}

-(void)sendDataChannelMessage:(NSData*)imgData
{
    NSLog(@"DataChannel::Inside sendDataChannelMessage");
    if(isDataChannelOpened && _dataChannel != nil)
    {
        NSLog(@"DataChannel::Sending buffer");
        //NSData *data = [[NSData alloc]initWithBase64EncodedString:@"hi...its harish here" options:NSDataBase64DecodingIgnoreUnknownCharacters];
       // NSData* data = [@"hi...its harish here" dataUsingEncoding:NSUTF8StringEncoding];
        RTCDataBuffer *buffer = [[RTCDataBuffer alloc]initWithData:imgData isBinary:true];
        BOOL retValue = [_dataChannel sendData:buffer];
        if(!retValue)
        {
            cancelSendData = true;
            NSMutableDictionary* details = [NSMutableDictionary dictionary];
            [details setValue:@"Sending Image data failed" forKey:NSLocalizedDescriptionKey];
            NSError *error = [NSError errorWithDomain:Session code:ERR_DATA_SEND userInfo:details];
            [self.delegate onSessionError:error.description errorCode:error.code additionalData:nil];
        }
        NSLog(@"DataChannel::retValue = %d",retValue);
    }
  
}

#pragma mark - DataChannel Delegate

// Called when the data channel state has changed.
- (void)channelDidChangeState:(RTCDataChannel*)channel;
{
    NSLog(@"DataChannel::Inside channelDidChangeState");
    NSLog(@"channel.label = %@",channel.label);
    NSLog(@"channel.state = %d",channel.state);
    if(channel.state == kRTCDataChannelStateOpen)
    {
        isDataChannelOpened = true;
        
    }
    NSLog(@"channel.bufferedAmount = %lu",(unsigned long)channel.bufferedAmount);
}

// Called when a data buffer was successfully received.
- (void)channel:(RTCDataChannel*)channel
didReceiveMessageWithBuffer:(RTCDataBuffer*)buffer;
{
    NSData* dataBuff = [buffer data];
    NSLog(@"didReceiveMessageWithBuffer size = %lu",(unsigned long)[dataBuff length]);
    
    
    if([dataBuff length] < 500)
    {
        NSError* error;
        NSDictionary* json = [NSJSONSerialization JSONObjectWithData:dataBuff
                                                             options:kNilOptions
                                                               error:&error];
        if(json == nil)
        {
            [concatenatedData appendData:dataBuff];
        }
        else
        if ([[json allKeys] containsObject:@"action"])
        {
            NSString* action  = [[json objectForKey:@"action"] lowercaseString];
            NSLog(@"DataChannel::Inside didReceiveMessageWithBuffer action = %@",action);
            if(![action compare:@"start"])
            {
                recievedDataId = [json objectForKey:@"dataId"];
		        startTimeForDataSentStr = [json objectForKey:@"startTime"];
                [concatenatedData setLength:0];
                NSLog(@"didReceiveMessageWithBuffer: start recievedDataId= %@",recievedDataId);
            }
            else
                if(![action compare:@"stop"])
                {
                    NSString* stopDataId = [json objectForKey:@"dataId"];
                    NSDate* stopTimeForDataSent = [NSDate date];
                    NSLog(@"didReceiveMessageWithBuffer : stop recievedDataId = %@",recievedDataId);
                    NSLog(@"didReceiveMessageWithBuffer : stop total data length = %lu",
                                            (unsigned long)[concatenatedData length]/1024);
                    NSDate* startTimeForDataSent = [dateFormatter dateFromString:startTimeForDataSentStr];
                    CGFloat differenceInSec = [stopTimeForDataSent timeIntervalSinceDate:startTimeForDataSent];
                    NSLog(@"didReceiveMessageWithBuffer:Total time for transfered file is = %f",differenceInSec);
                    
                    if(![stopDataId compare:recievedDataId])
                    {
                        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                        NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Image.jpg"];
                        [concatenatedData writeToFile:filePath atomically:YES];
                        [self.delegate onSessionDataWithImage:filePath];
                        [concatenatedData setLength:0];
                    }
                    else
                    {
                        NSMutableDictionary* details = [NSMutableDictionary dictionary];
                        [details setValue:@"Data received is not complete" forKey:NSLocalizedDescriptionKey];
                        NSError *error = [NSError errorWithDomain:Session code:ERR_DATA_RECEIVED userInfo:details];
                        [self.delegate onSessionError:error.description errorCode:error.code additionalData:nil];
                    }
                    
                }
        }
    }
    else
    {
        [concatenatedData appendData:dataBuff];
    }
    
}

- (void)peerConnection:(RTCPeerConnection*)peerConnection
    didOpenDataChannel:(RTCDataChannel*)dataChannel;
{
    NSLog(@"DataChannel::Inside didOpenDataChannel");
    if (_dataChannel == nil)
    {
        _dataChannel = dataChannel;
        _dataChannel.delegate = self;
    }
}

-(void) sendCompressedImageData:(NSData*)imgData
{
    //NSData *_imgData= [NSData dataWithContentsOfFile:filePath];
    NSLog(@"Inside sendCompressedImageData");
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSUInteger length = [imgData length];
        NSUInteger offset = 0;
        NSError *jsonError = nil;
        NSString* dataID = [[NSUUID UUID] UUIDString];

        NSString* currentDate = [dateFormatter stringFromDate:[NSDate date]];
	
        NSMutableDictionary* json = [[NSMutableDictionary alloc]init];
	
        [json setValue:@"start" forKey:@"action"];
        [json setValue:dataID forKey:@"dataId"];
	    [json setValue:currentDate forKey:@"startTime"];
        NSLog(@"sendDataWithImage::Image ID = %@",dataID);
        NSLog(@"sendDataWithImage::total length = %ld",(unsigned long)length);
        
        NSData *data = [NSJSONSerialization dataWithJSONObject:json options:0 error:&jsonError];
        [self sendDataChannelMessage:data];
        
        do {
            if(cancelSendData)
                break;
            NSUInteger thisChunkSize = length - offset > sessionConfig.dataChunkSize ? sessionConfig.dataChunkSize : length - offset;
            NSLog(@"Sending imagePickerController::thisChunkSize = %ld offset = %ld",(unsigned long)thisChunkSize,(unsigned long)offset);
            NSData* chunk = [NSData dataWithBytesNoCopy:(char *)[imgData bytes] + offset
                                                 length:thisChunkSize
                                           freeWhenDone:NO];
            offset += thisChunkSize;
            
            [self sendDataChannelMessage:chunk];
        } while (offset < length);
        
        if(!cancelSendData)
        {
            [json removeAllObjects];
            [json setValue:@"stop" forKey:@"action"];
            [json setValue:dataID forKey:@"imageID"];
            data = [NSJSONSerialization dataWithJSONObject:json options:0 error:&jsonError];
            [self sendDataChannelMessage:data];
        }
    });

}

// Apply exif to the image
- (UIImage*)unrotateImage:(UIImage*)image {
    CGSize size = image.size;
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0,0,size.width ,size.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}
-(void) sendDataWithImage:(NSString*)filePath
{
    cancelSendData = false;
    NSURL* imgURL = [NSURL URLWithString:filePath];
    // Create assets library
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init] ;
    NSLog(@"sendDataWithImage");
    // Try to load asset at imgURL
    [library assetForURL:imgURL resultBlock:^(ALAsset *asset) {
        if (asset) {
            
            ALAssetRepresentation *repr = [asset defaultRepresentation];
            NSLog(@"sendDataWithImage: calling sendCompressedImageData [repr size] = %ld",(long)[repr size]);
            UIImage *image = [UIImage imageWithCGImage:[repr fullResolutionImage] scale:[repr scale] orientation:(UIImageOrientation)repr.orientation];
            UIImage *image2 = [self unrotateImage:image];
            
            // Based on the image, scale the image
            if(sessionConfig.dataScaleFactor == lowScale)
            {
                [self sendCompressedImageData:UIImageJPEGRepresentation(image2, 0.3)];
            }
            else
            if(sessionConfig.dataScaleFactor == midScale)
            {
                [self sendCompressedImageData:UIImageJPEGRepresentation(image2, 0.7)];
            }
            else
            if(sessionConfig.dataScaleFactor == original)
            {
                [self sendCompressedImageData:UIImageJPEGRepresentation(image2, [repr size])];
            }
            
        } else {
            
            NSMutableDictionary* details = [NSMutableDictionary dictionary];
            [details setValue:@"Sending Image data failed" forKey:NSLocalizedDescriptionKey];
            NSError *error = [NSError errorWithDomain:Session code:ERR_DATA_SEND userInfo:details];
            [self.delegate onSessionError:error.description errorCode:error.code additionalData:nil];
        }
    } failureBlock:^(NSError *error) {
        
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"Incorrect Image URL" forKey:NSLocalizedDescriptionKey];
        error = [NSError errorWithDomain:Session code:ERR_INCORRECT_URL userInfo:details];
        [self.delegate onSessionError:error.description errorCode:error.code additionalData:nil];
    }];
}

//Data channel API's to send either a NSString or a Json msg

-(void) sendDataWithText:(NSString*)_textMsg
{
    NSData* data = [_textMsg dataUsingEncoding:NSUTF8StringEncoding];
    [self sendDataChannelMessage:data];
}



-(void)finalStats{

     NSMutableDictionary* streamInfo1 = [[NSMutableDictionary alloc]init];
    
    NSMutableDictionary* streamInfo = [[NSMutableDictionary alloc]init];
    
    streamInfo1 =  [statcollector streamInfo];
    
    NSString *startTime = [NSString stringWithFormat:@"%@", [streamInfo1 objectForKey:@"startTime"]];
    NSString *stopTime = [NSString stringWithFormat:@"%@",[streamInfo1 objectForKey:@"stopTime"]];
    NSString *duration = [NSString stringWithFormat:@"%@", [streamInfo1 objectForKey:@"duration"]];
    
    if(startTime != nil)[streamInfo setObject:startTime forKey:@"startTime"];
    if(stopTime != nil)[streamInfo setObject:stopTime forKey:@"stopTime"];
    if(duration != nil)[streamInfo setObject:duration forKey:@"duration"];
    if(rtcgid != nil)[streamInfo setObject:rtcgid forKey:@"rtcgSessionId"];
    if(turnIPToStat != nil)[streamInfo setObject:turnIPToStat forKey:@"turnIP"];
    if(turnUsedToStat != nil)[streamInfo setObject:turnUsedToStat forKey:@"turnUsed"];
    
    [self.delegate finalStats:[lastSr stats] streamInfo:streamInfo];
}

- (void) sendXMPPSignalingMessage:(NSString *)message toUser:(NSString *)jidStr
{
    [[XMPPWorker sharedInstance] sendSignalingMessage:message toUser:jidStr];
}

- (void) sendXMPPJingleMessage:(NSString *)sid type:(NSString*)type data:(NSString *)data
{
    //[[XMPPWorker sharedInstance] sendJingleMessage:sid type:type data:data];
}

- (void)xmppWorker:(XMPPWorker *)sender didReceiveSignalingMessage:(XMPPMessage *)message
{
    if ([message isMessageWithBody]) {
        NSString *jidFrom = [[message from] bare];
        NSLog(@"jidFrom: %@", jidFrom);
        
        NSString *jsonStr = [message body];
        
        NSData *jsonData = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error;
        NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&error];
        NSString *type = [jsonDict objectForKey:@"type"];
        NSLog(@"jidFrom: %@", type);
        
        if ([type compare:@"offer"] == NSOrderedSame) {
            NSLog(@"Set jidFrom");
             [self setFromJid:jidFrom];
        }
        
        [self onSignalingMessage:jsonDict];
    }
    
}

#pragma mark - XMPP session delegate

- (void)xmppWorker:(XMPPWorker *)sender didReceiveSessionInitiate:(NSString *)to  sid:(NSString*)sid;
{
    NSLog(@"xmppWorker : didReceiveSessionInitiate,");
}

- (void)xmppWorker:(XMPPWorker *)sender didReceiveSetRemoteDescription:(NSXMLElement*)jingle type:(NSString*)type;
{
    NSLog(@"xmppWorker : didReceiveSetRemoteDescription,");
}

- (void)xmppWorker:(XMPPWorker *)sender didReceiveAddIceCandidates:(NSXMLElement*)jingleContent;
{
    NSLog(@"xmppWorker : didReceiveAddIceCandidates,");
}

- (void)xmppWorker:(XMPPWorker *)sender didJoinRoom:(NSString*)roomName;
{
    NSLog(@"xmppWorker : didJoinRoom");
    
    [[XMPPWorker sharedInstance] joinRoom:roomName appDelegate:self];
}


#pragma mark - XMPP room delegate

- (void)xmppRoomDidCreate:(XMPPRoom *)sender
{
    NSLog(@"XMPP Stack : xmppRoomDidCreate");
    // [self.xmppRoom changeRoomSubject:self.roomSubject];
    
}

- (void)xmppRoomDidJoin:(XMPPRoom *)sender
{
    NSLog(@"XMPP Stack : xmppRoomDidJoin");
    [[XMPPWorker sharedInstance] activateJingle:self];
    [self.delegate onRoomJoined:[[sender roomJID] user]];

    

}

- (void)xmppRoom:(XMPPRoom *)sender occupantDidJoin:(XMPPJID *)occupantJID withPresence:(XMPPPresence *)presence
{
    NSLog(@"XMPP Stack : xmppRoom occupantDidJoin");
    
    if (webrtcstack.isVideoBridgeEnable)
    {
        if ([[occupantJID full] containsString:@"focus"])
        {
            // Note down the occupant JID
            targetJid = occupantJID;
        }
    }
    else
    {
        // Note down the occupant JID
        targetJid = occupantJID;
        
        // If this is a pull call, send the session-initiate message
        if (callType == incoming)
            [self startSession:updatedIceServers];
    }
}

- (void)xmppRoom:(XMPPRoom *)sender occupantDidLeave:(XMPPJID *)occupantJID withPresence:(XMPPPresence *)presence
{
    NSLog(@"XMPP Stack : xmppRoom occupantDidLeave");
    if (webrtcstack.isVideoBridgeEnable)
    {
        if ([[occupantJID full] containsString:@"jirecon"])
        {
            return;
        }
    }
    
    //Close session
    [self.delegate onSessionEnd:@"Remote left room"];
    [statcollector stopMetric:@"callDuration"];

    if(_statsTimer != nil)
    [_statsTimer invalidate];

//    state = inactive;
//    [self closeSession];
//
//    // Disconnect socket
//    [[XMPPWorker sharedInstance] disconnect];
//
//    //Deactivate Jingle
//    [[XMPPWorker sharedInstance] deactivateJingle];

}

- (void)xmppRoom:(XMPPRoom *)sender didReceiveMessage:(XMPPMessage *)message fromOccupant:(XMPPJID *)occupantJID
{
    NSLog(@"XMPP Stack : xmppRoom didReceiveMessage");

}

#pragma mark - XMPP Jingle delegate

// For Action (type) attribute: "session-accept", "session-info", "session-initiate", "session-terminate"
- (void)didReceiveSessionMsg:(NSString *)sid type:(NSString *)type data:(NSDictionary *)data :(NSArray *)msids
{
    NSLog(@"XMPP Stack : xmppJingle didReceiveSessionMsg of type %@ with session id %@ with data %@ and msids %@", type, sid, data,msids);
    
    // Check the type of the message
    // For session-initiate, treat as incoming call and start the session
    // For session-accept, treat as outgoing call and set the answer SDP
    // For session-terminate, treat as bye message
    if ([type isEqualToString:@"session-accept"])
    {
        [self onAnswerMessage:data];
    }
    else if ([type isEqualToString:@"session-initiate"])
    {
        [self onOfferMessage:data];
    }
    else if ([type isEqualToString:@"source-add"])
    {
        // Storing the data to retrieve further after recieving iceserver
        peerConnectionId = [data objectForKey:@"peerConnectionId"];
        initialSDP = data;

        msidsSession=[msids mutableCopy];
        //Parse SDP string
        NSString *tempSdp = [initialSDP objectForKey:@"sdp"];
        NSString *backslashString = [tempSdp stringByReplacingOccurrencesOfString:@"\\\\" withString:@"\\"];
        NSString *backslashrString = [backslashString stringByReplacingOccurrencesOfString:@"\\r" withString:@"\r"];
        NSString *forwardslashrString = [backslashrString stringByReplacingOccurrencesOfString:@"\\/" withString:@"/"];
        NSString *sdpString = [forwardslashrString stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
        
        // Create session description
        RTCSessionDescription *sdp = [[RTCSessionDescription alloc]
                                      initWithType:@"offer" sdp:[self preferISAC:sdpString]];
        
        
        [peerConnection setRemoteDescriptionWithDelegate:self sessionDescription:sdp];
        
        [self createAnswer];

        NSLog(@"WebRTCSession:didReceiveSessionMsg:source-add");
    }
    else if ([type isEqualToString:@"source-remove"])
    {
        // Storing the data to retrieve further after recieving iceserver
        initialSDP = data;
        //check whether second participant is getting removed
        if (msidsSession.count>0)
        {
            [self streamAndParticipantMapping:@"Remove":msids];
        }
        else
        {
            if ([self.delegate respondsToSelector:@selector(sessionRemoveMedia::)]) {
                
                RTCMediaStream *stream=[[streamsSession objectAtIndex:0] objectForKey:@"streamInfo"];
                [self.delegate sessionRemoveMedia :stream :0];
            }
        }
        
        //Parse SDP string
        NSString *tempSdp = [initialSDP objectForKey:@"sdp"];
        NSString *backslashString = [tempSdp stringByReplacingOccurrencesOfString:@"\\\\" withString:@"\\"];
        NSString *backslashrString = [backslashString stringByReplacingOccurrencesOfString:@"\\r" withString:@"\r"];
        NSString *forwardslashrString = [backslashrString stringByReplacingOccurrencesOfString:@"\\/" withString:@"/"];
        NSString *sdpString = [forwardslashrString stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
        
        // Create session description
        RTCSessionDescription *sdp = [[RTCSessionDescription alloc]
                                      initWithType:@"offer" sdp:[self preferISAC:sdpString]];
        
        
        [peerConnection setRemoteDescriptionWithDelegate:self sessionDescription:sdp];
        
        //TODO
//      [self createAnswer];
        NSLog(@"WebRTCSession:didReceiveSessionMsg:source-remove");
    }
}

// For Action (type) attribute: "transport-accept", "transport-info", "transport-reject", "transport-replace"
- (void)didReceiveTransportMsg:(NSString *)sid type:(NSString *)type data:(NSDictionary *)data
{
    NSLog(@"XMPP Stack : xmppJingle didReceiveTransportMsg %@", data);
    
    if ([type isEqualToString:@"transport-info"])
    {
        [self onCandidateMessage:data];
    }

}

// For Action (type) attribute: "content-accept", "content-add", "content-modify", "content-reject", "content-remove"
- (void)didReceiveContentMsg:(NSString *)sid type:(NSString *)type data:(NSDictionary *)data
{
    NSLog(@"XMPP Stack : xmppJingle didReceiveContentMsg");

}

// For Action (type) attribute: "description-info"
- (void)didReceiveDescriptionMsg:(NSString *)sid type:(NSString *)type data:(NSDictionary *)data
{
    NSLog(@"XMPP Stack : xmppJingle didReceiveDescriptionMsg");

}

// In case any error is received
- (void)didReceiveError:(NSString *)sid error:(NSDictionary *)data
{
    NSLog(@"XMPP Stack : xmppJingle didReceiveError");

}


@end
