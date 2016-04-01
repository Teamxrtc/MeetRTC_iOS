//
//  WebRTCStack.m
//  meet-webrtc-sdk
//
//  Created by Pankaj on 26/08/14.
//  Copyright 2014 Comcast Cable Communications Management, LLC.
//
#import "WebRTCSession.h"
#import "WebRTCStack.h"
#import "WebRTCError.h"
#import <UIKit/UIKit.h>
#import "WebRTCJSON.h"
#import <sys/utsname.h>
#import "XMPPWorker.h"
#import "WebRTCLogHandler.h"
#import "WebRTCLogging.h"
#import <arpa/inet.h>
#import <CFNetwork/CFNetwork.h>
#import <netinet/in.h>
#import <netdb.h>
#import <ifaddrs.h>
#import <arpa/inet.h>
#import <net/ethernet.h>
#import <net/if_dl.h>

NSString* const Stack     = @"Stack";
NSString* const Socket = @"Socket";

#define ICE_SERVER_TIMEOUT 3
#define RECONNET_TRY_TIMEOUT 3

#define LIBSDK_VERSION "0.3.7" // Need to find a better way of doing this.

@interface WebRTCSession() <XMPPDelegate>

@end

@interface WebRTCStack()

//xmpp
@property(nonatomic ) NSString* roomID;
@property(nonatomic ) WebRTCSession* session;
@property(nonatomic ) BOOL isIncomingCall;@end


@implementation WebRTCStack

NSString* const TAG5 = @"WebRTCStack";

@synthesize networkType = _networkType;

- (id)initWithRTCG:(WebRTCStackConfig*)_stackConfig _appdelegate:(id<WebRTCStackDelegate>)_appdelegate
{
    if((!_stackConfig.serverURL) )
    {
        //TODO Need to return object type instead of enum
        //return ERR_INCORRECT_PARAMS;
        return nil;
    }
    
//Url Validation
//    else
//    {
//        NSURL *testURL = [NSURL URLWithString:_stackConfig.serverURL];
//
//        // Check if the URL is valid
//        if (!testURL || !testURL.scheme || !testURL.host) {
//            LogDebug(@"initWithRTCG incorrect URL %@", _stackConfig.serverURL);
//            return nil;
//        }
//    }
    
    self = [super init];
    if (self!=nil) {
        stackConfig = _stackConfig;
        _roomID = nil;
        _isIncomingCall = false;
        NSMutableDictionary* metaData = [self getMetaData];
        LogDebug(@"MetaData is = %@",metaData);
            NSLog(@"WebRTCStack::initWithRTCG for XMPP");
            isChannelAPIEnable = false;
            isXMPPEnable = true;
            _isVideoBridgeEnable = false;
            self.delegate = (id<WebRTCStackDelegate>)_appdelegate;
            
            isReconnecting = false;
            _isCapabilityExchangeEnable = false;
            isNetworkAvailable = true;
            isNetworkStateUpdated = false;
            _reconnectTimeoutTimer = nil;

        if(_stackConfig.isNwSwitchEnable)
        {
            // Set up Reachability
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(reachabilityChanged:)
                                                         name:kReachabilityChangedNotification object:nil];
            
            reachability = [Reachability reachabilityForInternetConnection];
            [reachability startNotifier];
            oldStatus = [reachability currentReachabilityStatus];
            
            if (reachability.currentReachabilityStatus == ReachableViaWiFi){
                isWifiMode = true;
                isWifiModePrev = false;
            }
            else{
                isWifiMode = false;
                isWifiModePrev = true;
            }

        }
    }

    LogDebug(@"Stack being initialised with version %s",LIBSDK_VERSION );

    return self;
}

- (void) startSignalingServer:(NSDictionary*) websocketdata iceserverdata:(NSDictionary*)iceserverdata;
{
    LogDebug(@"Inside startSignalingServer ");
    
    if ((websocketdata == nil) || (iceserverdata == nil))
        return;
    NSString* credential = [websocketdata objectForKey:@"credential"];
    //@"T7R^6;@Z$$2TYzI+/!*'();:@&=+$,/?%#[]&mKU5uU=";//
    username = [websocketdata objectForKey:@"username"];
    NSArray* uris = [websocketdata objectForKey:@"uris"];
    
    NSURL *validURL = [NSURL URLWithString: [uris objectAtIndex:0]];
    path = [validURL path];
    
    encodedcredential =(NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                            NULL,
                                            (CFStringRef)credential,
                                            NULL,
                                            //(CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                            (CFStringRef)@"+&",
                                            kCFStringEncodingUTF8 ));

    BOOL secure = false;
    // Check if the URL has https
    if([[validURL scheme] isEqual:@"https"])
    {
        secure = true;
    }
    if(!isReconnecting)
    [self onStateChange:SocketConnecting];

    NSString *hostURL;

    if (stackConfig.doManualDns)
    {
        NSArray *addresses = [self getAddresses:[validURL host]];
        NSLog(@"DNS Result %@", [addresses description]);
        if ([addresses count] > 0)
        {
            for (int i =0; i <[addresses count]; i++)
            {
                if ([[addresses[i] componentsSeparatedByString:@":"] count] > 3) // IPv6 address
                {
                    // Prefer IPv4 if both are present
                    if ([addresses count] > 1)
                    {
                        continue;
                    }
                    else
                    {
                        hostURL = addresses[i];
                    }
                }
                else
                {
                    hostURL = addresses[i];
                }
            }
        }
        else
        {
            hostURL = [validURL host];
        }
    }
    else
    {
        hostURL = [validURL host];
    }
    LogDebug(@"Host name is %@ ", hostURL);

    iceservermsg = iceserverdata;

}

