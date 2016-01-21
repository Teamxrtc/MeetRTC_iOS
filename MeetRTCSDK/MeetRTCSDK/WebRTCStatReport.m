//
//  WebRTCStatReport.m
//  meet-webrtc-sdk
//
//  Created by Pankaj on 17/07/14.
//  Copyright 2014 Comcast Cable Communications Management, LLC.
//

#import "WebRTCStatReport.h"
#import "RTCPair.h"

int timeCounter1 = 10;


@interface WebRTCStatReport ()

@property(nonatomic ) NSString* txVideoID;
@property(nonatomic ) NSString* rxVideoID;
@property(nonatomic ) NSString* txAudioID;
@property(nonatomic ) NSString* rxAudioID;
@property(nonatomic ) BOOL isInitDone;
@property(nonatomic ) NSMutableArray* streamStatsArray;
@property(nonatomic ) NSMutableArray* receiveBandwidthArray ;
@property(nonatomic ) NSMutableArray* sendBandwidthArray;
@property(nonatomic ) NSMutableArray* transmitBitrate;
@property(nonatomic ) NSMutableArray* timeStamp;//Added
@property(nonatomic ) NSMutableArray* googTargetEncBitrateCorrected;
@property(nonatomic ) NSMutableArray* googActualEncBitrate;
@property(nonatomic ) NSMutableArray* googRetransmitBitrate;

@property(nonatomic ) NSMutableArray* rxVideoBytesReceived;//
@property(nonatomic ) NSMutableArray* rxVideoCurrentDelayMs;
@property(nonatomic ) NSMutableArray* rxVideoFrameHeightReceived;
@property(nonatomic ) NSMutableArray* rxVideoFrameRateReceived;
@property(nonatomic ) NSMutableArray* rxVideoFrameWidthReceived;
@property(nonatomic ) NSMutableArray* rxVideoPacketsLost;
@property(nonatomic ) NSMutableArray* rxVideoPacketsReceived;// Added
@property(nonatomic ) NSMutableArray* rxVideogoogCaptureStartNtpTimeMs;
@property(nonatomic ) NSMutableArray* rxVideogoogDecodeMs;
@property(nonatomic ) NSMutableArray* rxVideogoogFirsSent ;
@property(nonatomic ) NSMutableArray* rxVideogoogFrameRateDecoded;
@property(nonatomic ) NSMutableArray* rxVideogoogFrameRateOutput;
@property(nonatomic ) NSMutableArray* rxVideogoogJitterBufferMs;
@property(nonatomic ) NSMutableArray* rxVideogoogMaxDecodeMs;
@property(nonatomic ) NSMutableArray* rxVideogoogMinPlayoutDelayMs;
@property(nonatomic ) NSMutableArray* rxVideogoogNacksSent;
@property(nonatomic ) NSMutableArray* rxVideogoogPlisSent;
@property(nonatomic ) NSMutableArray* rxVideogoogRenderDelayMs;
@property(nonatomic ) NSMutableArray* rxVideogoogTargetDelayMs;

@property(nonatomic ) NSMutableArray* rxAudioOutputLevel;//
@property(nonatomic ) NSMutableArray* rxAudioBytesReceived;
@property(nonatomic ) NSMutableArray* rxAudioPacketsLost;
@property(nonatomic ) NSMutableArray* rxAudioPacketsReceived;//Added
@property(nonatomic ) NSMutableArray* rxAudiogoogAccelerateRate;
@property(nonatomic ) NSMutableArray* rxAudiogoogCaptureStartNtpTimeMs;
@property(nonatomic ) NSMutableArray* rxAudiogoogCurrentDelayMs;
@property(nonatomic ) NSMutableArray* rxAudiogoogDecodingCNG;
@property(nonatomic ) NSMutableArray* rxAudiogoogDecodingCTN;
@property(nonatomic ) NSMutableArray* rxAudiogoogDecodingCTSG;
@property(nonatomic ) NSMutableArray* rxAudiogoogDecodingNormal;
@property(nonatomic ) NSMutableArray* rxAudiogoogDecodingPLC;
@property(nonatomic ) NSMutableArray* rxAudiogoogDecodingPLCCNG;
@property(nonatomic ) NSMutableArray* rxAudiogoogExpandRate;
@property(nonatomic ) NSMutableArray* rxAudiogoogJitterBufferMs;
@property(nonatomic ) NSMutableArray* rxAudiogoogJitterReceived;
@property(nonatomic ) NSMutableArray* rxAudiogoogPreemptiveExpandRate;
@property(nonatomic ) NSMutableArray* rxAudiogoogPreferredJitterBufferMs;
@property(nonatomic ) NSMutableArray* rxAudiogoogSecondaryDecodedRate;
@property(nonatomic ) NSMutableArray* rxAudiogoogSpeechExpandRate;

@property(nonatomic ) NSMutableArray* txVideoBytesSent;//
@property(nonatomic ) NSMutableArray* txVideoEncodeUsagePercent;
@property(nonatomic ) NSMutableArray* txVideoFrameHeightSent;
@property(nonatomic ) NSMutableArray* txVideoFrameRateSent;
@property(nonatomic ) NSMutableArray* txVideoFrameWidthSent;
@property(nonatomic ) NSMutableArray* txVideoRtt;
@property(nonatomic ) NSMutableArray* txVideoPacketsLost;
@property(nonatomic ) NSMutableArray* txVideoPacketsSent;//Added
@property(nonatomic ) NSMutableArray* txVideogoogAdaptationChanges;
@property(nonatomic ) NSMutableArray* txVideogoogAvgEncodeMs;
@property(nonatomic ) NSMutableArray* txVideogoogFirsReceived;
@property(nonatomic ) NSMutableArray* txVideogoogFrameHeightInput;
@property(nonatomic ) NSMutableArray* txVideogoogFrameRateInput;
@property(nonatomic ) NSMutableArray* txVideogoogFrameWidthInput;
@property(nonatomic ) NSMutableArray* txVideogoogNacksReceived;
@property(nonatomic ) NSMutableArray* txVideogoogPlisReceived;

