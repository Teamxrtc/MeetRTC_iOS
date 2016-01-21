//
//  WebRTCConsoleLogger.m
//  meet-webrtc-sdk
//
//  Created by Pankaj on 06/04/15.
//  Copyright 2014 Comcast Cable Communications Management, LLC.
//

#import <Foundation/Foundation.h>
#import "WebRTCConsoleLogger.h"

@implementation WebRTCConsoleLogger

static WebRTCConsoleLogger *sharedInstance;

+ (void)initialize
{
    static BOOL initialized = NO;
    if (!initialized)
    {
        initialized = YES;
        
        sharedInstance = [[[self class] alloc] init];
    }
}

+ (instancetype)sharedInstance
{
    return sharedInstance;
}

- (id)init
{
    if (sharedInstance != nil)
    {
        return nil;
    }
    
    if ((self = [super init]))
    {
        
    }
    return self;
}

- (void)logMessage:(LogMessage *)logMessage
{
        NSString *logMsg = logMessage->logMsg;
        int currentLogLevel = logMessage->level;
        int _defaultLogLevel = logMessage->_defaultLogLevel;
        //const char *msg1 = [logMsg UTF8String];
        
        if(currentLogLevel <= _defaultLogLevel){
            
            //NSLog(@"%s",msg1);
            [_delegate onLogging:logMsg];
        }
}

@end

