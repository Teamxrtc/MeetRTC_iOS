//
//  XMPPWorker.m
//  AppRTCDemo
//
//  Created by zhang zhiyu on 14-2-25.
//  Copyright (c) 2014年 YK-Unit. All rights reserved.
//

#import "XMPPWorker.h"
#import "XMPPMessage+Signaling.h"

#import "GCDAsyncSocket.h"
#import "XMPP.h"
#import "XMPPLogging.h"
#import "XMPPReconnect.h"
#import "XMPPCapabilitiesCoreDataStorage.h"
#import "XMPPRosterCoreDataStorage.h"
#import "XMPPvCardAvatarModule.h"
#import "XMPPvCardCoreDataStorage.h"

// Manish
#import "XMPPRoom.h"
#import "XMPPRoomHybridStorage.h"
#import "XMPPJingle.h"

//Vamsi
#import "XMPPRayo.h"

#import "DDLog.h"
#import "DDTTYLogger.h"

#import <CFNetwork/CFNetwork.h>

// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif

@interface XMPPWorker()
//- (void)setupStream;
- (void)teardownStream;

- (void)goOnline;
- (void)goOffline;

- (NSManagedObjectContext *)managedObjectContext_roster;
- (NSManagedObjectContext *)managedObjectContext_capabilities;

// Manish
@property (nonatomic, strong) XMPPRoomHybridStorage* xmppRoomStorage;
@property (nonatomic, strong) XMPPRoom* xmppRoom;
@property (nonatomic, strong) XMPPJingle* xmppJingle;


@end

@implementation XMPPWorker
@synthesize hostName,hostPort;
@synthesize allowSelfSignedCertificates,allowSSLHostNameMismatch;
@synthesize userName,userPwd;
@synthesize isXmppConnected,isEngineRunning;
@synthesize signalingDelegate;
@synthesize xmppStream;
@synthesize xmppReconnect;
@synthesize xmppRoster;
@synthesize xmppRosterStorage;
@synthesize xmppvCardTempModule;
@synthesize xmppvCardAvatarModule;
@synthesize xmppCapabilities;
@synthesize xmppCapabilitiesStorage;
@synthesize fetchedResultsController_roster;
@synthesize isVideoBridgeEnable,isSecuredConnect;


+ (XMPPWorker *)sharedInstance
{
    static dispatch_once_t pred = 0;
    __strong static XMPPWorker *_sharedXMPPWorker = nil;
    dispatch_once(&pred, ^{
        _sharedXMPPWorker = [[self alloc] init];
    });
    return _sharedXMPPWorker;
}

- (id)init
{
    self = [super init];
    if (self) {
        hostName = NULL;
        hostPort = 0;
        allowSelfSignedCertificates = NO;
        allowSSLHostNameMismatch = NO;
        
        isXmppConnected = NO;
        isEngineRunning = NO;        
        isVideoBridgeEnable = true;
    }
    return self;
}

- (void)dealloc
{
    if (isEngineRunning) {
        [self stopEngine];
    }
    
    if (fetchedResultsController_roster) {
        fetchedResultsController_roster.delegate = Nil;
    }
    
    self.signalingDelegate = Nil;
}

