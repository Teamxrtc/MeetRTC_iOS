//
//  WebRTCStats.m
//  meet-webrtc-sdk
//
//  Created by Pankaj on 16/07/14.
//  Copyright 2014 Comcast Cable Communications Management, LLC.
//

#import "WebRTCStatsCollector.h"
#import "WebRTCStatGroup.h"
#import "WebRTCJSON.h"
#import "WebRTCLogHandler.h"
#import "WebRTCLogging.h"

@implementation WebRTCStatsCollector

@synthesize dateFormatter = _dateFormatter;
@synthesize metaData = _metaData;
@synthesize errorLog = _errorLog;
@synthesize callLog = _callLog;

NSString* const TAG7 = @"WebRTCStatsCollector";

-(id)initWithDefaultValue:(NSMutableDictionary*)metaData _appdelegate:(id<WebRTCStatsCollectorDelegate>)_appdelegate
{
    self = [super init];
    if (self!=nil) {
        self->setup = [[WebRTCStatGroup alloc]init];
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'.000'";
        _callLog = [[NSMutableArray alloc]init];
        _metaData = metaData;
        sessions = [[NSMutableDictionary alloc]init];
        self.delegate = _appdelegate;
        [self notifyApplication:@"meta" _value:_metaData];
    }
    return self;
}

-(void)writeMeta:(NSString*)metaKey _values:(NSString*)value
{
    [_metaData setValue:value forKey:metaKey];
    
}
-(void)startMetric:(NSString*)statName
{
    [setup startMetric:statName];
}

-(void)stopMetric:(NSString*)statName
{
    [setup stopMetric:statName];
    [self notifyApplication:@"setup" _value:[setup getAllStats]];
}

-(void)storeReaccuring:(NSString*)metaData _values:(NSDictionary*)values
{
    if(![metaData compare:@"streamInfo"])
    [values setValue:[_metaData objectForKey:@"NetworkType"] forKey:@"Network"];
    [setup storeReaccuring:metaData _values:values];
    [self notifyApplication:@"setup" _value:[setup getAllStats]];
}


-(void)startMetric:(WebRTCSession*)session _statName:(NSString*)statName
{
    WebRTCStatGroup* stats = [self getSessionStats:session];
    [stats startMetric:statName];
    [self saveStats:session _stats:stats];
}

-(void)stopMetric:(WebRTCSession*)session _statName:(NSString*)statName
{
    WebRTCStatGroup* stats = [self getSessionStats:session];
    [stats stopMetric:statName];

    NSMutableDictionary* sessObj = [[NSMutableDictionary alloc]init];
    [sessObj setValue:[stats getAllStats] forKey:[session getClientSessionId]];
    
    if ([sessObj count] != 0)
    {
        [self notifyApplication:@"sessions" _value:sessObj];
    }
    
}

-(void)storeReaccuring:(WebRTCSession*)session _statName:(NSString*)statName _values:(NSDictionary*)values
{
    WebRTCStatGroup* stats = [self getSessionStats:session];
    [stats storeReaccuring:statName _values:values];
    [self saveStats:session _stats:stats];
}

-(void)storeError:(NSString*)reason
{
    _errorLog = [[NSMutableDictionary alloc]init];
    //NSError* error;
    //NSDictionary* data =[WebRTCJSONSerialization JSONObjectWithData:_errorLog options:kNilOptions error:&error];
    
    //NSMutableDictionary* mdata = [NSMutableDictionary dictionaryWithDictionary:data];
    [_errorLog setValue:reason forKey:@"reason"];
    
    [self notifyApplication:@"errorLog" _value:_errorLog];
}

-(void)storeCallLogMessage:(NSString*)msg _msgType:(NSString*)msgType
{
    NSDate* now = [[NSDate alloc]init];
    NSMutableDictionary* log = [[NSMutableDictionary alloc]init];
    [log setValue:[_dateFormatter stringFromDate:now] forKey:@"time"];
    [log setValue:msgType forKey:@"name"];
    [log setValue:msg forKey:@"contents"];
    //[_callLog addObject:log];
    
    [self notifyApplication:@"callLog" _value:log];
    
}

/*-(NSString*)toPrettyString
{
    NSString* convertString =[NSString stringWithFormat:@"Stats:  %@", [self toJSON:true]];
    return convertString;
}

-(NSDictionary*)toJSON
{
    return [self toJSON:_omitCallLogInReport];
}

-(NSDictionary*)toJSON:(BOOL)omitLog
{
    NSMutableDictionary* sessObj = [[NSMutableDictionary alloc]init];
    for(id key in sessions) {
        WebRTCStatGroup* stats = [sessions objectForKey:key];
        [sessObj setValue:[stats getAllStats] forKey:key];
    }
    
    NSMutableDictionary* whole = [[NSMutableDictionary alloc]init];
    if ([sessObj count] != 0)
    {
        [whole setValue:sessObj forKey:@"sessions"];
    }

    [whole setValue:[setup getAllStats] forKey:@"setup"];
    [whole setValue:_metaData forKey:@"meta"];
    if(_errorLog)
    {
        [whole setValue:_errorLog forKey:@"error"];
    }
    
    if(!omitLog)
    {
        [whole setValue:_callLog forKey:@"callLog"];
    }
    return whole;
}*/

-(WebRTCStatGroup*)getSessionStats:(WebRTCSession*) session
{
    if([session getClientSessionId] == nil)
    {
        LogInfo(@"Session does not have sessionId can not log stat");
        return nil;
    }
    
    WebRTCStatGroup* stats;
    if([sessions objectForKey:[session getClientSessionId]])
    {
        stats = [sessions objectForKey:[session getClientSessionId]];
    }
    else
    {
        stats = [[WebRTCStatGroup alloc]init];
    }
    return stats;
}
-(void)saveStats:(WebRTCSession*) session _stats:(WebRTCStatGroup*)stats
{
    [sessions setObject:stats forKey:[session getClientSessionId]];
}


-(void)notifyApplication:(NSString*)key _value:(id)value
{
    //NSMutableDictionary *stat = [[NSMutableDictionary alloc]init];
    //[stat setValue:value forKey:key];
    
    //Sending stats notification to the application which is registered to statsNotification
    //[[NSNotificationCenter defaultCenter] postNotificationName:@"statsNotification" object:stat];
    
}

-(NSMutableDictionary*)streamInfo{
   
    return [setup streamInfo];
}

@end
