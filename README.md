##MeetRTC iOS

###Description

A WebRTC based video conferencing application for iOS compatible with the Jitsi-Meet Browser application, https://github.com/jitsi/jitsi-meet

###Overview

This project contains the following 

* Reference app which shows how to use the MeetRTC iOS SDK 
* MeetRTC iOS SDK code

###How to Use

Build MeetRTCSDK to build MeetRTCSDK static library.

The SDK output i.e. libMeetRTCSDK.a should be copied to MeetRTC/libs folder.

Build MeetRTC xcode project to produce the MeetRTC iOS Application.

###Features
Supports rendering 5 participants in Jitsi meet conference

###TODO

Current list of TODO items:

* Reorganize SDK library to build a multi-platform iOS Framework build.
* Integrate Cocoapods for 3rd party library dependancies
* Create Cocoapod for MeetRTCSDK library
* DataChannel support
* Dominant speaker support
* Currently XMPPFramework modifications only support XMPP over websocket, need to clean up and properly support full BOSH and TCP
* SDK API that aligns with libjitsimeet javascript API
* Swift API
* UI clean up and feature enhancements


###License and Copyright

Licensed under the Apache License, Version 2.0

Copyright 2016 Comcast Cable Communications Management, LLC

This product includes software developed at Comcast (http://www.comcast.com/).
