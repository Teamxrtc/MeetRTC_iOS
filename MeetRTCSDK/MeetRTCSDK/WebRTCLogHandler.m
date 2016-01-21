//
//  WebRTCLogHandler.m
//  meet-webrtc-sdk
//
//  Created by Pankaj on 06/02/15.
//  Copyright 2014 Comcast Cable Communications Management, LLC.
//

#import <Foundation/Foundation.h>
#import "WebRTCLogHandler.h"

@implementation WebRTCLogHandler

BOOL setDebugLogs = true ;


+(void)logMessage:(NSString*)_filename logContent:(NSString*)_msg{
    
    if (setDebugLogs) {
        
        [self logMessage:_filename logContent:_msg logType:_DEBUG];

        }
    }


+(void)logMessage:(NSString*)_filename logContent:(NSString*)_msg logType:(NSInteger)_type{
    
    switch (_type) {
           
        case SENSITIVE:
            NSLog(@"%@::%@", _filename,_msg);
            break;
            
        case VERBOSE:
            NSLog(@"%@::%@", _filename,_msg);
            break;
            
        case INFO:
            NSLog(@"%@::%@", _filename,_msg);
            break;

        case WARN:
            NSLog(@"%@::%@", _filename,_msg);
            break;
            
        case ERROR:
            NSLog(@"%@::%@", _filename,_msg);
            break;

        case _DEBUG:
            if (setDebugLogs) {
                NSLog(@"%@::%@", _filename,_msg);
                break;
            }
            
        default:
            break;
    }
    
}


@end