//
//  WebRTCStreamConfig.m
//  meet-webrtc-sdk
//
//  Created by Pankaj on 26/08/14.
//  Copyright 2014 Comcast Cable Communications Management, LLC.
//

#import "WebRTCStreamConfig.h"
#import "WebRTCSessionConfig.h"
#import "WebRTCLogHandler.h"
#import "WebRTCLogging.h"

@implementation WebRTCStreamConfig



@synthesize hMinResolution = _hMinResolution;
@synthesize vMinResolution = _vMinResolution;
@synthesize hMaxResolution = _hMaxResolution;
@synthesize vMaxResolution = _vMaxResolution;

@synthesize videoMaxBitrate = _videoMaxBitrate;
@synthesize videoInitialBitrate = _videoInitialBitrate;
@synthesize audioPreferBitrate = _audioPreferBitrate;
@synthesize videoPreferBitrate = _videoPreferBitrate;
@synthesize isFlipCamera = _isFlipCamera;

@synthesize minFrameRate = _minFrameRate;
@synthesize maxFrameRate = _maxFrameRate;
@synthesize minHeight = _minHeight;
@synthesize maxHeight = _maxHeight;
@synthesize minWidth = _minWidth;
@synthesize maxWidth = _maxWidth;
@synthesize minBlocks = _minBlocks;
@synthesize maxBlocks = _maxBlocks;
@synthesize recordedFilePath = _recordedFilePath;
@synthesize recordingQuality = _recordingQuality;
@synthesize recordedFileSizeThreshold = _recordedFileSizeThreshold;
@synthesize aspectRatio43 = _aspectRatio43;

NSString* const TAG = @"WebRTCStreamConfig";

- (id)init
{
    self = [super init];
    if (self!=nil)
    {
        _camType = CAM_TYPE_FRONT;
        _hMinResolution = DEFAULT_HMIN_RESOLUTION;
        _vMinResolution = DEFAULT_VMIN_RESOLUTION;
        _hMaxResolution = DEFAULT_HMAX_RESOLUTION;
        _vMaxResolution = DEFAULT_VMAX_RESOLUTION;
        _minFrameRate = DEFAULT_MIN_FRAMERATE;
        _maxFrameRate = DEFAULT_MAX_FRAMERATE;
        _minBlocks = DEFAULT_MINBLOCKS_RESOLUTION;
        _maxBlocks = DEFAULT_MAXBLOCKS_RESOLUTION;
        _isFlipCamera = false;
		_recordedFilePath = nil; //Need  to set the default file path
        _recordingQuality = WEBRTC_RECORD_MEDIUM;
        _recordedFileSizeThreshold = DEFAULT_FILESIZE;
        _aspectRatio43 = false;
    }
    return self;
}

- (void)setMediaConstraints:(int)resolution
{
   LogInfo(@"Inside setMediaConstraints:: resolution= %d", resolution);
  
   switch (resolution)
   {
    case QVGA:
        
        _minFrameRate = 22;
        _maxFrameRate = 30;
        _hMinResolution = 320;
        _hMaxResolution = 320;
        _vMinResolution = 240;
        _vMaxResolution = 240;
        _minBlocks = QVGA_MIN_BLOCKS;
        _maxBlocks = QVGA_MAX_BLOCKS;
        break;
        
    case VGA:  //SD
        
        _minFrameRate = 22;
        _maxFrameRate = 30;
        _hMinResolution = 640;
        _hMaxResolution = 640;
        _vMinResolution = 480;
        _vMaxResolution = 480;
        _minBlocks = VGA_MIN_BLOCKS;
        _maxBlocks = VGA_MAX_BLOCKS;
        break;

    case HD:
        
        _minFrameRate = 22;
        _maxFrameRate = 30;
        _hMinResolution = 1280;
        _hMaxResolution = 1280;
        _vMinResolution = 720;
        _vMaxResolution = 720;
        _minBlocks = HD_MIN_BLOCKS;
        _maxBlocks = HD_MAX_BLOCKS;
        break;
        
    case FHD:
        
        _minFrameRate = 22;
        _maxFrameRate = 30;
        _hMinResolution = 1920;
        _hMaxResolution = 1920;
        _vMinResolution = 1080;
        _vMaxResolution = 1080;
        _minBlocks = FHD_MIN_BLOCKS;
        _maxBlocks = FHD_MAX_BLOCKS;
        break;
    
    default:
        
        _minFrameRate = 22;
        _maxFrameRate = 30;
        _hMinResolution = DEFAULT_HMIN_RESOLUTION;
        _hMaxResolution = DEFAULT_VMIN_RESOLUTION;
        _vMinResolution = DEFAULT_HMAX_RESOLUTION;
        _vMaxResolution = DEFAULT_VMAX_RESOLUTION;
        _minBlocks = DEFAULT_MINBLOCKS_RESOLUTION;
        _maxBlocks = DEFAULT_MAXBLOCKS_RESOLUTION;
        break;
    }
}

@end
