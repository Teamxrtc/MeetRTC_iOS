//
//  WebRTCStatReport.h
//  meet-webrtc-sdk
//
//  Created by Pankaj on 17/07/14.
//  Copyright 2014 Comcast Cable Communications Management, LLC.
//

#import <Foundation/Foundation.h>
#import "RTCStatsReport.h"
enum StatTypes
{
    ssrc
};

enum ValueNames
{
    bytesSent,
    googFrameHeightSent,
    googFrameWidthSent,
    googFrameRateSent
};


@interface WebRTCStatReport : NSObject

@property(nonatomic ) NSInteger bytesSent;
@property(nonatomic ) NSInteger sendFrameRate;
@property(nonatomic ) NSInteger sendWidth;
@property(nonatomic ) NSInteger sendHeight;
@property(nonatomic ) NSInteger sendBandwidth;
@property(nonatomic ) NSInteger recvBandwidth;
@property(nonatomic ) NSInteger rtt;
@property(nonatomic ) NSInteger packetLossSent;
@property(nonatomic ) NSInteger totalPacketSent;
@property(nonatomic ) NSInteger packetLossRecv;
@property(nonatomic ) NSInteger totalPacketRecv;
@property(nonatomic ) double timesstamp;
@property(nonatomic ) NSString* turnServerIP;
@property(nonatomic ) NSString* reportID;
@property(nonatomic ) BOOL generalFlag;
@property(nonatomic ) BOOL rxAudioFlag;
@property(nonatomic ) BOOL rxVideoFlag;
@property(nonatomic ) BOOL txAudioFlag;
@property(nonatomic ) BOOL txVideoFlag;
@property(nonatomic ) NSDateFormatter* dateFormatter;

-(id)init;
-(void)parseReport:(NSArray*)reports;
-(int)useLastReportToCalcCurrentBandwidth:(WebRTCStatReport*)lastReport;
-(NSMutableDictionary*)toJSON;
-(NSString*)toString;
-(NSMutableDictionary*)getRxVideoStat:(NSArray*)pairs;
-(NSMutableDictionary*)getTxVideoStat:(NSArray*)pairs;
-(NSMutableDictionary*)getRxAudioStat:(NSArray*)pairs;
-(NSMutableDictionary*)getTxAudioStat:(NSArray*)pairs;
-(NSMutableDictionary*)getGeneralStat:(NSArray*)pairs;
-(NSString*)getTurnServerIP:(NSArray*)pairs;
-(NSMutableDictionary*)stats;
-(void)streamStatArrayAlloc;
-(void)resetParams;
-(NSString*)toString:(NSArray*)_array;

/* To check if turn ip available */
+ (BOOL)isTurnIPAvailable;
+ (void)setTurnIPAvailabilityStatus:(BOOL)value;
@end
