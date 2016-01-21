//
//  WebRTCStackConfig.h
//  meet-webrtc-sdk
//
//  Created by Pankaj on 26/08/14.
//  Copyright 2014 Comcast Cable Communications Management, LLC.
//

#import <Foundation/Foundation.h>

//@class SignalHandler;

@interface WebRTCStackConfig : NSObject

@property (nonatomic) NSString *serverURL;
@property (nonatomic) NSString *userName;

@property (nonatomic) NSInteger portNumber;
@property (nonatomic) BOOL isSecure;
@property (nonatomic) BOOL DtlsOn;
@property (nonatomic) BOOL isNwSwitchEnable;
@property (nonatomic) BOOL doManualDns;
@property (nonatomic) NSString *userId;


//RTC-2.0
@property (nonatomic) BOOL usingRTC20;
//create room request http headers
@property (nonatomic) NSString* trackingIdHeader;
@property (nonatomic) NSString* serverNameHeader;
@property (nonatomic) NSString* clientNameHeader;
@property (nonatomic) NSString* sourceIdHeader;
@property (nonatomic) NSString* deviceIdHeader;

- (id)initRTCGWithDefaultValue:(NSString*)serverURL _userId:(NSString *)userId _usingRTC20:(BOOL)usingRTC20;


@end