- (NSArray *)getAddresses:(NSString *)url {
        CFHostRef hostRef = CFHostCreateWithName(kCFAllocatorDefault, (__bridge CFStringRef)url);
        
        BOOL success = CFHostStartInfoResolution(hostRef, kCFHostAddresses, nil);
        if (!success) {
            // something went wrong
            return nil;
        }
        CFArrayRef addressesRef = CFHostGetAddressing(hostRef, nil);
        if (addressesRef == nil) {
            // couldn't found any address
            return nil;
        }
        
        // Convert these addresses into strings.
        char ipAddress[INET6_ADDRSTRLEN];
        NSMutableArray *addresses = [NSMutableArray array];
        CFIndex numAddresses = CFArrayGetCount(addressesRef);
        for (CFIndex currentIndex = 0; currentIndex < numAddresses; currentIndex++) {
            CFDataRef dataRef = (CFDataRef)CFArrayGetValueAtIndex(addressesRef, currentIndex);
            struct sockaddr *address = (struct sockaddr *)CFDataGetBytePtr(dataRef);
            if (address == nil) {
                return nil;
            }
            getnameinfo(address, address->sa_len, ipAddress, INET6_ADDRSTRLEN, nil, 0, NI_NUMERICHOST);
            if (ipAddress == nil) {
                return nil;
            }
            NSString * addressString = [NSString stringWithCString:ipAddress encoding:NSASCIIStringEncoding];
            if ([[addressString componentsSeparatedByString:@":"] count] > 3) // IPv6 address
            {
                addressString = [NSString stringWithFormat:@"[%@]", addressString];
            }
            [addresses addObject:addressString];
        }
        
        return addresses;
}


- (void) setVideoBridgeEnable: (bool) flag
{
    _isVideoBridgeEnable = flag;
    [XMPPWorker sharedInstance].isVideoBridgeEnable = flag;
}


-(NSMutableDictionary*)getMetaData
{
    
    /*NSString* name = [[UIDevice currentDevice] name];
    NSString* systemName =  [[UIDevice currentDevice] systemName];
    NSString* systemVersion = [[UIDevice currentDevice] systemVersion];
    NSString* model =  [[UIDevice currentDevice] model];*/
    NSString* NetConType = [self getNetworkConnectionType ];
    NSMutableDictionary* metadata = [[NSMutableDictionary alloc]init];
    //SString *uniqueIdentifier = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    NSString* sdkVersion = [UIDevice currentDevice].systemVersion;
    //[metadata setValue:name forKey:@"name"];
   // [metadata setValue:systemName forKey:@"systemName"];
   // [metadata setValue:systemVersion forKey:@"systemVersion"];
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *result = [NSString stringWithCString:systemInfo.machine
                                          encoding:NSUTF8StringEncoding];
    NSString* model = [self platformType:result];
    
#ifdef LIBSDK_VERSION
    [metadata setValue:@LIBSDK_VERSION forKey:@"sdkVersion"];
#endif
    [metadata setValue:model forKey:@"model"];
    [metadata setValue:@"Apple" forKey:@"manufacturer"];
    [metadata setValue:NetConType forKey:@"NetworkType"];
    [metadata setValue:sdkVersion forKey:@"iOSSDKVersion"];
    
    NSBundle *bundle = [NSBundle mainBundle];
    NSDictionary *info = [bundle infoDictionary];
    NSString *prodName = [info objectForKey:@"CFBundleDisplayName"];
    [metadata setValue:prodName forKey:@"packageName"];
    //[metadata setValue:prodName forKey:@"alias"];
    return metadata;

}


