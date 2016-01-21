//
//  WebRTCStackConfig.m
//  meet-webrtc-sdk
//
//  Created by Pankaj on 26/08/14.
//  Copyright 2014 Comcast Cable Communications Management, LLC.
//

#import "WebRTCStackConfig.h"

@implementation WebRTCStackConfig




@synthesize serverURL = _serverURL;
@synthesize usingRTC20 = _usingRTC20;

//headers for create room http request
@synthesize trackingIdHeader = _trackingIdHeader;
@synthesize serverNameHeader = _serverNameHeader;
@synthesize clientNameHeader = _clientNameHeader;
@synthesize sourceIdHeader = _sourceIdHeader;
@synthesize deviceIdHeader = _deviceIdHeader;


- (id)initRTCGWithDefaultValue:(NSString*)serverURL _userId:(NSString *)userId _usingRTC20:(BOOL)usingRTC20
{
    self = [super init];
    if (self!=nil) {
        
        _serverURL = serverURL;
        _isNwSwitchEnable = false;
        _doManualDns = false;
        userId = [userId lowercaseString]; // US491798
        _usingRTC20 = usingRTC20;
        
        _trackingIdHeader = @"2971c7e0-e839-11e4"; //need to remove the hardcoded value
        _serverNameHeader = @"RTCGSM";
        _clientNameHeader = @"Mobile";
        _sourceIdHeader = @"PBA";
        _deviceIdHeader = @"2971c7e0-e839-11e40"; //need to remove the hardcoded value
            }
    
    return self;
}


@end
