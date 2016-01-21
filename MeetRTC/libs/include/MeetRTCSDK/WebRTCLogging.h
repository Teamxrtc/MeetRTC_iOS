//
//  WebRTCLogging.h
//  meet-webrtc-sdk
//
//  Created by Pankaj on 06/04/15.
//  Copyright 2014 Comcast Cable Communications Management, LLC.
//

#import <Foundation/Foundation.h>

#ifndef LOG_LEVEL_DEF
#define LOG_LEVEL_DEF logLevel
#endif

@class LogMessage;

@protocol WebRTCLogger;


#define LOG_MACRO(lvl,frmt, ...) \
[WebRTCLogging log:lvl                                                        \
            format:(frmt), ##__VA_ARGS__]

#define LOG_LEVEL_OFF       0
#define LOG_LEVEL_ERROR     1
#define LOG_LEVEL_WARN      2
#define LOG_LEVEL_INFO      3
#define LOG_LEVEL_DEBUG     4
#define LOG_LEVEL_VERBOSE   5
#define LOG_LEVEL_SENSITIVE 6

#define LogError(frmt, ...)   LOG_MACRO(LOG_LEVEL_ERROR,frmt, ##__VA_ARGS__)
#define LogWarn(frmt, ...)    LOG_MACRO(LOG_LEVEL_WARN,frmt, ##__VA_ARGS__)
#define LogInfo(frmt, ...)    LOG_MACRO(LOG_LEVEL_INFO,frmt, ##__VA_ARGS__)
#define LogDebug(frmt, ...)   LOG_MACRO(LOG_LEVEL_DEBUG,frmt, ##__VA_ARGS__)
#define LogVerbose(frmt, ...) LOG_MACRO(LOG_LEVEL_VERBOSE,frmt, ##__VA_ARGS__)
#define LogSensitive(frmt, ...) LOG_MACRO(LOG_LEVEL_VERBOSE,frmt, ##__VA_ARGS__)


@protocol WebRTCLogDelegate <NSObject>

-(void)onLogging:(NSString *)msg;

@end

@interface WebRTCLogging : NSObject

+ (void)log:(int)level
     format:(NSString *)format, ...;
+ (void)addLogger:(id <WebRTCLogger>)logger;
+(void)setLogLevel:(int)logLevel;

@end


@protocol WebRTCLogger <NSObject>
@required

- (void)logMessage:(LogMessage *)logMessage;

@end



@interface LogMessage : NSObject
{

@public
    int level;
    int _defaultLogLevel;
    NSString *logMsg;
 
}

- (instancetype)initWithLogMsg:(NSString *)logMsg
                  currentLevel:(int)level
               defaultLogLevel:(int)logLevel;

@end











