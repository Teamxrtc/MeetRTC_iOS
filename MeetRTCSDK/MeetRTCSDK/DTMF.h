//
//  DTMF.h
//  meet-webrtc-sdk
//
//  Created by Pankaj on 10/07/14.
//  Copyright 2014 Comcast Cable Communications Management, LLC
//

#ifndef meet_webrtc_sdk_DTMF_h
#define meet_webrtc_sdk_DTMF_h

typedef enum{
    NUMBER1 ,
    NUMBER2 ,
    NUMBER3 ,
    NUMBER4 ,
    NUMBER5 ,
    NUMBER6 ,
    NUMBER7 ,
    NUMBER8 ,
    NUMBER9 ,
    NUMBER0 ,
    STAR ,
    HASH ,
    LETTERA ,
    LETTERB ,
    LETTERC ,
    LETTERD ,
}Tone;

#define toneValueString(enum) [@[@"1",@"2",@"3",@"4",@"5",@"6",@"7",@"8",@"9",@"0",@"*",@"#",@"A",@"B",@"C",@"D"] objectAtIndex:enum]

#endif
