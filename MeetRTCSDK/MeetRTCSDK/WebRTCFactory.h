//
//  WebRTCFactory.h
//
//  Created by Ganvir, Manish on 5/29/14.
//  Copyright 2014 Comcast Cable Communications Management, LLC.
//

#import <Foundation/Foundation.h>
#import "RTCPeerConnectionFactory.h"

@interface WebRTCFactory : NSObject

// Call this to get access to the factory
+ (RTCPeerConnectionFactory *)getPeerConnectionFactory;

// Call this to shutdown the factory
+ (void)DestroyPeerConnectionFactory;
@end