- (NSString *) platformType:(NSString *)platform
{
    if ([platform isEqualToString:@"iPhone1,1"])    return @"iPhone 1G";
    if ([platform isEqualToString:@"iPhone1,2"])    return @"iPhone 3G";
    if ([platform isEqualToString:@"iPhone2,1"])    return @"iPhone 3GS";
    if ([platform isEqualToString:@"iPhone3,1"])    return @"iPhone 4";
    if ([platform isEqualToString:@"iPhone3,3"])    return @"Verizon iPhone 4";
    if ([platform isEqualToString:@"iPhone4,1"])    return @"iPhone 4S";
    if ([platform isEqualToString:@"iPhone5,1"])    return @"iPhone 5 (GSM)";
    if ([platform isEqualToString:@"iPhone5,2"])    return @"iPhone 5 (GSM+CDMA)";
    if ([platform isEqualToString:@"iPhone5,3"])    return @"iPhone 5c (GSM)";
    if ([platform isEqualToString:@"iPhone5,4"])    return @"iPhone 5c (GSM+CDMA)";
    if ([platform isEqualToString:@"iPhone6,1"])    return @"iPhone 5s (GSM)";
    if ([platform isEqualToString:@"iPhone6,2"])    return @"iPhone 5s (GSM+CDMA)";
    if ([platform isEqualToString:@"iPhone7,2"])    return @"iPhone 6";
    if ([platform isEqualToString:@"iPhone7,1"])    return @"iPhone 6 Plus";
    if ([platform isEqualToString:@"iPod1,1"])      return @"iPod Touch 1G";
    if ([platform isEqualToString:@"iPod2,1"])      return @"iPod Touch 2G";
    if ([platform isEqualToString:@"iPod3,1"])      return @"iPod Touch 3G";
    if ([platform isEqualToString:@"iPod4,1"])      return @"iPod Touch 4G";
    if ([platform isEqualToString:@"iPod5,1"])      return @"iPod Touch 5G";
    if ([platform isEqualToString:@"iPad1,1"])      return @"iPad";
    if ([platform isEqualToString:@"iPad2,1"])      return @"iPad 2 (WiFi)";
    if ([platform isEqualToString:@"iPad2,2"])      return @"iPad 2 (GSM)";
    if ([platform isEqualToString:@"iPad2,3"])      return @"iPad 2 (CDMA)";
    if ([platform isEqualToString:@"iPad2,4"])      return @"iPad 2 (WiFi)";
    if ([platform isEqualToString:@"iPad2,5"])      return @"iPad Mini (WiFi)";
    if ([platform isEqualToString:@"iPad2,6"])      return @"iPad Mini (GSM)";
    if ([platform isEqualToString:@"iPad2,7"])      return @"iPad Mini (GSM+CDMA)";
    if ([platform isEqualToString:@"iPad3,1"])      return @"iPad 3 (WiFi)";
    if ([platform isEqualToString:@"iPad3,2"])      return @"iPad 3 (GSM+CDMA)";
    if ([platform isEqualToString:@"iPad3,3"])      return @"iPad 3 (GSM)";
    if ([platform isEqualToString:@"iPad3,4"])      return @"iPad 4 (WiFi)";
    if ([platform isEqualToString:@"iPad3,5"])      return @"iPad 4 (GSM)";
    if ([platform isEqualToString:@"iPad3,6"])      return @"iPad 4 (GSM+CDMA)";
    if ([platform isEqualToString:@"iPad4,1"])      return @"iPad Air (WiFi)";
    if ([platform isEqualToString:@"iPad4,2"])      return @"iPad Air (Cellular)";
    if ([platform isEqualToString:@"iPad4,3"])      return @"iPad Air";
    if ([platform isEqualToString:@"iPad4,4"])      return @"iPad Mini 2G (WiFi)";
    if ([platform isEqualToString:@"iPad4,5"])      return @"iPad Mini 2G (Cellular)";
    if ([platform isEqualToString:@"iPad4,6"])      return @"iPad Mini 2G";
    if ([platform isEqualToString:@"i386"])         return @"Simulator";
    if ([platform isEqualToString:@"x86_64"])       return @"Simulator";
    return platform;
}


-(NSString*)getNetworkConnectionType
{
    NSArray *subviews = [[[[UIApplication sharedApplication] valueForKey:@"statusBar"] valueForKey:@"foregroundView"]subviews];
    NSNumber *dataNetworkItemView = nil;
    
    for (id subview in subviews) {
        if([subview isKindOfClass:[NSClassFromString(@"UIStatusBarDataNetworkItemView") class]]) {
            dataNetworkItemView = subview;
            break;
        }
    }
    NSString* type;
    
    switch ([[dataNetworkItemView valueForKey:@"dataNetworkType"]integerValue]) {
        case 0:
           type=@"No Wifi/Cellular connection";
            _networkType = nonetwork;
            break;
            
        case 1:
            type=@"2G";
            _networkType = cellular2g;
            break;
            
        case 2:
            type=@"3G";
             _networkType = cellular3g;
            break;
            
        case 3:
            type=@"4G";
            _networkType = cellular4g;
            break;
            
        case 4:
            type=@"LTE";
            _networkType =  cellularLTE;
            break;
            
        case 5:
            type=@"Wifi";
            _networkType = wifi;
            break;
            
        default:
            type=@"Not found !!";
            break;
    }
    return type;
}


