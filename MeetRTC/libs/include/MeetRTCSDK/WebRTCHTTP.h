//
//  WebRTCHTTP.h
//  meet-webrtc-sdk
//
//  Created by Pankaj on 05/08/14.
//  Copyright 2014 Comcast Cable Communications Management, LLC.
//

#import <Foundation/Foundation.h>

@protocol WebRTCHTTPDelegate <NSObject>

- (void) onIceServer:(NSDictionary*) msg;
- (void) onHTTPError:(NSString*)error errorCode:(NSInteger)code;
- (void) startSignalingServer:(NSDictionary*) websocketdata iceserverdata:(NSDictionary*)iceserverdata;
//xmpp create room

- (void) createXMPPConnection:(NSString*)mucid;
@end

@interface WebRTCHTTP : NSObject <NSURLConnectionDelegate>
@property (nonatomic,assign) id<WebRTCHTTPDelegate> delegate;
@property (nonatomic) NSString* url;
@property (nonatomic) NSString* tokenStr;

-(id)initWithDefaultValue:(NSString*)endPointURL _token:(NSData *)token;
-(void)sendResourceRequest;
-(void)sendCreateJoinRoomRequest:(NSDictionary*)requestPayload _requestHeaders:(NSDictionary*)requestHeaders;
-(void)End;

@end
