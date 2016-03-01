//
//  XMPPRayo.h
//  meet-webrtc-sdk
//
//  Created by Vamsi on 4/22/15.
//  Copyright 2014 Comcast Cable Communications Management, LLC.
//

#ifndef meet_webrtc_sdk_XMPPRayo_h
#define meet_webrtc_sdk_XMPPRayo_h

#import <Foundation/Foundation.h>

#import "XMPP.h"
#import "XMPPFramework.h"

#define RAYO_XMLNS @"urn:xmpp:rayo:1"

@interface XMPPRayo : NSObject

+ (XMPPIQ *)dial:(NSString*)to from:(NSString*)from roomName:(NSString*)roomName roomPass:(NSString*)roomPass target:(NSString*)target;
+ (XMPPIQ *)hangup;

+(void) test;

@end

#endif