- (id)createStream:(WebRTCStreamConfig*)_streamConfig _recordingDelegate:(id<WebRTCSessionDelegate>)appDelegate
{
    WebRTCStream *_stream;
    
    if([self isStreamVideoEnable])
        _stream = [[WebRTCStream alloc]initWithDefaultValue:_streamConfig];
    else
    _stream = [[WebRTCStream alloc]init];

    _stream.delegate = self;
    _stream.recordingDelegate = (id<WebRTCAVRecordingDelegate>)appDelegate;
    [_stream start];
    return _stream;
}

- (id)createAudioOnlyStream
{
    WebRTCStream *_stream;
    
    if([self isStreamVideoEnable])
        _stream = [[WebRTCStream alloc]initWithDefaultValue];
    else
        _stream = [[WebRTCStream alloc]init];
    
    _stream.delegate = self;
    [_stream start];
    return _stream;
}


- (WebRTCSession *)createSession:(WebRTCStream *)_stream _appdelegate:(id<WebRTCSessionDelegate>)_appdelegate _configParam:(WebRTCSessionConfig *)_sessionConfig
{
    _isIncomingCall = false;
    if (clientSessionId == NULL) {
        clientSessionId = [[NSUUID UUID] UUIDString];
    }
    LogDebug(@"ClientSessionId befor session start:: %@",clientSessionId);
        _session = [[WebRTCSession alloc] initWithXMPPValue:self  _configParam:_sessionConfig _stream:_stream _appdelegate:_appdelegate _statcollector:statsCollector];
        sessions = @{clientSessionId: _session};
    
    //***arunkavi
    //use created room
    NSString *finalRoom=[[NSString alloc]initWithFormat:@"%@@%@",_sessionConfig.rtcgSessionId,stackConfig.serverURL];
    [self createXMPPConnection :finalRoom:_sessionConfig.isSecured];

    //For Incoming Call
    if (offerMsg != NULL) {
        [_session onSignalingMessage:offerMsg];
    }
    
    // Write alias
    //[statsCollector writeMeta:@"alias" _values:_sessionConfig.callerID];
    return _session;
}

- (id)createIncomingSession:(WebRTCStream *)_stream _appdelegate:(id<WebRTCSessionDelegate>)_appdelegate _configParam:(WebRTCSessionConfig *)_sessionConfig
{
    NSLog(@"Webrtc:Session:: ClientSessionId befor session start:: %@  %@",clientSessionId,[sessions objectForKey:clientSessionId]);
    if (clientSessionId == NULL) {
        clientSessionId = [[NSUUID UUID] UUIDString];
    }
    
    _session = [[WebRTCSession alloc] initWithIncomingSession:self arClientSessionId:clientSessionId  _stream:_stream _appdelegate:_appdelegate channelapi:isChannelAPIEnable _statcollector:statsCollector _configParam:_sessionConfig];
    sessions = @{clientSessionId: _session};

    [_session setXMPPEnable:true];
    //***arunkavi
    //use created room
    [self createXMPPConnection: _sessionConfig.rtcgSessionId : _sessionConfig.isSecured];
    
    return _session;
}

- (WebRTCSession *)createDataSession:(id<WebRTCSessionDelegate>)_appdelegate _configParam:(WebRTCSessionConfig *)_sessionConfig
{
    
    WebRTCSession* session = nil;
    if (clientSessionId == NULL) {
        clientSessionId = [[NSUUID UUID] UUIDString];
    }
    
    _dataFlag = true;
    LogDebug(@"ClientSessionId befor session start:: %@",clientSessionId);
    

        session = [[WebRTCSession alloc] initWithDefaultValue:self arClientSessionId:clientSessionId _configParam:_sessionConfig _stream:nil _appdelegate:_appdelegate _statcollector:statsCollector];
        sessions = @{clientSessionId: session};
        [session setDTLSFlag:true];
        [session start];

    
    //For Incoming Call
    if (offerMsg != NULL) {
        [session onSignalingMessage:offerMsg];
    }
    
    // Write alias
    //[statsCollector writeMeta:@"alias" _values:_sessionConfig.callerID];
    return session;
}

