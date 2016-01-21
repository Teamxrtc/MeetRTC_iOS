//
//  XMPPRayo.m
//  meet-webrtc-sdk
//
//  Created by Vamsi on 4/22/15.
//  Copyright 2014 Comcast Cable Communications Management, LLC.
//

#import "XMPPRayo.h"

@implementation XMPPRayo

+ (XMPPIQ *)dial:(NSString*)to from:(NSString*)from roomName:(NSString*)roomName roomPass:(NSString*)roomPass target:(NSString*)target
{
    XMPPIQ *xmpp;
    
    NSXMLElement *dialElement = [NSXMLElement elementWithName:@"dial"];
    [dialElement addAttributeWithName:@"xmlns" stringValue:RAYO_XMLNS];
    [dialElement addAttributeWithName:@"to" stringValue:to];
    [dialElement addAttributeWithName:@"from" stringValue:from];
    
    NSXMLElement *headerElement = [NSXMLElement elementWithName:@"header"];
    [headerElement addAttributeWithName:@"name" stringValue:@"JvbRoomName"];
    [headerElement addAttributeWithName:@"value" stringValue:roomName];
    
    [dialElement addChild:headerElement];
    
    if ([roomPass isEqual:@""] && roomPass.length)
    {
        NSXMLElement *passElement = [NSXMLElement elementWithName:@"header"];
        [passElement addAttributeWithName:@"name" stringValue:@"JvbRoomPassword"];
        [passElement addAttributeWithName:@"value" stringValue:roomPass];
        
        [dialElement addChild:passElement];
    }
    
    // New DNS related changes
    //XMPPJID *focusmucjid = [XMPPJID jidWithString:@"callcontrol.focus.xrtc.me"];
    
    /*NSMutableString *focusmucjid = [[NSMutableString alloc]init];
    [focusmucjid appendString:@"callcontrol."];
    [focusmucjid appendString:target];*/
    
    NSString *focusmucjid = target;
    focusmucjid = [focusmucjid stringByReplacingOccurrencesOfString:@"xmpp" withString:@"callcontrol"];
    
    /*NSMutableString *focusmucjid = [[NSMutableString alloc]init];
    [focusmucjid appendString:roomName];
    [focusmucjid appendString:@"/focus"];*/
    
    XMPPJID *targetJid = [XMPPJID jidWithString:focusmucjid];
    
    xmpp  = [[XMPPIQ alloc]initWithType:@"set" to:targetJid elementID:nil child:[dialElement copy]];
    
    return xmpp;

}

+ (XMPPIQ *)hangup
{
    XMPPIQ *xmpp;
    
    NSXMLElement *dialElement = [NSXMLElement elementWithName:@"hangup"];
    [dialElement addAttributeWithName:@"xmlns" stringValue:RAYO_XMLNS];
    
    xmpp  = [[XMPPIQ alloc]initWithType:@"set" to:[XMPPJID jidWithString:@""] elementID:nil child:[dialElement copy]];
    
    return xmpp;
  
}

@end

