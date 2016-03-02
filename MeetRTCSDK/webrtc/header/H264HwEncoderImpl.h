//
//  H264HwEncoderImpl.h
//  h264v1
//
//  Created by Ganvir, Manish on 3/31/15.
//  Copyright 2014 Comcast Cable Communications Management, LLC.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
//#include "talk/app/webrtc/peerconnection_fake.h"


static void release_callback(void *releaseRefCon,
                             const void *dataPtr,
                             size_t dataSize,
                             size_t numberOfPlanes,
                             const void *planeAddresses[]);


@protocol H264HwEncoderImplDelegate <NSObject>

- (void)gotSpsPps:(NSData*)sps pps:(NSData*)pps;
- (void)gotEncodedData:(NSData*)data isKeyFrame:(BOOL)isKeyFrame;

@end
@interface H264HwEncoderImpl : NSObject 

- (id)init;
- (void) initWithConfiguration;
- (void) initEncode:(int)width  height:(int)height;
- (void) changeResolution:(int)width  height:(int)height;
- (void) End;
- (void) encode:(void* [])planes width:(size_t [])width height:(size_t [])height bytesperrow:(size_t [])bytesperrow planesSize:(size_t [])planesSize;
- (void) decode:(uint8_t *)frame frameSize:(int)frameSize isIFrame:(bool)isIFrame width:(int)width  height:(int)height;

@property (weak, nonatomic) NSString *error;
@property (weak, nonatomic) id<H264HwEncoderImplDelegate> delegate;

@end