- (void) createXMPPConnection:(NSString*)roomname :(BOOL)secured
{
    NSArray *lines = [roomname componentsSeparatedByString: @"@"];
    _roomID = lines[0];
    NSString* websocketURL = lines[1];
    //Initializing room id
    if(!_isIncomingCall)
    [_session setRoomId:_roomID];
    
    NSLog(@"WebRTCStack::websocketURL = %@",websocketURL);
    
    [[XMPPWorker sharedInstance] startEngine];
    [[XMPPWorker sharedInstance] setXMPPDelegate:self];
    [[XMPPWorker sharedInstance] setHostName:websocketURL];
    [[XMPPWorker sharedInstance] setHostPort:stackConfig.portNumber];
    [[XMPPWorker sharedInstance] setUserName:roomname];
    [[XMPPWorker sharedInstance] setIsSecuredConnect:secured];
    [[XMPPWorker sharedInstance] setUserPwd:@""];
    [[XMPPWorker sharedInstance] connect];
    //[[XMPPWorker sharedInstance] fetchedResultsController_roster];
    NSLog(@"XMPP, setting the credentials hostname %@ port %ld username %@",
          stackConfig.serverURL,
          (long)stackConfig.portNumber,
          roomname);
}
- (void)onRTCServerMessage:(NSString*)msg
{
    LogDebug(@" onRTCServerMessage");
    
    NSString *type=NULL;
    NSString *clientSessionIdTmp;
    //Parse into JSON object
    NSError *error = nil;
    NSDictionary *messageJSON = [WebRTCJSONSerialization
                                 JSONObjectWithData:[msg dataUsingEncoding:NSUTF8StringEncoding]
                                 options:0 error:&error];
    
    // Check for errors
    NSAssert(!error, @"%@", [NSString stringWithFormat:@"Error handling message: %@", error.description]);
    
    NSAssert([messageJSON count] > 0, @"Invalid JSON object");
  
    
    // Get message type

   if ([messageJSON objectForKey:@"args"]) {
       
       NSArray * args = [messageJSON objectForKey:@"args"];
       NSDictionary * objects = args[0];
       NSString * objects1 = args[0];
       LogInfo(@"Args %@",objects1 );
       if (objects1 == [NSNull null])
             return;
       
       NSData* jsonData = [WebRTCJSONSerialization dataWithJSONObject:objects
                                                          options:0 error:nil];
       NSString *JSONString = [[NSString alloc] initWithBytes:[jsonData bytes] length:[jsonData length] encoding:NSUTF8StringEncoding];
       [statsCollector storeCallLogMessage:objects1 _msgType:@"serverRTC"];
       
       type = [objects objectForKey:@"type"];
       clientSessionIdTmp = [objects objectForKey:@"clientSessionId"];
       from = [objects objectForKey:@"to"];
       to = [objects objectForKey:@"from"];
       LogDebug(@"clientSessionId:: %@",clientSessionId);
       

           if ([sessions objectForKey:clientSessionIdTmp])
           {
               LogDebug(@"Webrtc:Session:: RTC server message has clientsessionId");
               WebRTCSession *session = (WebRTCSession*) [sessions objectForKey:clientSessionIdTmp];
               [session onSignalingMessage:objects];
           }
           else if (![type compare:@"offer"])
           {
               LogDebug(@"Webrtc:Session:: RTC message is of type OFFER");
               clientSessionId = clientSessionIdTmp;
               offerMsg = objects;
               
               [self.delegate onOffer:from to:to];
               //[sessions setValue:session forKey:clientSessionId]; //does not work need to fix for incoming call
               //[session onSignalingMessage:msg];
           }
           else
           {
               LogDebug(@"Webrtc:Session:: Unknown client SessionId dropping message");
               NSError *error = [NSError errorWithDomain:Stack
                                                    code:ERR_UNKNOWN_CLIENT
                                                userInfo:nil];
               [self onStackError:error.description errorCode:error.code];
           }

    }
    
}


- (void)onRegMessage:(NSString*)msg
{
    LogDebug(@"Webrtc:Session:: onRegMessage");
    [statsCollector storeCallLogMessage:msg _msgType:@"serverReg"];
    
    NSString *type;
    //Parse into JSON object
    NSError *error = nil;
    NSDictionary *messageJSON = [WebRTCJSONSerialization
                                 JSONObjectWithData:[msg dataUsingEncoding:NSUTF8StringEncoding]
                                 options:0 error:&error];
    
    // Check for errors
    NSAssert(!error, @"%@", [NSString stringWithFormat:@"Error handling message: %@", error.description]);
    
    NSAssert([messageJSON count] > 0, @"Invalid JSON object");
    
    
    // Get message type
    NSArray * args = [messageJSON objectForKey:@"args"];
    NSDictionary * objects = args[0];
    type = [objects objectForKey:@"type"];
    
    if(![type compare:@"regfailure"])
    {
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"Registration Failed !!!" forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:Session code:ERR_REG_FAILURE userInfo:details];
        [self onStackError:error.description errorCode:error.code];
    }
    else
    {
        [self.delegate onRegister];
    }
    
}

- (void)onAuthMessage:(NSString*)msg
{
    LogDebug(@"Webrtc:Session:: onAuthMessage");
    [statsCollector storeCallLogMessage:msg _msgType:@"serverAuth"];
}

- (void)sendRTCMessage:(id)msg
{
    LogDebug(@"Webrtc:Session:: sendRTCMessage");
   //  LogDebug(@"type == %@", [msg valueForKey:@"type"]);
    NSData* jsonData = [WebRTCJSONSerialization dataWithJSONObject:msg
                                                       options:0 error:nil];
    NSString *JSONString = [[NSString alloc] initWithBytes:[jsonData bytes] length:[jsonData length] encoding:NSUTF8StringEncoding];

    //[statsCollector storeCallLogMessage:JSONString _msgType:@"clientRTC"];
    [statsCollector storeCallLogMessage:msg _msgType:@"clientRTC"];
    
}

