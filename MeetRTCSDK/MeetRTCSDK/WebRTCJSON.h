//  WebRTCJSON.h
//  meet-webrtc-sdk
//
//  Created by Pankaj on 26/08/14.
//  Copyright 2014 Comcast Cable Communications Management, LLC.
#import <Foundation/Foundation.h>

@interface WebRTCJSONSerialization : NSObject


+ (id)JSONObjectWithData:(NSData *)data
                 options:(NSJSONReadingOptions)opt
                   error:(NSError **)error;
+ (NSData *)dataWithJSONObject:(id)obj
                       options:(NSJSONWritingOptions)opt
                         error:(NSError **)error;
@end
