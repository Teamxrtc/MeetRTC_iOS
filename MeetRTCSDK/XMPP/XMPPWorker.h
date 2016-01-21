//
//  XMPPWorker.h
//  AppRTCDemo
//
//  Created by zhang zhiyu on 14-2-25.
//  Copyright (c) 2014年 YK-Unit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "XMPPFramework.h"
#import "XMPPRoom.h"
#import "XMPPJingle.h"

@protocol XMPPWorkerSignalingDelegate;

@protocol XMPPDelegate <NSObject>
- (void) onReady:(NSArray*) alias;
@end


@interface XMPPWorker : NSObject
<XMPPStreamDelegate,XMPPRosterDelegate>
{
    NSString *hostName;
    UInt16 hostPort;
    BOOL allowSelfSignedCertificates;
	BOOL allowSSLHostNameMismatch;
    
    NSString *userName;
    NSString *userPwd;
    
    BOOL isXmppConnected;
    BOOL isEngineRunning;
    
    __weak id<XMPPWorkerSignalingDelegate> signalingDelegate;
    __weak id<XMPPDelegate> xmppDelegate;
    
    XMPPStream *xmppStream;
	XMPPReconnect *xmppReconnect;
    XMPPRoster *xmppRoster;
	XMPPRosterCoreDataStorage *xmppRosterStorage;
    XMPPvCardCoreDataStorage *xmppvCardStorage;
	XMPPvCardTempModule *xmppvCardTempModule;
	XMPPvCardAvatarModule *xmppvCardAvatarModule;
	XMPPCapabilities *xmppCapabilities;
	XMPPCapabilitiesCoreDataStorage *xmppCapabilitiesStorage;
    
    BOOL customCertEvaluation;
    
    
    NSFetchedResultsController *fetchedResultsController_roster;
    NSString *currentRoom;
    NSString *password;
    
    NSString *focusUserjid;
    NSString *room;
    NSXMLElement *elemPres;
    NSString *jireconRid;
    
}
@property (nonatomic,copy) NSString *hostName;
@property (nonatomic,assign) UInt16 hostPort;
@property (nonatomic,assign) BOOL allowSelfSignedCertificates;
@property (nonatomic,assign) BOOL allowSSLHostNameMismatch;
@property (nonatomic,copy) NSString *userName;
@property (nonatomic,copy) NSString *userPwd;
@property (nonatomic,assign) BOOL isXmppConnected;
@property (nonatomic,assign) BOOL isEngineRunning;
@property (nonatomic,weak) id<XMPPWorkerSignalingDelegate> signalingDelegate;
@property (nonatomic,weak) id<XMPPDelegate> xmppDelegate;
@property(nonatomic) BOOL isVideoBridgeEnable;
@property (nonatomic) BOOL isSecuredConnect;

@property (nonatomic, strong, readonly) XMPPStream *xmppStream;
@property (nonatomic, strong, readonly) XMPPReconnect *xmppReconnect;
@property (nonatomic, strong, readonly) XMPPRoster *xmppRoster;
@property (nonatomic, strong, readonly) XMPPRosterCoreDataStorage *xmppRosterStorage;
@property (nonatomic, strong, readonly) XMPPvCardTempModule *xmppvCardTempModule;
@property (nonatomic, strong, readonly) XMPPvCardAvatarModule *xmppvCardAvatarModule;
@property (nonatomic, strong, readonly) XMPPCapabilities *xmppCapabilities;
@property (nonatomic, strong, readonly) XMPPCapabilitiesCoreDataStorage *xmppCapabilitiesStorage;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController_roster;


+ (XMPPWorker *)sharedInstance;

/*
best to run it IN THIS ORDER
startEngine ➝ [connect ⇄ disconnect] ➝ stopEngine
 */
- (void)startEngine;
- (void)setupStream;
- (void)stopEngine;
- (BOOL)connect;
- (void)disconnect;
- (void)setXMPPDelegate:del;
- (void)joinRoom: (NSString *)roomName appDelegate:(id<XMPPRoomDelegate>)appDelegate;
- (void)leaveRoom;
- (void)activateJingle: (id<XMPPJingleDelegate>)appDelegate;
- (void)deactivateJingle;
- (void)allocateConferenceFocus:roomName;

- (void)sendSignalingMessage:(NSString *)message toUser:(NSString *)jidStr;
- (void)sendJingleMessage:(NSString*)type data:(NSDictionary*)data target:(XMPPJID *)target;
- (void)sendVideoInfo:(NSString*)type data:(NSDictionary*)data target:(XMPPJID *)target;
- (void)sendPresenceAlive;
- (void)dial:(NSString*)to from:(NSString*)from;
- (void)hangup;
- (void)record:(NSString*)state;

//Recording
- (XMPPIQ*)setRecordingJirecon:(NSString*)state tok:(NSString*)token target:(NSString*)target;
- (XMPPIQ*)setRecordingColibri:(NSString*)state tok:(NSString*)token target:(NSString*)target;


@end


@protocol XMPPWorkerSignalingDelegate <NSObject>
@optional
// Called when receive a signaling message.
- (void)xmppWorker:(XMPPWorker *)sender didReceiveSignalingMessage:(XMPPMessage *)message;
- (void)xmppWorker:(XMPPWorker *)sender didReceiveSessionInitiate:(NSString *)to  sid:(NSString*)sid;
- (void)xmppWorker:(XMPPWorker *)sender didReceiveSetRemoteDescription:(NSXMLElement*)jingle type:(NSString*)type;
- (void)xmppWorker:(XMPPWorker *)sender didReceiveAddIceCandidates:(NSXMLElement*)jingleContent;
- (void)xmppWorker:(XMPPWorker *)sender didJoinRoom:(NSString*)roomName;

@end