- (void)disconnect
{
    LogDebug(@"WebRTCStack->disconnect");
   
    httpconn.delegate = nil;
   
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // Teardown XMPP
    [[XMPPWorker sharedInstance] stopEngine];
}

- (void)rejectCall
{
    NSData *data = [@"{\"type\" : \"bye\"}" dataUsingEncoding:NSUTF8StringEncoding];
    NSError* error;
    NSDictionary* json =[WebRTCJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    
    NSMutableDictionary* jsonm = [NSMutableDictionary dictionaryWithDictionary:json];
    
    [jsonm setValue:to forKey:@"target"];
    [jsonm setValue:from forKey:@"from"];
    [jsonm setValue:@"PBA" forKey:@"appId"];
    [jsonm setValue:from forKey:@"uid"];
    [jsonm setValue:@"default" forKey:@"applicationContext"];
    [jsonm setValue:clientSessionId forKey:@"clientSessionId"];
    
    [self sendRTCMessage:jsonm];
    
    
}

- (void)sendRegMessage:(id)msg
{
    LogDebug(@"Webrtc:Session:: sendRegMessage");
    [statsCollector storeCallLogMessage:msg _msgType:@"clientReg"];
    
}

- (void)registerOnServer
{
    LogDebug(@"registerOnServer");
    NSDictionary *tempMsg = @{ @"uid" : emailId, @"address" : emailId, @"Authorization" : @"Bearer ExampleKey"};
    NSError *jsonError = nil;
    NSData *msg = [WebRTCJSONSerialization dataWithJSONObject:tempMsg options:0 error:&jsonError];
    
    NSError* error;
    NSDictionary* json =[WebRTCJSONSerialization JSONObjectWithData:msg options:kNilOptions error:&error];
    
    NSMutableDictionary* jsonm = [NSMutableDictionary dictionaryWithDictionary:json];
    
    
    // Sending registration request
    LogDebug(@"Webrtc:Session:: Sending registration message");
    [self sendRegMessage:jsonm];
    
    NSTimer *_regtimer;
    _regtimer = [NSTimer scheduledTimerWithTimeInterval:ICE_SERVER_TIMEOUT
                                                 target:self
                                               selector:@selector(_timerCallback:)
                                               userInfo:nil
                                                repeats:NO
                 ];
    
    
}

- (void)_timerCallback:(NSTimer *)timer{
    
    LogDebug(@" _timerCallback");
    
    NSDictionary *tempMsg = @{ @"uid" : emailId, @"address" : emailId, @"Authorization" : @"Bearer ExampleKey"};
    NSError *jsonError = nil;
    NSData *msg = [WebRTCJSONSerialization dataWithJSONObject:tempMsg options:0 error:&jsonError];
    
    NSError* error;
    NSDictionary* json =[WebRTCJSONSerialization JSONObjectWithData:msg options:kNilOptions error:&error];
    
    NSMutableDictionary* jsonm = [NSMutableDictionary dictionaryWithDictionary:json];
    
    
    // Sending registration request
    LogDebug(@"Webrtc:Session:: Sending registration message");
    [self sendRegMessage:jsonm];
    
}

#pragma mark - XMPPDelegate methods
- (void) onReady:(NSArray*) alias
{
    NSLog(@"XMPP Stack : State is Connected :: alias %@", alias.description);
    
    if(stackConfig.usingRTC20)
    [_session start:iceservermsg];
    else
    [self.delegate onReady:alias];
}




- (void)_reconnectCallback
{

}
    





-(void) onStateChange:(NetworkState)state
{
    nwState = state;
    [self.delegate onStateChange:state];
}

#pragma mark - Sample WebRTCStreamDelegate delegate
- (void)OnLocalStream:(RTCVideoTrack *)videoTrack;
{
    LogDebug(@"OnLocalStream");
    [self.delegate startLocalDisplay:videoTrack];
}

- (void) onStreamError:(NSString *)error errorCode:(NSInteger)code
{
    LogError(@"On Error from stream");
    [self onStackError:error errorCode:code];
}

-(BOOL)isStreamVideoEnable
{
   return true;
}

- (void) onIceServer:(NSDictionary*) msg
{
    //TODO
}

- (void) onHTTPError:(NSString*)error errorCode:(NSInteger)code
{
   [self onStackError:error errorCode:code];
}

-(void)onStackError:(NSString*)error errorCode:(NSInteger)code
{
    switch (code) {
        case ERR_NO_WEBSOCKET_SUPPORT:
            [statsCollector storeError:@"unable to connect"];
            break;
            
        case ERR_WEBSOCKET_DISCONNECT:
            [statsCollector storeError:@"Server Disconnected"];
            break;
        
        case ERR_INCORRECT_STATE:
            [statsCollector storeError:@"Incorrect State"];
            break;
            
        case ERR_INVALID_CONSTRAINTS:
            [statsCollector storeError:@"Invalid Constraints Given"];
            break;
            
        case ERR_CAMERA_NOT_FOUND:
            [statsCollector storeError:@"Camera Error"];
            break;
            
        default:
            [statsCollector storeError:@"Unknown Error"];
            break;
    }
    [self.delegate onStackError:error errorCode:code];
}

- (int) getMachineID
{
    struct utsname systemInfo;
    uname(&systemInfo);
    
    NSString *device = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    
    LogDebug(@"getMachineID = %@",device);
    
    int deviceSeries;
    
    if([device isEqualToString:@"iPhone3,1"] || [device isEqualToString:@"iPhone3,2"] || [device isEqualToString:@"iPhone3,3"] ||
            [device isEqualToString:@"iPhone4,1"])
    {
        deviceSeries =  iPhone4;
    }
    else if([device isEqualToString:@"iPhone5,1"] || [device isEqualToString:@"iPhone5,2"] || [device isEqualToString:@"iPhone5,3"] ||
            [device isEqualToString:@"iPhone5,4"] || [device isEqualToString:@"iPhone6,1"] || [device isEqualToString:@"iPhone6,2"])
    {
        deviceSeries = iPhone5;
    }
    else if([device isEqualToString:@"iPhone7,2"] || [device isEqualToString:@"iPhone7,1"])
    {
        deviceSeries = iPhone6;
    }
    
    return deviceSeries;
}

- (void)reconnectTimeout
{
    if (nwState == SocketDisconnect)
    {
        LogInfo(@"Network Reconnect Wait Time is Over !!!!");
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"websocket connection has been closed by the gateway/server" forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:Socket code:ERR_WEBSOCKET_DISCONNECT userInfo:details];
        [self onStackError:error.description errorCode:error.code];
        [self onStateChange:Disconnected];
        isReconnecting = false;
    }
}

