//  WebRTCJSON.m
//  meet-webrtc-sdk
//
//  Created by Pankaj on 26/08/14.
//  Copyright 2014 Comcast Cable Communications Management, LLC.

#import "WebRTCJSON.h"

@interface NSObject (WebRTCJSONSerialization)

- (id)JSONObjectWithData:(NSData *)data
                 options:(NSJSONReadingOptions)opt
                   error:(NSError **)error;
- (NSData *)dataWithJSONObject:(id)obj
                       options:(NSJSONWritingOptions)opt
                         error:(NSError **)error;


@end

@implementation WebRTCJSONSerialization

+ (id)JSONObjectWithData:(NSData *)data
                 options:(NSJSONReadingOptions)opt
                   error:(NSError **)error {
    
//    NSString *strData = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:opt error:error];

    return dict;
}
+ (NSData *)dataWithJSONObject:(id)obj
                       options:(NSJSONWritingOptions)opt
                         error:(NSError **)error {
    // Get the data from NSJSONSerialization
    /*NSData *lData = [NSJSONSerialization dataWithJSONObject:obj options:opt error:error];
    
    // NSJSONSerialization would have added extra characters in URL
    NSString *datastring = [[NSString alloc] initWithData:lData encoding:NSUTF8StringEncoding];
   // NSLog(@"String before %@", datastring);
    datastring = [datastring stringByReplacingOccurrencesOfString:@"\\/" withString:@"/"];
    //NSLog(@"String after %@", datastring);

    lData = [datastring dataUsingEncoding:NSUTF8StringEncoding];
    return lData;*/
    return [NSJSONSerialization dataWithJSONObject:obj options:opt error:error];
}

@end
