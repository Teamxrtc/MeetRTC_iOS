//
//  WebRTCHTTP.m
//  meet-webrtc-sdk
//
//  Created by Pankaj on 05/08/14.
//  Copyright 2014 Comcast Cable Communications Management, LLC.
//
#import "WebRTCJSON.h"
#import "WebRTCHTTP.h"
#import "WebRTCError.h"
#import "WebRTCLogHandler.h"
#import "WebRTCLogging.h"

@implementation WebRTCHTTP
{
    NSURLSessionDataTask* datatask;
}

NSString* const TAG1 = @"WebRTCHTTP";

@synthesize url = _url;
- (id)initWithDefaultValue:(NSString*)endPointURL  _token:(NSData*)token
{
    self = [super init];
    if (self!=nil) {
        _url = endPointURL;
    }
    
    if ((endPointURL == nil) || (token == nil))
    {
        return nil;
    }
    
    NSString *tokenDataString = [[NSString alloc] initWithData:token encoding:NSUTF8StringEncoding];
    _tokenStr = [NSString stringWithFormat:@"Bearer %@", tokenDataString];
    datatask = nil;
    return self;
}


-(void)sendResourceRequest
{
    LogInfo(@"URL is = %@",_url );
    NSURL *url = [NSURL URLWithString:_url];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    // Set POST method
    request.HTTPMethod = @"GET";
    
    //[request setHTTPMethod:@"GET"];
    //[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];
    //[request setValue:_tokenStr forHTTPHeaderField:@"Authorization"];
    
    // Set session config
    NSURLSessionConfiguration * sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfig.HTTPAdditionalHeaders = @{ @"Content-Type" : @"application/x-www-form-urlencoded", @"Authorization" : _tokenStr };
    
    // Create URLSession
    //    NSURLSession * urlSession = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    
    NSURLSession * urlSession = [NSURLSession sessionWithConfiguration:sessionConfig delegate:nil delegateQueue:nil];

    
    //NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    //[connection start];
  [datatask =  [urlSession dataTaskWithRequest:request completionHandler:^(NSData *data,
                                                                 NSURLResponse *response,
                                                                 NSError *error) {
        
        if(self.delegate != nil)
        {
            
        NSString *strData = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
            
        LogInfo(@"WebRTC HTTP: didReceiveData %@",strData );
        
        NSUInteger statusCode = ((NSHTTPURLResponse *)response).statusCode;
        if (error || statusCode != 200) {
            NSError *httperror;
            NSMutableDictionary* details = [NSMutableDictionary dictionary];
            
            LogInfo(@"WebRTC HTTP: Received error code from HTTP server :: %lu",(unsigned long)statusCode);

            if(statusCode == 401)
            {
                [details setValue:@"Invalid credential for http connection" forKey:NSLocalizedDescriptionKey];
                httperror = [NSError errorWithDomain:Session code:ERR_INVALID_CREDENTIALS userInfo:details];
            }
            else
            {
                [details setValue:@"Invalid end point URL" forKey:NSLocalizedDescriptionKey];
                httperror = [NSError errorWithDomain:Session code:ERR_ENDPOINT_URL userInfo:details];
            }
            
            [self.delegate onHTTPError:httperror.description errorCode:httperror.code];
            return;
        }
       
        
        NSDictionary* json =[WebRTCJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        NSDictionary* webSockjson =[json objectForKey:@"webSocket"];
        NSDictionary* iceServer =[json objectForKey:@"iceServers"];
        if (webSockjson == nil || iceServer == nil)
        {
            NSMutableDictionary* details = [NSMutableDictionary dictionary];
            [details setValue:@"Received incorrect parameters from RTCG" forKey:NSLocalizedDescriptionKey];
            NSError *error = [NSError errorWithDomain:Session code:ERR_INCORRECT_PARAMS userInfo:details];
            [self.delegate onHTTPError:error.description errorCode:error.code];
            return;
        }
        
        /*NSDictionary* errormsg =[json objectForKey:@"error"];
        //NSDictionary* iceservejson =[json objectForKey:@"iceServers"];
        
        if (errormsg != nil)
        {
            NSMutableDictionary* details = [NSMutableDictionary dictionary];
            [details setValue:@"Received error from RTCG" forKey:NSLocalizedDescriptionKey];
            NSError *error = [NSError errorWithDomain:Session code:ERR_INCORRECT_PARAMS userInfo:details];
            [self.delegate onHTTPError:error.description errorCode:error.code];
            return;
        }*/
        
        NSString* credential = [webSockjson objectForKey:@"credential"];
        NSString* username = [webSockjson objectForKey:@"username"];
        NSArray* uris = [webSockjson objectForKey:@"uris"];
        NSURL *validURL = [NSURL URLWithString: [uris objectAtIndex:0]];
        NSString* webSockURL = [NSString stringWithFormat:@"%@/socket.io/1?username=%@&credential=%@",[uris objectAtIndex:0],username,credential];
        //Need to use this URL for handshaking

        LogInfo(@"webSockURL = %@",webSockURL);
            
        if((![validURL host]) || (![validURL port]))
        {
            NSMutableDictionary* details = [NSMutableDictionary dictionary];
            [details setValue:@"URL/Port is not valid" forKey:NSLocalizedDescriptionKey];
            NSError *error = [NSError errorWithDomain:Session code:ERR_INCORRECT_PARAMS userInfo:details];
            [self.delegate onHTTPError:error.description errorCode:error.code];
            return;
        }
         if(self.delegate != nil)
        [self.delegate startSignalingServer:webSockjson iceserverdata:json];

    }
    }]
        resume];

}

-(void)End
{
    if (datatask != nil)
        [datatask cancel];
    datatask = nil;
}

//Using for testing through local server
/*-(void)sendRequest
{
    NSLog(@">>>>URL is = %@",_url);
    
    NSURL *url = [NSURL URLWithString:_url];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"GET"];
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    [connection start];
}


-(void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    
    NSLog(@"didReceiveData");
    NSError* error;
    NSDictionary* json =[WebRTCJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    NSLog(@"Received http data = %@",json);
    NSDictionary* webSockjson =[json objectForKey:@"webSocket"];
    NSString* credential = [webSockjson objectForKey:@"credential"];
    NSString* username = [webSockjson objectForKey:@"username"];
    NSArray* uris = [webSockjson objectForKey:@"uris"];
    NSURL *validURL = [NSURL URLWithString: [uris objectAtIndex:0]];
    NSString* webSockURL = [NSString stringWithFormat:@"%@/socket.io/1?username=%@&credential=%@",[uris objectAtIndex:0],username,credential];
    
    //Need to use this URL for handshaking
    NSLog(@"webSockURL = %@",webSockURL);
    
    if((![validURL host]) || (![validURL port]))
    {
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"URL/Port is not valid" forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:Session code:ERR_INCORRECT_PARAMS userInfo:details];
        [self.delegate onHTTPError:error.description errorCode:error.code];
        return;
    }
    
    [self.delegate startSignalingServer:webSockjson iceserverdata:webSockjson];
}*/

-(void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    
    LogError(@"didFailWithError" );
    [self.delegate onHTTPError:error.description errorCode:error.code];
    
}

@end