- (void)reachabilityChanged:(NSNotification*)notification
{
    
    if(reachability.currentReachabilityStatus == NotReachable && oldStatus !=  reachability.currentReachabilityStatus)
    {
        LogInfo(@"Internet off");
        isNetworkAvailable = false;
        isNetworkStateUpdated = true;
        oldStatus = reachability.currentReachabilityStatus;
        
        _reconnectTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:RECONNET_TRY_TIMEOUT
                                                       target:self
                                                     selector:@selector(reconnectTimeout)
                                                     userInfo:nil
                                                      repeats:NO
                       ];

    }
    else if(oldStatus != reachability.currentReachabilityStatus)
    {
        LogInfo(@"Internet on");
        isNetworkAvailable = true;
        isNetworkStateUpdated = true;
        oldStatus = reachability.currentReachabilityStatus;
        
        isWifiModePrev = isWifiMode;
        if (reachability.currentReachabilityStatus == ReachableViaWiFi){
            isWifiMode = true;
        }
        else{
            isWifiMode = false;
        }
        [self initiateReconnect];
    }
}

- (void) initiateReconnect
{
    if (_reconnectTimeoutTimer != nil) {
        [_reconnectTimeoutTimer invalidate];
    }
    
    [self _reconnectCallback];
}

-(void)sendpreferredH264:(BOOL)preferH264{
#ifdef __IPHONE_8_0
//    [RTCPeerConnectionFactory OnSetH264:preferH264]; //v47 changes
#else
    NSLog(@"Call on iOS version less than iOS 8 will run on VP8 only !!!");
#endif
}

-(void) dial:(NSString*)toPhone from:(NSString*)fromPhone
{
    [[XMPPWorker sharedInstance] dial:toPhone from:fromPhone];
}

-(void) hangup
{
    [[XMPPWorker sharedInstance] hangup];
}

-(void) record:(NSString*)state
{
    [[XMPPWorker sharedInstance] record:state];
}

