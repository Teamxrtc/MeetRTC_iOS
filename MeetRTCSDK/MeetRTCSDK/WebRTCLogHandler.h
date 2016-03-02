//
//  WebRTCLogHandler.h
//  meet-webrtc-sdk
//
//  Created by Pankaj on 06/02/15.
//  Copyright 2014 Comcast Cable Communications Management, LLC.
//

#ifndef meet_webrtc_sdk_WebRTCLogHandler_h
#define meet_webrtc_sdk_WebRTCLogHandler_h


#endif


@interface WebRTCLogHandler : NSObject

typedef enum {
    SENSITIVE = 0,
    VERBOSE   = 1,
    INFO      = 2,
    WARN      = 3,
    ERROR     = 4,
    _DEBUG    = 5
}Log;

+(void)logMessage:(NSString*)_filename logContent:(NSString*)_msg;
+(void)logMessage:(NSString*)_filename logContent:(NSString*)_msg logType:(NSInteger)_type;

@end