#pragma mark - private methods
- (void)setupStream
{
	NSAssert(xmppStream == nil, @"Method setupStream invoked multiple times");
	
	// Setup xmpp stream
	//
	// The XMPPStream is the base class for all activity.
	// Everything else plugs into the xmppStream, such as modules/extensions and delegates.
    
	xmppStream = [[XMPPStream alloc] init];
	
#if !TARGET_IPHONE_SIMULATOR
	{
		// Want xmpp to run in the background?
		//
		// P.S. - The simulator doesn't support backgrounding yet.
		//        When you try to set the associated property on the simulator, it simply fails.
		//        And when you background an app on the simulator,
		//        it just queues network traffic til the app is foregrounded again.
		//        We are patiently waiting for a fix from Apple.
		//        If you do enableBackgroundingOnSocket on the simulator,
		//        you will simply see an error message from the xmpp stack when it fails to set the property.
		
		xmppStream.enableBackgroundingOnSocket = YES;
	}
#endif
	
	// Setup reconnect
	//
	// The XMPPReconnect module monitors for "accidental disconnections" and
	// automatically reconnects the stream for you.
	// There's a bunch more information in the XMPPReconnect header file.
	
	xmppReconnect = [[XMPPReconnect alloc] init];
	
	// Setup roster
	//
	// The XMPPRoster handles the xmpp protocol stuff related to the roster.
	// The storage for the roster is abstracted.
	// So you can use any storage mechanism you want.
	// You can store it all in memory, or use core data and store it on disk, or use core data with an in-memory store,
	// or setup your own using raw SQLite, or create your own storage mechanism.
	// You can do it however you like! It's your application.
	// But you do need to provide the roster with some storage facility.
	
	xmppRosterStorage = [[XMPPRosterCoreDataStorage alloc] init];
    //	xmppRosterStorage = [[XMPPRosterCoreDataStorage alloc] initWithInMemoryStore];
	
	xmppRoster = [[XMPPRoster alloc] initWithRosterStorage:xmppRosterStorage];
	
	xmppRoster.autoFetchRoster = YES;
	xmppRoster.autoAcceptKnownPresenceSubscriptionRequests = YES;
	
	// Setup vCard support
	//
	// The vCard Avatar module works in conjuction with the standard vCard Temp module to download user avatars.
	// The XMPPRoster will automatically integrate with XMPPvCardAvatarModule to cache roster photos in the roster.
	
	xmppvCardStorage = [XMPPvCardCoreDataStorage sharedInstance];
	xmppvCardTempModule = [[XMPPvCardTempModule alloc] initWithvCardStorage:xmppvCardStorage];
	
	xmppvCardAvatarModule = [[XMPPvCardAvatarModule alloc] initWithvCardTempModule:xmppvCardTempModule];
	
	// Setup capabilities
	//
	// The XMPPCapabilities module handles all the complex hashing of the caps protocol (XEP-0115).
	// Basically, when other clients broadcast their presence on the network
	// they include information about what capabilities their client supports (audio, video, file transfer, etc).
	// But as you can imagine, this list starts to get pretty big.
	// This is where the hashing stuff comes into play.
	// Most people running the same version of the same client are going to have the same list of capabilities.
	// So the protocol defines a standardized way to hash the list of capabilities.
	// Clients then broadcast the tiny hash instead of the big list.
	// The XMPPCapabilities protocol automatically handles figuring out what these hashes mean,
	// and also persistently storing the hashes so lookups aren't needed in the future.
	//
	// Similarly to the roster, the storage of the module is abstracted.
	// You are strongly encouraged to persist caps information across sessions.
	//
	// The XMPPCapabilitiesCoreDataStorage is an ideal solution.
	// It can also be shared amongst multiple streams to further reduce hash lookups.
	
    
    /*  Manish: this was the original code
     
     xmppCapabilitiesStorage = [XMPPCapabilitiesCoreDataStorage sharedInstance];
     xmppCapabilities = [[XMPPCapabilities alloc] initWithCapabilitiesStorage:xmppCapabilitiesStorage];
     
     xmppCapabilities.autoFetchHashedCapabilities = YES;
     xmppCapabilities.autoFetchNonHashedCapabilities = NO;
     
     // Activate xmpp modules
     
     [xmppReconnect         activate:xmppStream];
     [xmppRoster            activate:xmppStream];
     [xmppvCardTempModule   activate:xmppStream];
     [xmppvCardAvatarModule activate:xmppStream];
     [xmppCapabilities      activate:xmppStream];

    */
    
	xmppCapabilitiesStorage = [XMPPCapabilitiesCoreDataStorage sharedInstance];
    xmppCapabilities = [[XMPPCapabilities alloc] initWithCapabilitiesStorage:xmppCapabilitiesStorage];
    
    xmppCapabilities.autoFetchHashedCapabilities = NO;
    xmppCapabilities.autoFetchNonHashedCapabilities = NO;
    xmppCapabilities.autoFetchMyServerCapabilities = YES;

	// Activate xmpp modules
    
	[xmppReconnect         activate:xmppStream];
    
    
    // Manish: we need however 0030 and 0045
    // 0030 is based on 0115 so lets use that and set properties to use 0030
    [xmppCapabilities      activate:xmppStream];
    
    /* Join room
    // MUC
    self.xmppRoomStorage = [XMPPRoomHybridStorage sharedInstance];
    self.xmppRoom = [[XMPPRoom alloc] initWithRoomStorage:self.xmppRoomStorage jid:xmppStream.myJID];
    
    [self.xmppRoom addDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    [self.xmppRoom activate:self.xmppStream];
     */
	  
    // Manish: We dont need XEP 0115 or 0153 or 154 or 144
    //[xmppRoster            activate:xmppStream];
    //[xmppvCardTempModule   activate:xmppStream];
    //[xmppvCardAvatarModule activate:xmppStream];
    //[xmppCapabilities      activate:xmppStream];
    
	// Add ourself as a delegate to anything we may be interested in
    
    
	[xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
	[xmppRoster addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
	// Optional:
	//
	// Replace me with the proper domain and port.
	// The example below is setup for a typical google talk account.
	//
	// If you don't supply a hostName, then it will be automatically resolved using the JID (below).
	// For example, if you supply a JID like 'user@quack.com/rsrc'
	// then the xmpp framework will follow the xmpp specification, and do a SRV lookup for quack.com.
	//
	// If you don't specify a hostPort, then the default (5222) will be used.
	
    //	[xmppStream setHostName:@"talk.google.com"];
    //	[xmppStream setHostPort:xxxx];
    
    //Vamsi
    //[xmppStream setHostName:@"x.x.x.x"];
    //[xmppStream setHostPort:xxxx];
    
    // You may need to alter these settings depending on the server you're connecting to
    customCertEvaluation = YES;
    
    //Jingle ... Need to check this
    /*allowSelfSignedCertificates = NO;
    allowSSLHostNameMismatch = NO;
    allAudioCodecs = [xmppJingle emptyAudioPayload];
    NSArray * codecs = [[phono papi] codecArray];
    for (int i=0; i< [codecs count]; i++){
        NSDictionary *codec = [codecs objectAtIndex:i];
        [xmppJingle addCodecToPayload:allAudioCodecs name:[codec objectForKey:@"name"] rate:[codec objectForKey:@"rate"] ptype:[codec objectForKey:@"ptype"]];
    }*/

}

- (void)teardownStream
{
	[xmppStream removeDelegate:self];
	[xmppRoster removeDelegate:self];
	
	[xmppReconnect         deactivate];
	[xmppRoster            deactivate];
	[xmppvCardTempModule   deactivate];
	[xmppvCardAvatarModule deactivate];
	[xmppCapabilities      deactivate];
	
	[xmppStream disconnect];
	
	xmppStream = nil;
	xmppReconnect = nil;
    xmppRoster = nil;
	xmppRosterStorage = nil;
	xmppvCardStorage = nil;
    xmppvCardTempModule = nil;
	xmppvCardAvatarModule = nil;
	xmppCapabilities = nil;
	xmppCapabilitiesStorage = nil;
}

- (void)goOnline
{
	XMPPPresence *presence = [XMPPPresence presence]; // type="available" is implicit
    
    NSString *domain = [xmppStream.myJID domain];
    
    //Google set their presence priority to 24, so we do the same to be compatible.
    
    if([domain isEqualToString:@"gmail.com"]
       || [domain isEqualToString:@"gtalk.com"]
       || [domain isEqualToString:@"talk.google.com"])
    {
        NSXMLElement *priority = [NSXMLElement elementWithName:@"priority" stringValue:@"24"];
        [presence addChild:priority];
    }
	
	[[self xmppStream] sendElement:presence];
}

// Manish: Method to join a room
- (void)joinRoom: (NSString *)roomName appDelegate:(id<XMPPRoomDelegate>)appDelegate
{
    NSString *fullRoomName;
    if(!isVideoBridgeEnable)
    {
        // muc changes
        fullRoomName = [NSString stringWithFormat:@"%@.%@", roomName, [xmppStream.myJID domain]];
    }
    else
    {
        // New DNS related changes
        //fullRoomName = [NSString stringWithFormat:@"%@%@", roomName, [xmppStream.myJID domain]];
        fullRoomName = roomName;
    }
    self.xmppRoomStorage = [XMPPRoomHybridStorage sharedInstance];
    NSLog(@"XMPP Worker Joining room %@", fullRoomName );
    self.xmppRoom = [[XMPPRoom alloc] initWithRoomStorage:self.xmppRoomStorage jid:[XMPPJID jidWithString:fullRoomName]];
    
    [self.xmppRoom addDelegate:appDelegate delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    [self.xmppRoom activate:self.xmppStream];
    [self.xmppRoom joinRoomUsingNickname:[xmppStream.myJID user] history:nil];
}

- (void)leaveRoom
{
    [self.xmppRoom leaveRoom];
}

// Manish: Start doing jingle
- (void)activateJingle: (id<XMPPJingleDelegate>)appDelegate
{
    NSLog(@"XMPP Worker Activating Jingle " );
    self.xmppJingle = [[XMPPJingle alloc] init];
    [self.xmppJingle SetDelegate:appDelegate];
    [self.xmppJingle activate:self.xmppStream];
}

// Manish: Stop doing jingle
- (void)deactivateJingle
{
    NSLog(@"XMPP Worker Deactivating Jingle " );
    [self.xmppJingle SetDelegate:nil];
    [self.xmppJingle deactivate];
    self.xmppJingle = nil;
}

- (void)sendJingleMessage:(NSString*)type data:(NSDictionary*)data target:(XMPPJID *)target
{
    if ([type hasPrefix:@"session"])
    {
        [self.xmppJingle sendSessionMsg:type data:data target:target];
    }
    else if ([type hasPrefix:@"transport"])
    {
        [self.xmppJingle sendTransportMsg:type data:data target:target];
        
    }
    else if ([type hasPrefix:@"source"])
    {
    }
}

- (void)sendVideoInfo:(NSString*)type data:(NSDictionary*)data target:(XMPPJID *)target
{
    elemPres = [self.xmppJingle getVideoContent:type data:data target:target];
    [self sendPresenceWithVideoInfo];
    
    [NSTimer scheduledTimerWithTimeInterval:10
                                     target:self
                                   selector:@selector(sendPresenceWithVideoInfo)
                                   userInfo:nil
                                    repeats:YES
     ];
}

- (void)sendPresenceAlive
{
    [NSTimer scheduledTimerWithTimeInterval:30
                                     target:self
                                   selector:@selector(sendAlive)
                                   userInfo:nil
                                    repeats:YES
     ];
}

- (void)goOffline
{
	XMPPPresence *presence = [XMPPPresence presenceWithType:@"unavailable"];
	
	[[self xmppStream] sendElement:presence];
}

#pragma mark - public methods
- (void)startEngine
{
    [self setupStream];
    isEngineRunning = YES;
}

- (void)stopEngine
{
    [self teardownStream];
    isEngineRunning = NO;
}

- (BOOL)connect
{
    if (![xmppStream isDisconnected]) {
        return YES;
    }
   
    if (!self.userName || !self.userPwd) {
        return NO;
    }
    
    //userName should be name@domain
    [xmppStream setMyJID:[XMPPJID jidWithString:self.userName]];
    [xmppStream setIsSecureConnect:isSecuredConnect];
    password = self.userPwd;

    NSError *error = nil;
    if (![xmppStream connectWithTimeout :XMPPStreamTimeoutNone error:&error])
	{
		//EASYLogError(@"Error connecting: %@", error);
        
		return NO;
	}
    
    return YES;
}

- (void)disconnect
{
    [self goOffline];
	[xmppStream disconnect];
}

- (void)sendSignalingMessage:(NSString *)message toUser:(NSString *)jidStr
{
    NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
    [body setStringValue:message];
    
    XMPPJID *toJID = [XMPPJID jidWithString:jidStr];
    
    XMPPMessage *xmppMessage = [XMPPMessage signalingMessageTo:toJID elementID:Nil child:body];
    [xmppStream sendElement:xmppMessage];
}

- (void)setHostName:(NSString *)name
{
    if (name) {
        hostName = Nil;
        hostName = [name copy];

        if (xmppStream) {
            [xmppStream setHostName:name];
        }
    }
}

- (void)setHostPort:(UInt16)port
{
    if (port) {
        hostPort = port;
        if (hostPort) {
            [xmppStream setHostPort:port];
        }
    }
}

#pragma mark - Core Data
- (NSManagedObjectContext *)managedObjectContext_roster
{
	return [xmppRosterStorage mainThreadManagedObjectContext];
}

- (NSManagedObjectContext *)managedObjectContext_capabilities
{
	return [xmppCapabilitiesStorage mainThreadManagedObjectContext];
}

- (void)setXMPPDelegate:del
{
    _xmppDelegate = (id< XMPPDelegate >) del;
}

#pragma mark - fetchedResultsController_roster
- (NSFetchedResultsController *)fetchedResultsController_roster
{
    if (fetchedResultsController_roster == Nil) {
        NSManagedObjectContext *moc = [self managedObjectContext_roster];
		
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPUserCoreDataStorageObject"
            inManagedObjectContext:moc];
		
		NSSortDescriptor *sd1 = [[NSSortDescriptor alloc] initWithKey:@"sectionNum" ascending:YES];
		NSSortDescriptor *sd2 = [[NSSortDescriptor alloc] initWithKey:@"displayName" ascending:YES];
		
		NSArray *sortDescriptors = [NSArray arrayWithObjects:sd1, sd2, nil];
		
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		[fetchRequest setEntity:entity];
		[fetchRequest setSortDescriptors:sortDescriptors];
		[fetchRequest setFetchBatchSize:10];
		
		fetchedResultsController_roster = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
            managedObjectContext:moc
            sectionNameKeyPath:@"sectionNum"
            cacheName:nil];
		
		NSError *error = nil;
		if (![fetchedResultsController_roster performFetch:&error])
		{
			//EASYLogError(@"Error performing fetch: %@", error);
		}
        
    }
    
    return fetchedResultsController_roster;
}

#pragma mark - XMPPStreamDelegate

- (void)xmppStream:(XMPPStream *)sender socketDidConnect:(GCDAsyncSocket *)socket
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStream:(XMPPStream *)sender willSecureWithSettings:(NSMutableDictionary *)settings
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	
	if (allowSelfSignedCertificates)
	{
		[settings setObject:[NSNumber numberWithBool:YES] forKey:(NSString *)kCFStreamSSLAllowsAnyRoot];
	}
	
	if (allowSSLHostNameMismatch)
	{
		[settings setObject:[NSNull null] forKey:(NSString *)kCFStreamSSLPeerName];
	}
	else
	{
		NSString *expectedCertName = [xmppStream.myJID domain];
        
		if (expectedCertName)
		{
			[settings setObject:expectedCertName forKey:(NSString *)kCFStreamSSLPeerName];
		}
	}
}