-(void) addAudioRouteNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(audioSessionRouteChanged:)
                                                 name:AVAudioSessionRouteChangeNotification
                                               object:nil];
}
-(int) switchMic: (BOOL)builtin
{
    NSError* theError = nil;
    BOOL result = YES;
    
    AVAudioSession* inAudioSession = [AVAudioSession sharedInstance];
    
    result = [inAudioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:&theError];
    if (!result)
    {
        NSLog(@"switchMic::setCategory failed");
    }
    
    result = [inAudioSession setActive:YES error:&theError];
    if (!result)
    {
        NSLog(@"V::setActive failed");
    }
    
    // Get the set of available inputs. If there are no audio accessories attached, there will be
    // only one available input -- the built in microphone.
    NSArray* inputs = [inAudioSession availableInputs];
    
    
    // Locate the Port corresponding to the built-in microphone.
    AVAudioSessionPortDescription* micPort = nil;
    if(builtin)
    {
        for (AVAudioSessionPortDescription* port in inputs)
        {
            if ([port.portType isEqualToString:AVAudioSessionPortBuiltInMic])
            {
                micPort = port;
                break;
            }
        }
    }
    else
    {
        for (AVAudioSessionPortDescription* port in inputs)
        {
            if ([port.portType isEqualToString:AVAudioSessionPortHeadsetMic])
            {
                micPort = port;
                break;
            }
        }
        
        if(micPort == nil)
            return 0;
        
    }
    
    NSLog(@"There are %u data sources for port :\"%@\"", (unsigned)[micPort.dataSources count], micPort);
    NSLog(@"%@", micPort.dataSources);
    
    // loop over the built-in mic's data sources and attempt to locate the front microphone
    AVAudioSessionDataSourceDescription* frontDataSource = nil;
    for (AVAudioSessionDataSourceDescription* source in micPort.dataSources)
    {
        if ([source.orientation isEqual:AVAudioSessionOrientationFront])
        {
            frontDataSource = source;
            break;
        }
    }
    
    if (frontDataSource)
    {
        NSLog(@"Currently selected source is \"%@\" for port \"%@\"", micPort.selectedDataSource.dataSourceName, micPort.portName);
        NSLog(@"Attempting to select source \"%@\" on port \"%@\"", frontDataSource, micPort.portName);
        
        // Set a preference for the front data source.
        theError = nil;
        result = [micPort setPreferredDataSource:frontDataSource error:&theError];
        if (!result)
        {
            // an error occurred. Handle it!
            NSLog(@"setPreferredDataSource failed");
        }
    }
    
    // Make sure the built-in mic is selected for input. This will be a no-op if the built-in mic is
    // already the current input Port.
    theError = nil;
    result = [inAudioSession setPreferredInput:micPort error:&theError];
    if (!result)
    {
        // an error occurred. Handle it!
        NSLog(@"setPreferredInput failed");
    }
    
    return 1;
    
}
-(BOOL) isHeadsetAvailable
{
    AVAudioSessionRouteDescription *currentRoute = [[AVAudioSession sharedInstance] currentRoute];
    for (AVAudioSessionPortDescription *output in currentRoute.outputs) {
        if ([[output portType] isEqualToString:AVAudioSessionPortHeadphones]) {
            return true;
        }
    }
    
    return false;
}
-(int) switchSpeaker: (BOOL)builtin
{
    NSError* theError = nil;
    BOOL result = YES;
    
    AVAudioSession* outAudioSession = [AVAudioSession sharedInstance];
    
    result = [outAudioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:&theError];
    if (!result)
    {
        NSLog(@"switchSpeaker::setCategory failed");
    }
    
    result = [outAudioSession setActive:YES error:&theError];
    if (!result)
    {
        NSLog(@"switchSpeaker::setActive failed");
    }
    
    
    //    if(outAudioSession.outputNumberOfChannels > 1)
    //    {
    if(builtin)
    {
        result = [outAudioSession  overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&theError];
        if(!result)
        {
            NSLog(@"overrideOutputAudioPort to speaker failed");
        }
        
    }
    else
    {
        result = [outAudioSession  overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:&theError];
        if(!result)
        {
            NSLog(@"overrideOutputAudioPort to headset failed");
        }
    }
    //    }
    return 1;
}

-(void) audioSessionRouteChanged:(NSNotification*)notification
{
    NSDictionary *interuptionDict = notification.userInfo;
    
    NSInteger routeChangeReason = [[interuptionDict valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    
    switch (routeChangeReason) {
        case AVAudioSessionRouteChangeReasonUnknown:
            NSLog(@"routeChangeReason : AVAudioSessionRouteChangeReasonUnknown");
            break;
            
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            // a headset was added or removed
            NSLog(@"routeChangeReason : AVAudioSessionRouteChangeReasonNewDeviceAvailable");
            [self.delegate onAudioSessionRouteChanged:notification];
            break;
            
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
            // a headset was added or removed
            NSLog(@"routeChangeReason : AVAudioSessionRouteChangeReasonOldDeviceUnavailable");
            [self.delegate onAudioSessionRouteChanged:notification];
            break;
            
        case AVAudioSessionRouteChangeReasonCategoryChange:
            NSLog(@"routeChangeReason : AVAudioSessionRouteChangeReasonCategoryChange");//
            break;
            
        case AVAudioSessionRouteChangeReasonOverride:
            NSLog(@"routeChangeReason : AVAudioSessionRouteChangeReasonOverride");
            break;
            
        case AVAudioSessionRouteChangeReasonWakeFromSleep:
            NSLog(@"routeChangeReason : AVAudioSessionRouteChangeReasonWakeFromSleep");
            break;
            
        case AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory:
            NSLog(@"routeChangeReason : AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory");
            break;
            
        default:
            break;
    }
    
}

@end
