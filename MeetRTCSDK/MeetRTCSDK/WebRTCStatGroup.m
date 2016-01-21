//
//  WebRTCStatGroup.m
//  meet-webrtc-sdk
//
//  Created by Pankaj on 16/07/14.
//  Copyright 2014 Comcast Cable Communications Management, LLC.
//

#import "WebRTCStatGroup.h"

@implementation WebRTCStatGroup

@synthesize dateFormatter;
-(id)init
{
    self = [super init];
    if (self!=nil) {
        self->stats = [[NSMutableDictionary alloc]init];
        self->streamInfo = [[NSMutableDictionary alloc]init];
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];

        //dateFormatter.dateFormat = @"yyyy-MM-ddTHH:mm:ss";
    }
    return self;
}

-(NSMutableDictionary*)getAllStats
{
    return stats;
}

-(NSMutableDictionary*)getStat:(NSString*)statName
{
    return stats;
}

-(void)startMetric:(NSString*)statName
{
    NSDate* now = [NSDate date];
    
    [self writeStat:statName _key:@"startTime" _value:[dateFormatter stringFromDate:now]];
}

-(void)stopMetric:(NSString*)statName
{
    NSDate* now = [NSDate date];
    NSDate* from=nil;
    from = [[stats objectForKey:statName] valueForKey:@"startTime"];
    if (from != nil)
    {
        [self writeStat:statName _key:@"stopTime" _value:[dateFormatter stringFromDate:now]];
    }
    
}

-(void)storeReaccuring:(NSString*)statName _values:(NSDictionary*)values
{
    if (([statName compare:@"streamInfo"])) {
        [stats setValue:[values objectForKey:statName] forKey:statName];
    }
    else
    {
        NSDate* now = [NSDate date];
        [values setValue:[dateFormatter stringFromDate:now] forKey:@"timestamp"];
        [self writeArrayStat:statName _value:values];
    }
    
}

-(void)writeStat:(NSString*)statName _key:(NSString*)key _value:(NSString*)value
{
    NSMutableDictionary* stat = [stats objectForKey:statName];
    if(!stat)
    {
        stat = [[NSMutableDictionary alloc]init];
    }
    
    [stat setValue:value forKey:key];
    
    if((![statName compare:@"callDuration"]) && (![key compare:@"stopTime"]))
    {
        NSDate* startTime = [dateFormatter dateFromString:[stat objectForKey:@"startTime"]];
        NSDate* stopTime = [dateFormatter dateFromString:[stat objectForKey:@"stopTime"]];
        NSTimeInterval duration = [stopTime timeIntervalSinceDate:startTime];
        [stat setValue:[NSNumber numberWithFloat:duration] forKey:@"duration"];
        [streamInfo setObject:startTime forKey:@"startTime"];
        [streamInfo setObject:stopTime forKey:@"stopTime"];
        [streamInfo setObject:[NSNumber numberWithFloat:duration] forKey:@"duration"];
    }

    [stats setValue:stat forKey:statName];
    
}

-(NSMutableDictionary*)streamInfo{
    
    return streamInfo;
}

-(void)writeArrayStat:(NSString*)statName  _value:(NSDictionary*)value
{
    NSDictionary* stat = [stats objectForKey:statName];
    if(!stat)
    {
        stat = [[NSMutableDictionary alloc]init];
    }
    
    NSMutableArray* timeSeries = [stat objectForKey:@"timeseries"];
    
    if(!timeSeries)
    {
        timeSeries = [[NSMutableArray alloc]init];
    }
    
    [timeSeries addObject:value];
    [stat setValue:timeSeries forKey:@"timeseries"];
    [stats setValue:stat forKey:statName];
}

@end