- (void)xmppStream:(XMPPStream *)sender didReceiveTrust:(SecTrustRef)trust
 completionHandler:(void (^)(BOOL shouldTrustPeer))completionHandler
{
    //DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    // The delegate method should likely have code similar to this,
    // but will presumably perform some extra security code stuff.
    // For example, allowing a specific self-signed certificate that is known to the app.
    
    dispatch_queue_t bgQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(bgQueue, ^{
        
        SecTrustResultType result = kSecTrustResultDeny;
        OSStatus status = SecTrustEvaluate(trust, &result);
        
        if (status == noErr && (result == kSecTrustResultProceed || result == kSecTrustResultUnspecified)) {
            completionHandler(YES);
        }
        else {
            completionHandler(NO);
        }
    });
}


- (void)xmppStreamDidSecure:(XMPPStream *)sender
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStreamDidConnect:(XMPPStream *)sender
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	
	isXmppConnected = YES;
    
	//***arunkavi -for anonymous
    NSError *authenticationError = nil;
    [[self xmppStream] authenticateAnonymously:&authenticationError];
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	
	[self goOnline];
    NSArray* alias = [[NSArray alloc] init];

    [self.xmppDelegate onReady:alias];

}

- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *
                                                      
                                                      )iq
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
	// muc changes
    NSLog(@"xmppStream : didReceiveIQ %@", iq.description);
    
    if ([iq isResultIQ])
    {
       NSXMLElement *elem = [iq elementForName:@"conference" xmlns:@"http://jitsi.org/protocol/focus"];
       
       if (elem != nil)
       {
          NSString *ready = [elem attributeStringValueForName:@"ready"];
           
           if ([ready isEqual:@"true"])
           {
               //parse config options
               focusUserjid = [elem attributeStringValueForName:@"focusjid"];
               
               //TODO: check external auth enabled
               //TODO: check sip gateway enabled
               
               room = [elem attributeStringValueForName:@"room"];
               
               // New DNS related changes
               room = [room stringByReplacingOccurrencesOfString:@"xmpp" withString:@"conference"];
               
               [self.signalingDelegate xmppWorker:self didJoinRoom:room];
               
               XMPPIQ *iqResponse = [XMPPIQ iqWithType:@"result" to:[iq from] elementID:[iq elementID]];
               [xmppStream sendElement:iqResponse];
               
               return YES;
           }
       }
        
        NSXMLElement *jireconElem = [iq elementForName:@"recording" xmlns:@"http://jitsi.org/protocol/jirecon"];
        
        if (jireconElem != nil)
        {
            jireconRid = [jireconElem attributeStringValueForName:@"rid"];
            
            XMPPIQ *iqResponse = [XMPPIQ iqWithType:@"result" to:[iq from] elementID:[iq elementID]];
            [xmppStream sendElement:iqResponse];
            
            return YES;
        }
 
    }

    
	return NO;
}

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    XMPPUserCoreDataStorageObject *user = [xmppRosterStorage userForJID:[message from] xmppStream:xmppStream managedObjectContext:[self managedObjectContext_roster]];
    NSString *body = [[message elementForName:@"body"] stringValue];
    NSString *jidStr = [user jidStr];
    DDLogVerbose(@"ReceiveMessage:\n%@\nfrom:%@",body,jidStr);
    
    if ([message isSignalingMessageWithBody]) {
        /*if (self.signalingDelegate && [self.signalingDelegate respondsToSelector:@selector(xmppWorker:didReceiveSignalingMessage:)]) {*/
            [self.signalingDelegate xmppWorker:self didReceiveSignalingMessage:message];
        //}
    }
}

- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence
{
	DDLogVerbose(@"%@: %@ - %@", THIS_FILE, THIS_METHOD, [presence fromStr]);
    
    NSString *myJID = [[xmppStream myJID] full];
    NSLog(@"rtcTargetJid:%@", myJID);    
}

- (void)sendAlive
{
    XMPPPresence *presence = [XMPPPresence presence];
    [[self xmppStream] sendElement:presence];
}

- (void)sendPresenceWithVideoInfo
{
    XMPPPresence *presence = [XMPPPresence presenceWithType:nil to:[XMPPJID jidWithString:room]];
    [presence addChild:[elemPres copy]];
    
    [[self xmppStream] sendElement:presence];
}

- (void)xmppStream:(XMPPStream *)sender didReceiveError:(id)error
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	
	if (!isXmppConnected)
	{
		//EASYLogError(@"Unable to connect to server. Check xmppStream.hostName");
	}
    isXmppConnected = NO;
}

#pragma mark - XMPPRosterDelegate
- (void)xmppRoster:(XMPPRoster *)sender didReceiveBuddyRequest:(XMPPPresence *)presence
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    NSLog(@"xmppRoster :sender:didReceiveBuddyRequest");
	
	XMPPUserCoreDataStorageObject *user = [xmppRosterStorage userForJID:[presence from]
	                                                         xmppStream:xmppStream
	                                               managedObjectContext:[self managedObjectContext_roster]];
	
	NSString *displayName = [user displayName];
	NSString *jidStrBare = [presence fromStr];
	NSString *body = nil;
	
	if (![displayName isEqualToString:jidStrBare])
	{
		body = [NSString stringWithFormat:@"Buddy request from %@ <%@>", displayName, jidStrBare];
	}
	else
	{
		body = [NSString stringWithFormat:@"Buddy request from %@", displayName];
	}
	
	
	if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive)
	{
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:displayName
		                                                    message:body
		                                                   delegate:nil
		                                          cancelButtonTitle:@"Not implemented"
		                                          otherButtonTitles:nil];
		[alertView show];
	}
	else
	{
		// We are not active, so use a local notification instead
		UILocalNotification *localNotification = [[UILocalNotification alloc] init];
		localNotification.alertAction = @"Not implemented";
		localNotification.alertBody = body;
		
		[[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
	}
	
}

// Jicofo/Videobridge related
- (void)allocateConferenceFocus:roomName
{
    // Set focue user jid
    focusUserjid = @"";
    
    // Create conference IQ
    XMPPIQ *iq = [self createConferenceIQ:roomName];
    
    // send IQ
    [xmppStream sendElement:iq];
}

- (XMPPIQ*) createConferenceIQ:roomName
{
    XMPPIQ *xmpp;
    
    NSXMLElement *confElement = [NSXMLElement elementWithName:@"conference"];
    [confElement addAttributeWithName:@"xmlns" stringValue:@"http://jitsi.org/protocol/focus"];
    
    ///***arunkavi
    NSString *fullRoomName = [NSString stringWithFormat:@"%@conference.%@", roomName, [xmppStream.myJID domain]];

    [confElement addAttributeWithName:@"room" stringValue:fullRoomName];
    
    NSXMLElement *bridgeElement = [NSXMLElement elementWithName:@"property"];
    [bridgeElement addAttributeWithName:@"name" stringValue:@"bridge"];
    
    NSMutableString *fullvideobridge = [[NSMutableString alloc]init];
    [fullvideobridge appendString:@"jitsi-videobridge."];
    [fullvideobridge appendString:[xmppStream.myJID domain]];
    [bridgeElement addAttributeWithName:@"value" stringValue:fullvideobridge];
//    [bridgeElement addAttributeWithName:@"value" stringValue:@"jitsi-videobridge.xrtc.me"];
    
    [confElement addChild:bridgeElement];
    
    NSXMLElement *ccElement = [NSXMLElement elementWithName:@"property"];
    [ccElement addAttributeWithName:@"name" stringValue:@"call_control"];
    NSString *dom = [xmppStream.myJID domain];
    dom=[NSString stringWithFormat:@"callcontrol.%@",dom];
    [ccElement addAttributeWithName:@"value" stringValue:dom];
    [confElement addChild:ccElement];
    
    NSXMLElement *chanElement = [NSXMLElement elementWithName:@"property"];
    [chanElement addAttributeWithName:@"name" stringValue:@"channelLastN"];
    [chanElement addAttributeWithName:@"value" stringValue:@"-1"];
    
    [confElement addChild:chanElement];
    
    NSXMLElement *adapElement = [NSXMLElement elementWithName:@"property"];
    [adapElement addAttributeWithName:@"name" stringValue:@"adaptiveLastN"];
    [adapElement addAttributeWithName:@"value" stringValue:@"false"];
    
    [confElement addChild:adapElement];
    
    NSXMLElement *simuElement = [NSXMLElement elementWithName:@"property"];
    [simuElement addAttributeWithName:@"name" stringValue:@"adaptiveSimulcast"];
    [simuElement addAttributeWithName:@"value" stringValue:@"false"];
    
    [confElement addChild:simuElement];
    
    NSXMLElement *osctpElement = [NSXMLElement elementWithName:@"property"];
    [osctpElement addAttributeWithName:@"name" stringValue:@"openSctp"];
    [osctpElement addAttributeWithName:@"value" stringValue:@"true"];
    
    [confElement addChild:osctpElement];
    
    NSXMLElement *firefoxElement = [NSXMLElement elementWithName:@"property"];
    [firefoxElement addAttributeWithName:@"name" stringValue:@"enableFirefoxHacks"];
    [firefoxElement addAttributeWithName:@"value" stringValue:@"false"];
    
    [confElement addChild:firefoxElement];
    
    NSString *fullTargetJid = [xmppStream.myJID domain];

    fullTargetJid=[NSString stringWithFormat:@"focus.%@",fullTargetJid];
    
    XMPPJID *targetJid = [XMPPJID jidWithString:fullTargetJid];
    
    xmpp  = [[XMPPIQ alloc]initWithType:@"set" to:targetJid elementID:nil child:[confElement copy]];
    
    return xmpp;
    
}

//PSTN dialing

- (void) dial:(NSString*)to from:(NSString*)from
{
    XMPPIQ *iq = [XMPPRayo dial:to from:from roomName:room roomPass:@"" target:[xmppStream.myJID domain]];
    
    // send IQ
    [xmppStream sendElement:iq];
  
}

- (void)hangup
{
    XMPPIQ *iq = [XMPPRayo hangup];
    
    // send IQ
    [xmppStream sendElement:iq];
}


// Recording

- (void)record:(NSString*)state
{
    XMPPIQ *iq;
    
    iq = [self setRecordingJirecon:state tok:nil target:nil];
    
    // send IQ
    [xmppStream sendElement:iq];    
}

- (XMPPIQ*)setRecordingJirecon:(NSString*)state tok:(NSString*)token target:(NSString*)target
{
    XMPPIQ *xmpp;
    
    NSXMLElement *recElement = [NSXMLElement elementWithName:@"recording"];
    [recElement addAttributeWithName:@"xmlns" stringValue:@"http://jitsi.org/protocol/jirecon"];
    [recElement addAttributeWithName:@"action" stringValue:state];
    [recElement addAttributeWithName:@"mucjid" stringValue:room];
    if ([state isEqual:@"stop"])
    {
        [recElement addAttributeWithName:@"rid" stringValue:jireconRid];
    }
    else
    {
        jireconRid = @"";
    }

    
  
    NSString *focusmucjid = [xmppStream.myJID domain];
    focusmucjid=[NSString stringWithFormat:@"jirecon.%@",focusmucjid];
    
    XMPPJID *targetJid = [XMPPJID jidWithString:focusmucjid];
    
    xmpp  = [[XMPPIQ alloc]initWithType:@"set" to:targetJid elementID:nil child:[recElement copy]];
    
    return xmpp;

}

- (XMPPIQ*)setRecordingColibri:(NSString*)state tok:(NSString*)token target:(NSString*)target
{
    XMPPIQ *xmpp;
    
    NSXMLElement *conElement = [NSXMLElement elementWithName:@"conference"];
    [conElement addAttributeWithName:@"xmlns" stringValue:@"http://jitsi.org/protocol/colibri"];
    
    
    NSXMLElement *recElement = [NSXMLElement elementWithName:@"recording"];
    [recElement addAttributeWithName:@"state" stringValue:state];
    [recElement addAttributeWithName:@"token" stringValue:token];
    
    [conElement addChild:recElement];
    
    NSString *focusmucjid = target;
    focusmucjid=[NSString stringWithFormat:@"colibri.%@",focusmucjid];
    
    XMPPJID *targetJid = [XMPPJID jidWithString:focusmucjid];
    
    xmpp  = [[XMPPIQ alloc]initWithType:@"set" to:targetJid elementID:nil child:[conElement copy]];
    
    return xmpp; 
}

@end