@property(nonatomic ) NSMutableArray* txAudioInputLevel;//
@property(nonatomic ) NSMutableArray* txAudioBytesSent;
@property(nonatomic ) NSMutableArray* txAudioPacketsLost;
@property(nonatomic ) NSMutableArray* txAudioPacketsSent; //Added
@property(nonatomic ) NSMutableArray* txAudiogoogEchoCancellationQualityMin;
@property(nonatomic ) NSMutableArray* txAudiogoogEchoCancellationEchoDelayMedian;
@property(nonatomic ) NSMutableArray* txAudiogoogEchoCancellationEchoDelayStdDev;
@property(nonatomic ) NSMutableArray* txAudiogoogEchoCancellationReturnLoss;
@property(nonatomic ) NSMutableArray* txAudiogoogEchoCancellationReturnLossEnhancement;
@property(nonatomic ) NSMutableArray* txAudiogoogJitterReceived;
@property(nonatomic ) NSMutableArray* txAudiogoogRtt;

@property(nonatomic ) NSInteger arrayIndex;

@end

static BOOL isTurnIPAvailable;

@implementation WebRTCStatReport
@synthesize bytesSent;
@synthesize sendFrameRate;
@synthesize sendWidth;
@synthesize sendHeight;
@synthesize sendBandwidth;
@synthesize recvBandwidth;
@synthesize timesstamp;
@synthesize rtt;
@synthesize packetLossSent;
@synthesize totalPacketSent;
@synthesize packetLossRecv;
@synthesize totalPacketRecv;
@synthesize  turnServerIP;
@synthesize generalFlag;
@synthesize rxAudioFlag;
@synthesize rxVideoFlag;
@synthesize txAudioFlag;
@synthesize txVideoFlag;
@synthesize dateFormatter;

-(id)init
{
    self = [super init];
    if (self!=nil) {
        
        _txVideoID = nil;
        _rxVideoID = nil;
        _txAudioID = nil;
        _rxAudioID = nil;
        _isInitDone = false;
        isTurnIPAvailable = false;
        turnServerIP = @"";
        rtt = 0;
        totalPacketSent = 0;
        packetLossSent = 0;
        generalFlag = false;
        rxAudioFlag = false;
        rxVideoFlag = false;
        txAudioFlag = false;
        txVideoFlag = false ;
        _streamStatsArray = [[NSMutableArray alloc]init];
        _receiveBandwidthArray  = [NSMutableArray array];
        _sendBandwidthArray     = [NSMutableArray array];
        _transmitBitrate        = [NSMutableArray array];
        _timeStamp              = [NSMutableArray array];//Added
        _googTargetEncBitrateCorrected      = [NSMutableArray array];
        _googActualEncBitrate      = [NSMutableArray array];
        _googRetransmitBitrate      = [NSMutableArray array];
        
        _rxVideoBytesReceived   = [NSMutableArray array];
        _rxVideoCurrentDelayMs  = [NSMutableArray array];
        _rxVideoFrameHeightReceived = [NSMutableArray array];
        _rxVideoFrameRateReceived   = [NSMutableArray array];
        _rxVideoFrameWidthReceived  = [NSMutableArray array];
        _rxVideoPacketsLost         = [NSMutableArray array];
        _rxVideoPacketsReceived     = [NSMutableArray array];//Added
        _rxVideogoogCaptureStartNtpTimeMs  = [NSMutableArray array];
        
        _rxVideogoogDecodeMs  = [NSMutableArray array];
        _rxVideogoogFirsSent   = [NSMutableArray array];
        
        _rxVideogoogFrameRateDecoded  = [NSMutableArray array];
        _rxVideogoogFrameRateOutput  = [NSMutableArray array];
        
        
        _rxVideogoogJitterBufferMs  = [NSMutableArray array];
        _rxVideogoogMaxDecodeMs  = [NSMutableArray array];
        _rxVideogoogMinPlayoutDelayMs  = [NSMutableArray array];
        _rxVideogoogNacksSent  = [NSMutableArray array];
        _rxVideogoogPlisSent  = [NSMutableArray array];
        _rxVideogoogRenderDelayMs  = [NSMutableArray array];
        _rxVideogoogTargetDelayMs  = [NSMutableArray array];
        
        _rxAudioOutputLevel         = [NSMutableArray array];//
        _rxAudioBytesReceived       = [NSMutableArray array];
        _rxAudioPacketsLost         = [NSMutableArray array];
        _rxAudioPacketsReceived     = [NSMutableArray array];//Added
        
        _rxAudiogoogAccelerateRate = [NSMutableArray array];
        _rxAudiogoogCaptureStartNtpTimeMs = [NSMutableArray array];
        _rxAudiogoogCurrentDelayMs = [NSMutableArray array];
        _rxAudiogoogDecodingCNG = [NSMutableArray array];
        _rxAudiogoogDecodingCTN = [NSMutableArray array];
        _rxAudiogoogDecodingCTSG = [NSMutableArray array];
        _rxAudiogoogDecodingNormal = [NSMutableArray array];
        _rxAudiogoogDecodingPLC = [NSMutableArray array];
        _rxAudiogoogDecodingPLCCNG = [NSMutableArray array];
        _rxAudiogoogExpandRate = [NSMutableArray array];
        _rxAudiogoogJitterBufferMs = [NSMutableArray array];
        _rxAudiogoogJitterReceived = [NSMutableArray array];
        _rxAudiogoogPreemptiveExpandRate = [NSMutableArray array];
        _rxAudiogoogPreferredJitterBufferMs = [NSMutableArray array];
        _rxAudiogoogSecondaryDecodedRate = [NSMutableArray array];
        _rxAudiogoogSpeechExpandRate = [NSMutableArray array];
        
        _txVideoBytesSent           = [NSMutableArray array];//
        _txVideoEncodeUsagePercent  = [NSMutableArray array];
        _txVideoFrameHeightSent     = [NSMutableArray array];
        _txVideoFrameRateSent       = [NSMutableArray array];
        _txVideoFrameWidthSent      = [NSMutableArray array];
        _txVideoRtt                 = [NSMutableArray array];
        _txVideoPacketsLost         = [NSMutableArray array];
        _txVideoPacketsSent         = [NSMutableArray array];//Added
        _txVideogoogAdaptationChanges = [NSMutableArray array];
        _txVideogoogAvgEncodeMs = [NSMutableArray array];
        _txVideogoogFirsReceived = [NSMutableArray array];
        _txVideogoogFrameHeightInput = [NSMutableArray array];
        _txVideogoogFrameRateInput = [NSMutableArray array];
        _txVideogoogFrameWidthInput = [NSMutableArray array];
        _txVideogoogNacksReceived = [NSMutableArray array];
        _txVideogoogPlisReceived = [NSMutableArray array];
        
        _txAudioInputLevel          = [NSMutableArray array];//
        _txAudioBytesSent           = [NSMutableArray array];
        _txAudioPacketsSent         = [NSMutableArray array];
        _txAudioPacketsLost         = [NSMutableArray array]; //Added
        _txAudiogoogEchoCancellationQualityMin  =[NSMutableArray array];
        _txAudiogoogEchoCancellationEchoDelayMedian =[NSMutableArray array];
        _txAudiogoogEchoCancellationEchoDelayStdDev = [NSMutableArray array];
        _txAudiogoogEchoCancellationReturnLoss =[NSMutableArray array];
        _txAudiogoogEchoCancellationReturnLossEnhancement =[NSMutableArray array];
        _txAudiogoogJitterReceived =[NSMutableArray array];
        _txAudiogoogRtt =[NSMutableArray array];
        
        _arrayIndex = 0;
        
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
        
    }
    
    return self;
}

