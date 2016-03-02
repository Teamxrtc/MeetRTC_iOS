//
//  WebRTCError.h
//
//  Created by Pankaj on 26/06/14.
//  Copyright 2014 Comcast Cable Communications Management, LLC.
//

#ifndef meet_WebRTCError_h
#define meet_WebRTCError_h

//Error Domain
extern NSString* const General;
extern NSString* const Socket;
extern NSString* const Stream;
extern NSString* const Session;


typedef enum errorcode
{
    //General
    OK_NO_ERROR = 0,
    ERR_INVALID_CREDENTIALS = -101,
    ERR_ENDPOINT_URL = -102,
    ERR_INCORRECT_PARAMS = -103,
    ERR_INCORRECT_STATE = -104,
    
    //Socket
    ERR_NO_WEBSOCKET_SUPPORT = -201,
    ERR_WEBSOCKET_DISCONNECT = -202,
    ERR_TRANSPORT_ERROR = -203,
    
    //Stream
    ERR_INVALID_CONSTRAINTS = -301,
    ERR_CAMERA_NOT_FOUND = -302,
    ERR_VIDEO_CAPTURE = -303,
    ERR_LOCAL_TRACK = -304,
    ERR_PC_FACTORY = -305,
    ERR_RECORDING = -306,
    
    //Session
    ERR_INVALID_SDP = -401,
    ERR_TARGET_NO_REPLY = -402,
    ERR_ICE_CONNECTION_ERROR = -403,
    ERR_ICE_CONNECTION_TIMEOUT = -404,
    ERR_UNSPECIFIED_PEERCONNECTION = -405,
    ERR_REG_FAILURE = -406,
    ERR_REMOTE_PARTY_NOT_EXIST = -407,
    ERR_UNKNOWN_SERVER_MSG = -408,
    ERR_REMOTE_VIDEO = -409,
    ERR_PEER_CONNECTION = -410,
    ERR_ICE_CANDIDATE = -411,
    ERR_REMOTE_UNREACHABLE = -412,
    ERR_DATA_SEND = -413,
    ERR_DATA_RECEIVED = -414,
    ERR_INCORRECT_URL = -415,
    ERR_RTCG_ERROR = -499,  //Unknown RTCG error
    
    //Stack
    ERR_UNKNOWN_CLIENT = -501,
    
	//HTTP
    ERR_HTTP_CONNECTION_FAILED = -601,
    
    //Channel
    ERR_CREATECHANNEL_FAILED = -701
} ERRCODE;


#endif
