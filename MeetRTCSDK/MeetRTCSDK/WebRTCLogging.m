//
//  WebRTCLogging.m
//  meet-webrtc-sdk
//
//  Created by Pankaj on 06/04/15.
//  Copyright 2014 Comcast Cable Communications Management, LLC.
//

#import <Foundation/Foundation.h>
#import "WebRTCLogging.h"

#import <pthread.h>
#if TARGET_OS_IPHONE
#import <UIKit/UIDevice.h>
#endif
int _defaultLogLevel;

@interface LoggerNode : NSObject {
@public
    id <WebRTCLogger> logger;
}

+ (LoggerNode *)nodeWithLogger:(id <WebRTCLogger>)logger;

@end

@implementation WebRTCLogging


static NSMutableArray *loggers;

+ (void)initialize
{
    static BOOL initialized = NO;
    if (!initialized)
    {
        initialized = YES;
        
        loggers = [[NSMutableArray alloc] initWithCapacity:3];
        
    }
}


+ (void)addLogger:(id <WebRTCLogger>)logger
{
    if (logger == nil) return;

    if([loggers count] == 0){
        
        LoggerNode *loggerNode =[LoggerNode nodeWithLogger:logger];
        [loggers addObject:loggerNode];
        
    }
    //Enable this if needed multiple logging support like file, console etc
   /* else
     {
         bool found = false;
         for (LoggerNode *loggerNode in loggers)
            {
                if([loggerNode->logger class] == [logger class])
                {
                    found = true;
                    break;
                }
            }
         if (!found)
         {
             LoggerNode *loggerNode =[LoggerNode nodeWithLogger:logger];
             [loggers addObject:loggerNode];
         }
     }*/
    
}

+(void)setLogLevel:(int)logLevel
{
    _defaultLogLevel = logLevel;
}

+ (void)queueLogMessage:(LogMessage *)logMessage
{
    for (LoggerNode *loggerNode in loggers)
    {
        [loggerNode->logger logMessage:logMessage];
    }
}



+(void)log:(int)level
    format:(NSString *)format, ...

{
    va_list args;
    if (format)
    {
        va_start(args, format);
        
        NSString *logMsg = [[NSString alloc] initWithFormat:format arguments:args];
        LogMessage *logMessage = [[LogMessage alloc] initWithLogMsg:logMsg
                                                       currentLevel:level
                                                    defaultLogLevel:_defaultLogLevel];
        
        
        [self queueLogMessage:logMessage];
        
        va_end(args);
    }
}

@end



@implementation LoggerNode

- (instancetype)initWithLogger:(id <WebRTCLogger>)aLogger{
    if ((self = [super init]))
    {
        logger = aLogger;
    }
     return self;
}

+ (LoggerNode *)nodeWithLogger:(id <WebRTCLogger>)logger{
    
    return [[LoggerNode alloc] initWithLogger:logger];
}

@end




@implementation LogMessage


- (instancetype)initWithLogMsg:(NSString *)msg
                  currentLevel:(int)level1
               defaultLogLevel:(int)logLevel
{
    logMsg = msg;
    level  = level1;
    _defaultLogLevel = logLevel;

    return self;
}

@end


    






