-(void)initIDForSSRC:(NSArray*)reports
{
    for(RTCStatsReport* report in reports)
    {
        NSString* type = report.type;
        if (![type compare:@"ssrc"])
        {
            NSArray* pairs = report.values;
            
            for(RTCPair* pair in pairs)
            {
                NSString* type = pair.key;
                
                if(![type compare:@"googFrameRateReceived"])
                {
                    _rxVideoID = report.reportId;
                }
                else if(![type compare:@"googFrameRateSent"])
                {
                    _txVideoID = report.reportId;
                }
                else if(![type compare:@"audioOutputLevel"])
                {
                    _rxAudioID = report.reportId;
                }
                else if(![type compare:@"audioInputLevel"])
                {
                    _txAudioID = report.reportId;
                }
            }
            
        }
    }
    
}


-(NSMutableDictionary*)getTxAudioStat:(NSArray*)pairs
{
    NSMutableDictionary* obj = [[NSMutableDictionary alloc]init];
    [obj setValue:@"TxAudio" forKey:@"id"];
    
    for(RTCPair* pair in pairs)
    {
        //obj = [[NSMutableDictionary alloc]init];
        NSNumber *aWrappedInt = nil;
        NSString* type = pair.key;
            
        if(![type compare:@"bytesSent"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
            [obj setValue:aWrappedInt forKey:@"bytesSent"];
            [_txAudioBytesSent setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"audioInputLevel"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
            [obj setValue:aWrappedInt forKey:@"audioInputLevel"];
            [_txAudioInputLevel setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"packetsSent"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
            [obj setValue:aWrappedInt forKey:@"packetsSent"];
            [_txAudioPacketsSent setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"packetsLost"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
            [obj setValue:aWrappedInt forKey:@"packetsLost"];
            [_txAudioPacketsLost setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"googEchoCancellationQualityMin"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
            [obj setValue:aWrappedInt forKey:@"googEchoCancellationQualityMin"];
            [_txAudiogoogEchoCancellationQualityMin  setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"googEchoCancellationEchoDelayMedian"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
            [obj setValue:aWrappedInt forKey:@"googEchoCancellationEchoDelayMedian"];
            [_txAudiogoogEchoCancellationEchoDelayMedian  setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"googEchoCancellationEchoDelayStdDev"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
            [obj setValue:aWrappedInt forKey:@"googEchoCancellationEchoDelayStdDev"];
            [_txAudiogoogEchoCancellationEchoDelayStdDev  setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"googEchoCancellationReturnLoss"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
            [obj setValue:aWrappedInt forKey:@"googEchoCancellationReturnLoss"];
            [_txAudiogoogEchoCancellationReturnLoss  setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"googEchoCancellationReturnLossEnhancement"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
            [obj setValue:aWrappedInt forKey:@"googEchoCancellationReturnLossEnhancement"];
            [_txAudiogoogEchoCancellationReturnLossEnhancement  setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"googJitterReceived"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
            [obj setValue:aWrappedInt forKey:@"googJitterReceived"];
            [_txAudiogoogJitterReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"googRtt"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
            [obj setValue:aWrappedInt forKey:@"googRtt"];
            [_txAudiogoogRtt setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }

    }
    
    return obj;
}

-(NSMutableDictionary*)getTxVideoStat:(NSArray*)pairs
{
    NSMutableDictionary* obj = [[NSMutableDictionary alloc]init];
    [obj setValue:@"TxVideo" forKey:@"id"];
    
    for(RTCPair* pair in pairs)
    {
        //obj = [[NSMutableDictionary alloc]init];
        NSNumber *aWrappedInt = nil;
        NSString* type = pair.key;
        
        if(![type compare:@"bytesSent"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
            [obj setValue:aWrappedInt forKey:@"bytesSent"];
            [_txVideoBytesSent setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"packetsSent"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
            [obj setValue:aWrappedInt forKey:@"packetsSent"];
            [_txVideoPacketsSent setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"googFrameHeightSent"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googFrameHeightSent"];
             [_txVideoFrameHeightSent setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googFrameWidthSent"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googFrameWidthSent"];
             [_txVideoFrameWidthSent setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googFrameRateSent"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googFrameRateSent"];
             [_txVideoFrameRateSent setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googEncodeUsagePercent"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googEncodeUsagePercent"];
             [_txVideoEncodeUsagePercent setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googRtt"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             rtt = [aWrappedInt integerValue];
             if(rtt < 0)
                 rtt = 0;
             //rtt = aWrappedInt;
             [obj setValue:aWrappedInt forKey:@"googRtt"];
             [_txVideoRtt setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"packetsLost"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             packetLossSent = [aWrappedInt integerValue];
             if(packetLossSent < 0)
                 packetLossSent = 0;
             [obj setValue:aWrappedInt forKey:@"packetsLost"];
            [_txVideoPacketsLost setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googAdaptationChanges"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googAdaptationChanges"];
             [_txVideogoogAdaptationChanges setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googAvgEncodeMs"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googAvgEncodeMs"];
             [_txVideogoogAvgEncodeMs setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googFirsReceived"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googFirsReceived"];
             [_txVideogoogFirsReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googFrameHeightInput"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googFrameHeightInput"];
             [_txVideogoogFrameHeightInput setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googFrameRateInput"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googFrameRateInput"];
             [_txVideogoogFrameRateInput setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
        
         else if(![type compare:@"googFrameWidthInput"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googFrameWidthInput"];
             [_txVideogoogFrameWidthInput setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
        
         else if(![type compare:@"googNacksReceived"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googNacksReceived"];
             [_txVideogoogNacksReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googPlisReceived"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googPlisReceived"];
             [_txVideogoogPlisReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
    }

    
    return obj;
}

-(NSMutableDictionary*)getRxAudioStat:(NSArray*)pairs
{
    NSMutableDictionary* obj = [[NSMutableDictionary alloc]init];
    [obj setValue:@"RxAudio" forKey:@"id"];
    
    for(RTCPair* pair in pairs)
    {
        //obj = [[NSMutableDictionary alloc]init];
        NSNumber *aWrappedInt = nil;
        NSString* type = pair.key;
        
        if(![type compare:@"bytesReceived"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
            [obj setValue:aWrappedInt forKey:@"bytesReceived"];
            [_rxAudioBytesReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"audioOutputLevel"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"audioOutputLevel"];
             [_rxAudioOutputLevel setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"packetsReceived"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"packetsReceived"];
             [_rxAudioPacketsReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"packetsLost"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"packetsLost"];
             [_rxAudioPacketsLost setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googAccelerateRate"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googAccelerateRate"];
             [_rxAudiogoogAccelerateRate setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googCaptureStartNtpTimeMs"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googCaptureStartNtpTimeMs"];
             [_rxAudiogoogCaptureStartNtpTimeMs setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googCurrentDelayMs"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googCurrentDelayMs"];
             [_rxAudiogoogCurrentDelayMs setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googDecodingCNG"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googDecodingCNG"];
             [_rxAudiogoogDecodingCNG setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googDecodingCTN "])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googDecodingCTN "];
             [_rxAudiogoogDecodingCTN setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googDecodingCTSG "])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googDecodingCTSG "];
             [_rxAudiogoogDecodingCTSG setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googDecodingNormal "])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googDecodingNormal "];
             [_rxAudiogoogDecodingNormal setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googDecodingPLC"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googDecodingPLC"];
             [_rxAudiogoogDecodingPLC setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googDecodingPLCCNG"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googDecodingPLCCNG"];
             [_rxAudiogoogDecodingPLCCNG setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googExpandRate"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googExpandRate"];
             [_rxAudiogoogExpandRate setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googJitterBufferMs"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googJitterBufferMs"];
             [_rxAudiogoogJitterBufferMs setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googJitterReceived"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googJitterReceived"];
             [_rxAudiogoogJitterReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googPreemptiveExpandRate"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googPreemptiveExpandRate"];
             [_rxAudiogoogPreemptiveExpandRate setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googPreferredJitterBufferMs"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googPreferredJitterBufferMs"];
             [_rxAudiogoogPreferredJitterBufferMs setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googSecondaryDecodedRate"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googSecondaryDecodedRate"];
             [_rxAudiogoogSecondaryDecodedRate setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googSpeechExpandRate"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googSpeechExpandRate"];
             [_rxAudiogoogSpeechExpandRate setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
    }

    return obj;
}

-(NSMutableDictionary*)getRxVideoStat:(NSArray*)pairs
{
    NSMutableDictionary* obj = [[NSMutableDictionary alloc]init];
    [obj setValue:@"RxVideo" forKey:@"id"];
    
    for(RTCPair* pair in pairs)
    {
        //obj = [[NSMutableDictionary alloc]init];
        NSNumber *aWrappedInt = nil;
        NSString* type = pair.key;
        
        if(![type compare:@"bytesReceived"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
            [obj setValue:aWrappedInt forKey:@"bytesReceived"];
            [_rxVideoBytesReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"packetsReceived"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
            [obj setValue:aWrappedInt forKey:@"packetsReceived"];
            [_rxVideoPacketsReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];        }
        else if(![type compare:@"googFrameHeightReceived"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googFrameHeightReceived"];
             [_rxVideoFrameHeightReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];         }
         else if(![type compare:@"googFrameWidthReceived"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googFrameWidthReceived"];
             [_rxVideoFrameWidthReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googFrameRateReceived"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googFrameRateReceived"];
             [_rxVideoFrameRateReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googCurrentDelayMs"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googCurrentDelayMs"];
             [_rxVideoCurrentDelayMs setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"packetsLost"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             packetLossRecv = [aWrappedInt integerValue];
             if(packetLossRecv < 0)
                 packetLossRecv = 0;
             [obj setValue:aWrappedInt forKey:@"packetsLost"];
             [_rxVideoPacketsLost setObject:aWrappedInt atIndexedSubscript:_arrayIndex];

         }
         else if(![type compare:@"googCaptureStartNtpTimeMs"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googCaptureStartNtpTimeMs"];
             [_rxVideogoogCaptureStartNtpTimeMs setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googDecodeMs"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googDecodeMs"];
             [_rxVideogoogDecodeMs setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googFirsSent"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googFirsSent"];
             [_rxVideogoogFirsSent setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googFrameRateDecoded"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googFrameRateDecoded"];
             [_rxVideogoogFrameRateDecoded setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googFrameRateOutput"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googFrameRateOutput"];
             [_rxVideogoogFrameRateOutput setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googJitterBufferMs"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googJitterBufferMs"];
             [_rxVideogoogJitterBufferMs setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googMaxDecodeMs"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googMaxDecodeMs"];
             [_rxVideogoogMaxDecodeMs setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googMinPlayoutDelayMs"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googMinPlayoutDelayMs"];
             [_rxVideogoogMinPlayoutDelayMs setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googNacksSent"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googNacksSent"];
             [_rxVideogoogNacksSent setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googPlisSent"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googPlisSent"];
             [_rxVideogoogPlisSent setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googRenderDelayMs"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googRenderDelayMs"];
             [_rxVideogoogRenderDelayMs setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googTargetDelayMs"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googTargetDelayMs"];
             [_rxVideogoogTargetDelayMs setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
    }

    return obj;
}


-(NSMutableDictionary*)getGeneralStat:(NSArray*)pairs
{
    NSMutableDictionary* obj = [[NSMutableDictionary alloc]init];
    [obj setValue:@"General" forKey:@"id"];
    
    for(RTCPair* pair in pairs)
    {
        //obj = [[NSMutableDictionary alloc]init];
        NSNumber *aWrappedInt = nil;
        NSString* type = pair.key;
        
        if(![type compare:@"googAvailableSendBandwidth"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
            sendBandwidth = [aWrappedInt integerValue];
            [obj setValue:aWrappedInt forKey:@"googAvailableSendBandwidth"];
            [_sendBandwidthArray setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"googTransmitBitrate"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
            [obj setValue:aWrappedInt forKey:@"googTransmitBitrate"];
            [_transmitBitrate setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"googAvailableReceiveBandwidth"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
            recvBandwidth = [aWrappedInt integerValue];
            [_receiveBandwidthArray setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
            [obj setValue:aWrappedInt forKey:@"googAvailableReceiveBandwidth"];
        }
        else if(![type compare:@"packetsLost"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
            [obj setValue:aWrappedInt forKey:@"packetsLost"];
        }
        else if(![type compare:@"googTargetEncBitrateCorrected"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
            recvBandwidth = [aWrappedInt integerValue];
            [_googTargetEncBitrateCorrected setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
            [obj setValue:aWrappedInt forKey:@"googTargetEncBitrateCorrected"];
        }
        else if(![type compare:@"googActualEncBitrate"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
            recvBandwidth = [aWrappedInt integerValue];
            [_googActualEncBitrate setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
            [obj setValue:aWrappedInt forKey:@"googActualEncBitrate"];
        }
        else if(![type compare:@"googRetransmitBitrate"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
            recvBandwidth = [aWrappedInt integerValue];
            [_googRetransmitBitrate setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
            [obj setValue:aWrappedInt forKey:@"googRetransmitBitrate"];
        }
    }
    
    return obj;
}

-(NSString*)getTurnServerIP:(NSArray *)pairs
{
    NSString * serverIP = @"";
    BOOL isActive = false;
    BOOL isRelay = false;        
    NSString* remoteCandidateType = @"relay";
    
    for(RTCPair* pair in pairs)
    {
        //obj = [[NSMutableDictionary alloc]init];
        NSString* type = pair.key;
        
        if(![type compare:@"googActiveConnection"])
        {
            isActive = [pair.value boolValue];
        }
        else
        if(![type compare:@"googRemoteCandidateType"])
        {
            if(![pair.value compare:@"relay"])
            isRelay = true;
        }
        else
        if(![type compare:@"googRemoteAddress"])
        {
            serverIP = pair.value;
        }
    }
    if(isActive && isRelay)
    {
        isTurnIPAvailable = true;
        return serverIP;
    }

    return @"";
}


-(void)parseReport:(NSArray*)reports
{
    NSInteger anInt = 0;
    NSNumber *aWrappedInt = [NSNumber numberWithInteger:anInt];
    if(!_isInitDone)
    {
        [self initIDForSSRC:reports];
        _isInitDone = true;
    }
    for(RTCStatsReport* report in reports)
    {
        NSString* type = report.type;
        timesstamp = report.timestamp;
        NSDate* now = [NSDate date];
        [_timeStamp setObject:[dateFormatter stringFromDate:now] atIndexedSubscript:_arrayIndex];
        
        NSMutableDictionary* streamStats = nil;
        if (![type compare:@"ssrc"] || ![type compare:@"VideoBwe"])
        {
            NSString* reportID = report.reportId;
            NSArray* pairs = report.values;
            if(![reportID compare:_rxVideoID])
            {
                streamStats = [self getRxVideoStat:pairs];
                NSInteger packetLost = [[streamStats objectForKey:@"packetsLost"]integerValue];
                NSInteger packetRecv = [[streamStats objectForKey:@"packetsReceived"]integerValue];
                //totalPacketSent = packetRecv + packetLost;
                totalPacketRecv = packetRecv + packetLost;
                if(totalPacketRecv <= 0)
                    totalPacketRecv = 1;
                rxVideoFlag = true;
            }
            else
            if(![reportID compare:_txVideoID])
            {
                streamStats = [self getTxVideoStat:pairs];
                NSInteger packetLost = [[streamStats objectForKey:@"packetsLost"]integerValue];
                NSInteger packetSent = [[streamStats objectForKey:@"packetsSent"]integerValue];
                totalPacketSent = packetSent + packetLost;
                if(totalPacketSent <= 0)
                    totalPacketSent = 1;
                txVideoFlag = true;
            }
            else
            if(![reportID compare:_rxAudioID])
            {
                streamStats = [self getRxAudioStat:pairs];
                rxAudioFlag = true ;
            }
            else
            if(![reportID compare:_txAudioID])
            {
                streamStats = [self getTxAudioStat:pairs];
                txAudioFlag = true ;
            }
            else
            if(![reportID compare:@"bweforvideo"])
            {
                streamStats = [self getGeneralStat:pairs];
                generalFlag = true;
            }
            
        }
        else
        if (![type compare:@"googCandidatePair"] && !isTurnIPAvailable)
        {
            NSArray* pairs = report.values;
            turnServerIP = [self getTurnServerIP:pairs];
        }
        if(streamStats != nil)
        [_streamStatsArray addObject:streamStats];
    }

    if (!rxVideoFlag) {
        
        [_rxVideoBytesReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_rxVideoPacketsReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_rxVideoFrameHeightReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_rxVideoFrameWidthReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_rxVideoFrameRateReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_rxVideoCurrentDelayMs setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_rxVideoPacketsLost setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_rxVideogoogCaptureStartNtpTimeMs  setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        
        [_rxVideogoogDecodeMs  setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_rxVideogoogFirsSent   setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        
        [_rxVideogoogFrameRateDecoded  setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_rxVideogoogFrameRateOutput  setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        
        
        [_rxVideogoogJitterBufferMs  setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_rxVideogoogMaxDecodeMs  setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_rxVideogoogMinPlayoutDelayMs  setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_rxVideogoogNacksSent  setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_rxVideogoogPlisSent  setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_rxVideogoogRenderDelayMs  setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_rxVideogoogTargetDelayMs  setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        rxVideoFlag = false;
    }
    
    if (!txVideoFlag) {
        
        [_txVideoBytesSent setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_txVideoEncodeUsagePercent setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_txVideoFrameHeightSent setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_txVideoFrameRateSent setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_txVideoFrameWidthSent setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_txVideoRtt setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_txVideoPacketsLost setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_txVideoPacketsSent setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_txVideogoogAdaptationChanges setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_txVideogoogAvgEncodeMs setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_txVideogoogFirsReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_txVideogoogFrameHeightInput setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_txVideogoogFrameRateInput setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_txVideogoogFrameWidthInput setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_txVideogoogNacksReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_txVideogoogPlisReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        
        txVideoFlag = false ;
        
    }
    
    if (!rxAudioFlag) {
        
        [_rxAudioOutputLevel setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_rxAudioBytesReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_rxAudioPacketsLost setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_rxAudioPacketsReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_rxAudiogoogAccelerateRate  setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_rxAudiogoogCaptureStartNtpTimeMs  setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_rxAudiogoogCurrentDelayMs  setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_rxAudiogoogDecodingCNG  setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_rxAudiogoogDecodingCTN  setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_rxAudiogoogDecodingCTSG  setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_rxAudiogoogDecodingNormal  setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_rxAudiogoogDecodingPLC  setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_rxAudiogoogDecodingPLCCNG  setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_rxAudiogoogExpandRate  setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_rxAudiogoogJitterBufferMs  setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_rxAudiogoogJitterReceived  setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_rxAudiogoogPreemptiveExpandRate  setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_rxAudiogoogPreferredJitterBufferMs  setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_rxAudiogoogSecondaryDecodedRate  setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_rxAudiogoogSpeechExpandRate  setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        rxAudioFlag = false;

    }
    
    if (!txAudioFlag) {
        
        [_txAudioInputLevel setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_txAudioBytesSent setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_txAudioPacketsLost setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_txAudioPacketsSent setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_txAudiogoogEchoCancellationQualityMin setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_txAudiogoogEchoCancellationEchoDelayStdDev setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_txAudiogoogEchoCancellationReturnLoss setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_txAudiogoogEchoCancellationReturnLossEnhancement setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_txAudiogoogJitterReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_txAudiogoogRtt setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
                 txAudioFlag = false;
    }
    
    if (!generalFlag) {
        
        [_sendBandwidthArray setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_receiveBandwidthArray setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_transmitBitrate setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_googTargetEncBitrateCorrected setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_googActualEncBitrate setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_googRetransmitBitrate setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        generalFlag = false;
    }
    
    if (timeCounter1 == 10) {
        _arrayIndex++;
        timeCounter1 = 0;
    }
    timeCounter1++;

}

-(void)resetParams
{
    _txVideoID = nil;
    _rxVideoID = nil;
    _txAudioID = nil;
    _rxAudioID = nil;
    _isInitDone = false;
    isTurnIPAvailable = false;
    turnServerIP = @"";
    rtt = 0;
    totalPacketSent = 0;
    packetLossSent = 0;
 
}

-(int)useLastReportToCalcCurrentBandwidth:(WebRTCStatReport*)lastReport
{
    
    /*
    double d = (bytesSent - (lastReport.bytesSent))/((timesstamp - (lastReport.timesstamp))/10);
    
    NSLog(@"Time difference is = %f",d);
    sendBandwidth = d;*/
    return sendBandwidth;
}


-(NSDictionary*)toJSON{
    
    NSMutableDictionary *obj1 = [[NSMutableDictionary alloc]init];
    [obj1 setValue:_streamStatsArray forKey:@"groups"];
    return  obj1;
}

-(NSString*)toString
{
    NSMutableDictionary* data = [self toJSON];
    NSString *string = [NSString stringWithFormat:@"%@",data];
    return string;
}

+ (BOOL)isTurnIPAvailable
{
    return isTurnIPAvailable;
}

-(void)streamStatArrayAlloc
{    
 _streamStatsArray = [[NSMutableArray alloc]init];
}

+ (void)setTurnIPAvailabilityStatus:(BOOL)value
{
    isTurnIPAvailable = value;
}

-(NSString*)toString:(NSArray*)_array{
    
    return [[_array valueForKey:@"description"] componentsJoinedByString:@","];
}

-(NSMutableDictionary*)stats{
    NSString * result;
    
    NSMutableDictionary* general = [[NSMutableDictionary alloc]init];
    
    NSMutableDictionary* rxVideo = [[NSMutableDictionary alloc]init];
    
    NSMutableDictionary* rxAudio = [[NSMutableDictionary alloc]init];
    
    NSMutableDictionary* txVideo = [[NSMutableDictionary alloc]init];
    
    NSMutableDictionary* txAudio = [[NSMutableDictionary alloc]init];
    
    NSMutableDictionary* timeseries = [[NSMutableDictionary alloc]init];
    
    /////////////////////////////////////////////////////////////////
    
    result = [self toString:_receiveBandwidthArray];
    [general setObject:result forKey:@"googAvailableReceiveBandwidth"];
    
    result = [self toString:_sendBandwidthArray];
    [general setObject:result forKey:@"googAvailableSendBandwidth"];
    
    result = [self toString:_transmitBitrate];
    [general setObject:result forKey:@"googTransmitBitrate"];
    
    result = [self toString:_timeStamp];
    [general setObject:result forKey:@"timestamp"];
    
    
    result = [self toString:_googTargetEncBitrateCorrected];
    [general setObject:result forKey:@"googTargetEncBitrateCorrected"];
    
    result = [self toString:_googActualEncBitrate];
    [general setObject:result forKey:@"googActualEncBitrate"];
    
    
    result = [self toString:_googRetransmitBitrate];
    [general setObject:result forKey:@"googRetransmitBitrate"];
    
    ///////////////////////////////////////////////////////////////////
    
    result = [self toString:_rxVideoBytesReceived];
    if(result != nil) [rxVideo  setObject:result forKey:@"bytesReceived"];
    
    result = [self toString:_rxVideoCurrentDelayMs];
    if(result != nil)[rxVideo  setObject:result forKey:@"googCurrentDelayMs"];
    
    result = [self toString:_rxVideoFrameHeightReceived];
    if(result != nil)[rxVideo  setObject:result forKey:@"googFrameHeightReceived"];
    
    result = [self toString:_rxVideoFrameRateReceived];
    if(result != nil)[rxVideo  setObject:result forKey:@"googFrameRateReceived"];
    
    result = [self toString:_rxVideoFrameWidthReceived];
    if(result != nil)[rxVideo  setObject:result forKey:@"googFrameWidthReceived"];
    
    result = [self toString:_rxVideoPacketsLost];
    if(result != nil)[rxVideo  setObject:result forKey:@"packetsLost"];
    
    result = [self toString:_rxVideoPacketsReceived];
    if(result != nil)[rxVideo  setObject:result forKey:@"packetsReceived"];
    
    
    result = [self toString:_rxVideogoogCaptureStartNtpTimeMs];
    if(result != nil)[rxVideo  setObject:result forKey:@"googCaptureStartNtpTimeMs"];
    
    result = [self toString:_rxVideogoogDecodeMs];
    if(result != nil)[rxVideo  setObject:result forKey:@"googDecodeMs"];
    
    
    result = [self toString:_rxVideogoogFirsSent];
    if(result != nil)[rxVideo  setObject:result forKey:@"googFirsSent"];
    
    result = [self toString:_rxVideogoogFrameRateDecoded];
    if(result != nil)[rxVideo  setObject:result forKey:@"googFrameRateDecoded"];
    
    result = [self toString:_rxVideogoogFrameRateOutput];
    if(result != nil)[rxVideo  setObject:result forKey:@"googFrameRateOutput"];
    
    result = [self toString:_rxVideogoogJitterBufferMs];
    if(result != nil)[rxVideo  setObject:result forKey:@"googJitterBufferMs"];
    
    result = [self toString:_rxVideogoogMaxDecodeMs];
    if(result != nil)[rxVideo  setObject:result forKey:@"googMaxDecodeMs"];
    
    result = [self toString:_rxVideogoogMinPlayoutDelayMs];
    if(result != nil)[rxVideo  setObject:result forKey:@"googMinPlayoutDelayMs"];
    
    result = [self toString:_rxVideogoogNacksSent];
    if(result != nil)[rxVideo  setObject:result forKey:@"googNacksSent"];
    
    result = [self toString:_rxVideogoogPlisSent];
    if(result != nil)[rxVideo  setObject:result forKey:@"googPlisSent"];
    
    result = [self toString:_rxVideogoogRenderDelayMs];
    if(result != nil)[rxVideo  setObject:result forKey:@"googRenderDelayMs"];
    
    result = [self toString:_rxVideogoogTargetDelayMs];
    if(result != nil)[rxVideo  setObject:result forKey:@"googTargetDelayMs"];
    
    ///////////////////////////////////////////////////////////////////
    
    result = [self toString:_rxAudioOutputLevel];
    if(result != nil)[rxAudio setObject:result forKey:@"audioOutputLevel"];
    
    result = [self toString:_rxAudioBytesReceived];
    if(result != nil)[rxAudio setObject:result forKey:@"bytesReceived"];
    
    result = [self toString:_rxAudioPacketsLost];
    if(result != nil)[rxAudio setObject:result forKey:@"packetsLost"];
    
    result = [self toString:_rxAudioPacketsReceived];
    if(result != nil)[rxAudio setObject:result forKey:@"packetsReceived"];
    
    
    result = [self toString:_rxAudiogoogAccelerateRate];
    if(result != nil)[rxAudio setObject:result forKey:@"googAccelerateRate"];
    
    result = [self toString:_rxAudiogoogCaptureStartNtpTimeMs];
    if(result != nil)[rxAudio setObject:result forKey:@"googCaptureStartNtpTimeMs"];
    
    result = [self toString:_rxAudiogoogCurrentDelayMs];
    if(result != nil)[rxAudio setObject:result forKey:@"googCurrentDelayMs"];
    
    result = [self toString:_rxAudiogoogDecodingCNG];
    if(result != nil)[rxAudio setObject:result forKey:@"googDecodingCNG"];
    
    result = [self toString:_rxAudiogoogDecodingCTN];
    if(result != nil)[rxAudio setObject:result forKey:@"googDecodingCTN"];
    
    result = [self toString:_rxAudiogoogDecodingCTSG];
    if(result != nil)[rxAudio setObject:result forKey:@"googDecodingCTSG"];
    
    result = [self toString:_rxAudiogoogDecodingNormal];
    if(result != nil)[rxAudio setObject:result forKey:@"googDecodingNormal"];
    
    result = [self toString:_rxAudiogoogDecodingPLC];
    if(result != nil)[rxAudio setObject:result forKey:@"googDecodingPLC"];
    
    result = [self toString:_rxAudiogoogDecodingPLCCNG];
    if(result != nil)[rxAudio setObject:result forKey:@"googDecodingPLCCNG"];
    
    result = [self toString:_rxAudiogoogExpandRate];
    if(result != nil)[rxAudio setObject:result forKey:@"googExpandRate"];
    
    result = [self toString:_rxAudiogoogJitterBufferMs];
    if(result != nil)[rxAudio setObject:result forKey:@"googJitterBufferMs"];
    
    result = [self toString:_rxAudiogoogJitterReceived];
    if(result != nil)[rxAudio setObject:result forKey:@"googJitterReceived"];
    
    result = [self toString:_rxAudiogoogPreemptiveExpandRate];
    if(result != nil)[rxAudio setObject:result forKey:@"googPreemptiveExpandRate"];
    
    result = [self toString:_rxAudiogoogPreferredJitterBufferMs];
    if(result != nil)[rxAudio setObject:result forKey:@"googPreferredJitterBufferMs"];
    
    result = [self toString:_rxAudiogoogSecondaryDecodedRate];
    if(result != nil)[rxAudio setObject:result forKey:@"googSecondaryDecodedRate"];
    
    result = [self toString:_rxAudiogoogSpeechExpandRate];
    if(result != nil)[rxAudio setObject:result forKey:@"googSpeechExpandRate"];
    
    ///////////////////////////////////////////////////////////////////
    
    result = [self toString:_txVideoBytesSent];
    if(result != nil)[txVideo setObject:result forKey:@"bytesSent"];
    
    result = [self toString:_txVideoEncodeUsagePercent];
    if(result != nil)[txVideo setObject:result forKey:@"googEncodeUsagePercent"];
    
    result = [self toString:_txVideoFrameHeightSent];
    if(result != nil)[txVideo setObject:result forKey:@"googFrameHeightSent"];
    
    result = [self toString:_txVideoFrameRateSent];
    if(result != nil)[txVideo setObject:result forKey:@"googFrameRateSent"];
    
    result = [self toString:_txVideoFrameWidthSent];
    if(result != nil)[txVideo setObject:result forKey:@"googFrameWidthSent"];
    
    result = [self toString:_txVideoRtt];
    if(result != nil)[txVideo setObject:result forKey:@"googRtt"];
    
    result = [self toString:_txVideoPacketsLost];
    if(result != nil)[txVideo setObject:result forKey:@"packetsLost"];
    
    result = [self toString:_txVideoPacketsSent];
    if(result != nil)[txVideo setObject:result forKey:@"packetsSent"];
    
    result = [self toString:_txVideogoogAdaptationChanges];
    if(result != nil)[txVideo setObject:result forKey:@"googAdaptationChanges"];
    
    result = [self toString:_txVideogoogAvgEncodeMs];
    if(result != nil)[txVideo setObject:result forKey:@"googAvgEncodeMs"];
    
        result = [self toString:_txVideogoogFirsReceived];
    if(result != nil)[txVideo setObject:result forKey:@"googFirsReceived"];
    
        result = [self toString:_txVideogoogFrameHeightInput];
    if(result != nil)[txVideo setObject:result forKey:@"googFrameHeightInput"];
    
        result = [self toString:_txVideogoogFrameRateInput];
    if(result != nil)[txVideo setObject:result forKey:@"googFrameRateInput"];
    
    result = [self toString:_txVideogoogFrameWidthInput];
    if(result != nil)[txVideo setObject:result forKey:@"googFrameWidthInput"];
    
    result = [self toString:_txVideogoogNacksReceived];
    if(result != nil)[txVideo setObject:result forKey:@"googNacksReceived"];
    
    result = [self toString:_txVideogoogPlisReceived];
    if(result != nil)[txVideo setObject:result forKey:@"googPlisReceived"];
    
    ///////////////////////////////////////////////////////////////////
    
    result = [self toString:_txAudioInputLevel];
    if(result != nil)[txAudio setObject:result forKey:@"audioInputLevel"];
    
    result = [self toString:_txAudioBytesSent];
    if(result != nil)[txAudio setObject:result forKey:@"bytesSent"];
    
    result = [self toString:_txAudioPacketsLost];
    if(result != nil)[txAudio setObject:result forKey:@"packetsLost"];
    
    result = [self toString:_txAudioPacketsSent];
    if(result != nil)[txAudio setObject:result forKey:@"packetsSent"];
    
    result = [self toString:_txAudiogoogEchoCancellationQualityMin];
    if(result != nil)[txAudio setObject:result forKey:@"googEchoCancellationQualityMin"];
    
    result = [self toString:_txAudiogoogEchoCancellationEchoDelayMedian];
    if(result != nil)[txAudio setObject:result forKey:@"googEchoCancellationEchoDelayMedian"];
    
    result = [self toString:_txAudiogoogEchoCancellationEchoDelayStdDev];
    if(result != nil)[txAudio setObject:result forKey:@"googEchoCancellationEchoDelayStdDev"];
    
    result = [self toString:_txAudiogoogEchoCancellationReturnLoss];
    if(result != nil)[txAudio setObject:result forKey:@"googEchoCancellationReturnLoss"];
    
    result = [self toString:_txAudiogoogEchoCancellationReturnLossEnhancement];
    if(result != nil)[txAudio setObject:result forKey:@"googEchoCancellationReturnLossEnhancement"];
    
    result = [self toString:_txAudiogoogJitterReceived];
    if(result != nil)[txAudio setObject:result forKey:@"googJitterReceived"];
    
    result = [self toString:_txAudiogoogRtt];
    if(result != nil)[txAudio setObject:result forKey:@"googRtt"];
    
    
    
    

    

    
    
    ///////////////////////////////////////////////////////////////////
    
    [timeseries setObject:general forKey:@"General"];
    [timeseries setObject:rxVideo forKey:@"rxVideo"];
    [timeseries setObject:rxAudio forKey:@"rxAudio"];
    [timeseries setObject:txVideo forKey:@"txVideo"];
    [timeseries setObject:txAudio forKey:@"txAudio"];
    
    return timeseries;
    
    
}



@end
