//
//  XMPPJingleSDP.h
//  meet-webrtc-sdk
//
//  Created by Ganvir, Manish (Contractor) on 2/6/15.
//  Copyright 2014 Comcast Cable Communications Management, LLC.
//

#ifndef meet_webrtc_sdk_XMPPJingleSDP_h
#define meet_webrtc_sdk_XMPPJingleSDP_h
#import <Foundation/Foundation.h>
#import "XMPP.h"
#import "XMPPFramework.h"

// Namespace for jingle messages
#define XEP_0166_XMLNS @"urn:xmpp:jingle:1"

@interface XMPPJingleSDPUtil : NSObject
{
    NSMutableArray* session;
    NSMutableArray* media;
    
	NSXMLElement *sdpFprElement;
    NSString *gUfrag;
    NSString *gPwd;
    NSMutableDictionary *oldAVDContent;
}
- (XMPPIQ *)SDPToXMPP:(NSString *)sdp action:(NSString *)action initiator:(XMPPJID *)initiator target:(XMPPJID *)target UID:(NSString *)UID SID:(NSString *)SID;
- (XMPPIQ *)CandidateToXMPP:(NSDictionary *)dict action:(NSString *)action initiator:(XMPPJID *)initiator target:(XMPPJID *)target UID:(NSString *)UID SID:(NSString *)SID;
- (NSXMLElement *)MediaToXMPP:(NSString *)type  data:(NSDictionary *)data target:(XMPPJID *)target UID:(NSString *)UID SID:(NSString *)SID;

- (NSString *)XMPPToSDP:(XMPPIQ *)iq;
- (NSString *)XMPPToSDPNew:(XMPPIQ *)iq;
- (NSString *)XMPPToSDPRemove:(XMPPIQ *)iq;
- (NSString *)XMPPToMsid:(XMPPIQ *)iq;

- (NSDictionary *)XMPPToCandidate:(XMPPIQ *)iq;

- (NSString*)find_line:(NSString*)haystack  needle:(NSString*)needle;
- (NSArray*)find_lines:(NSString*)haystack  needle:(NSString*)needle;
- (NSArray*) parse_mline:(NSString*)line;

- (void) splitSDP:(NSString*)sdp;

@end

#endif
