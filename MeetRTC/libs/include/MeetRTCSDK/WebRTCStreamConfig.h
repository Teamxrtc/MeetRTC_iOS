//
//  WebRTCStreamConfig.h
//  meet-webrtc-sdk
//
//  Created by Pankaj on 26/08/14.
//  Copyright 2014 Comcast Cable Communications Management, LLC.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "RTCSessionDescriptionDelegate.h"
#import "RTCPeerConnectionFactory.h"
#import "RTCPeerConnectionDelegate.h"
#import "RTCVideoTrack.h"
#import "RTCICEServer.h"
#import "RTCMediaStream.h"

//Define default values
#define DEFAULT_HMIN_RESOLUTION 640
#define DEFAULT_VMIN_RESOLUTION 480
#define DEFAULT_HMAX_RESOLUTION 1920
#define DEFAULT_VMAX_RESOLUTION 1080

#define DEFAULT_MINBLOCKS_RESOLUTION 6758400
#define DEFAULT_MAXBLOCKS_RESOLUTION 62208000

#define DEFAULT_VIDEO_MAXBITRATE 4096
#define DEFAULT_VIDEO_INITIALBITRATE 1500
#define DEFAULT_AUDIO_PREFERBITRATE 60
#define DEFAULT_VIDEO_PREFERBITRATE 4096

#define DEFAULT_MIN_FRAMERATE 22
#define DEFAULT_MAX_FRAMERATE 30

#define FHD_MIN_BLOCKS  45619200        //1920*1080  iPhone 6 series
#define FHD_MAX_BLOCKS  62208000
#define HD_MIN_BLOCKS   20275200        //1280*720   iPhone 5 series
#define HD_MAX_BLOCKS   27648000
#define VGA_MIN_BLOCKS  6758400         //640*480    iPhone 4 series 
#define VGA_MAX_BLOCKS  9216000
#define QVGA_MIN_BLOCKS 1689600         //320*240
#define QVGA_MAX_BLOCKS 2304000

#define DEFAULT_FILESIZE 500 //Default recorded file size in MB

typedef enum
{
    CAM_TYPE_FRONT,
    CAM_TYPE_BACK,
    CAM_TYPE_AUTO,
    CAM_TYPE_NONE
}WebRTCCamera_type_e;

typedef enum
{
    WEBRTC_RECORD_LOW,
    WEBRTC_RECORD_MEDIUM,
    WEBRTC_RECORD_HIGH
}WebRTCRecord_quality_e;


@interface WebRTCStreamConfig : NSObject

@property (nonatomic)WebRTCCamera_type_e camType;
@property (nonatomic)NSInteger hMinResolution;
@property (nonatomic)NSInteger vMinResolution;
@property (nonatomic)NSInteger hMaxResolution;
@property (nonatomic)NSInteger vMaxResolution;

@property (nonatomic)NSInteger videoMaxBitrate;
@property (nonatomic)NSInteger videoInitialBitrate;
@property (nonatomic)NSInteger audioPreferBitrate;
@property (nonatomic)NSInteger videoPreferBitrate;
@property (nonatomic)BOOL isFlipCamera;

@property (nonatomic)NSInteger minFrameRate;
@property (nonatomic)NSInteger maxFrameRate;
@property (nonatomic)NSInteger minHeight;
@property (nonatomic)NSInteger maxHeight;
@property (nonatomic)NSInteger minWidth;
@property (nonatomic)NSInteger maxWidth;
@property (nonatomic)NSInteger minBlocks;
@property (nonatomic)NSInteger maxBlocks;


//Recoding related configuration
@property (nonatomic)NSString* recordedFilePath;
@property (nonatomic)NSInteger recordingQuality;
@property (nonatomic)NSInteger recordedFileSizeThreshold; //Size will be in MB

// To enable/disable 4:3 video aspect ratio
@property (nonatomic)BOOL aspectRatio43;

- (id)init;
- (void)setMediaConstraints:(int)resolution;
@end
