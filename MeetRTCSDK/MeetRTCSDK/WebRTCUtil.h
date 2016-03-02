//
//  WebRTCUtil.h
//  meet-webrtc-sdk
//
//  Created by Pankaj on 26/08/14.
//  Copyright 2014 Comcast Cable Communications Management, LLC.
//

#ifndef meet_WebRTCUtil_h
#define meet_WebRTCUtil_h
typedef enum
{
    outgoing,
    incoming,
    dataoutgoing,
    dataincoming
}WebrtcSessionCallTypes;


typedef struct
{
    BOOL EnableDataSend;
    BOOL EnableDataRecv;
    BOOL EnableVideoSend;
    BOOL EnableVideoRecv;
    BOOL EnableAudioSend;
    BOOL EnableAudioRecv;
    
    BOOL EnableOneWay;
    BOOL EnableBroadcast;
    
}WebrtcSessionOptions_t;



#endif
