//
//  WebRTCConsoleLogger.h
//  meet-webrtc-sdk
//
//  Created by Pankaj on 06/04/15.
//  Copyright 2014 Comcast Cable Communications Management, LLC.
//

#import <Foundation/Foundation.h>
#import "WebRTCLogging.h"

@interface WebRTCConsoleLogger : NSObject<WebRTCLogger>

+ (instancetype)sharedInstance;

@property(nonatomic,assign) id<WebRTCLogDelegate> delegate;

@end