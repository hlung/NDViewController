//
//  NDObject.m
//  NDSample
//
//  Created by Hlung on 11/1/13.
//  Copyright (c) 2013 Oozou. All rights reserved.
//

#import "NDObject.h"
#import "SimplePingHelper.h"

@interface NDObject ()
@property (nonatomic,strong) NSURL *host;
@property (nonatomic,strong) NSString *title;
@property (nonatomic,strong) NSNumber *latency;
@property (nonatomic,assign) NDLatencyType latencyType;
@property (nonatomic,strong) Reachability* hostReach;
@end

@implementation NDObject {
    NSDate *latencyStart;
    SimplePingHelper *pinger;
    NSString *hostScheme, *hostName;
}

+ (NDObject*)objectWithTitle:(NSString*)title host:(NSURL*)host {
    NDObject *new = [[NDObject alloc] init];
    new.title = title;
    new.host = host;
    return new;
}

- (void)setHost:(NSURL *)host {
    if ([host isKindOfClass:[NSURL class]]) {
        _host = host;

        hostScheme = self.host.scheme;
        hostName = self.host.host;
        if (hostScheme == nil) {
            hostScheme = @"http";
            hostName = self.host.absoluteString;
            _host = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@",hostScheme,hostName]];
        }
        
        self.latency = nil;
        self.latencyType = NDLatencyType_unknown;
    }
}

- (void)reachabilityChanged:(NSNotification *)notification {
    Reachability *reach = [notification object];
    if([reach isKindOfClass:[Reachability class]] && reach == self.hostReach) {
        if ([self.hostReach currentReachabilityStatus] != NotReachable) {
            NSLog(@"%@ - host reachable", self);
            [self measureLatency];
        }
        else {
            NSLog(@"%@ - host NOT reachable!", self);
        }
        [self notifyChanges];
    }
}

- (void)start {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reachabilityChanged:)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    
    // NOTE: Some version of Reachability uses method name -reachabilityWithHostName: instead
    // (with lower case 'n'). So be careful!
    //self.hostReach = [Reachability reachabilityWithHostname:hostName];
    self.hostReach = [Reachability reachabilityWithHostName:hostName];
	[self.hostReach startNotifier];
}

- (NSString*)description {
    return [NSString stringWithFormat:@"[%@ host: \"%@\"]",NSStringFromClass(self.class), self.host];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.hostReach stopNotifier];
}

#pragma mark - Latency

- (void)measureLatency {
    if ([self.hostReach currentReachabilityStatus] != NotReachable) {
        if (self.latencyType != NDLatencyType_measuring) {
            self.latencyType = NDLatencyType_measuring;
            self.latency = nil;
            [self notifyChanges];
            [self measureLatencyByICMP];
        }
    }
}

- (void)notifyChanges {
    [[NSNotificationCenter defaultCenter] postNotificationName:kNDObjectChangeNotification object:self];
}

- (NSNumber*)endLatency {
    NSNumber *num = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSinceDate:latencyStart]];
    latencyStart = nil;
    return num;
}

#pragma mark Latency ICMP PING

// Measuring latency by pinging host. May not work if host blocks ICMP packets,
// resulting in timeout (Request timeout for icmp_seq 0)
// In this case, we fall back to -measureLatencyByHTTPGET
- (void)measureLatencyByICMP {
    NSLog(@"%@ - measuring PING latency...", self);
    latencyStart = [NSDate date];
    [SimplePingHelper ping:hostName target:self sel:@selector(pingResult:)];
}

- (void)pingResult:(NSNumber*)success {
//    NSDate *now = [NSDate date];
//    NSLog(@"time %f", [now timeIntervalSinceDate:latencyStart]);
//    latencyStart = now;
//    [SimplePingHelper ping:self.host target:self sel:@selector(pingResult:)];

    if (success.boolValue) {
        self.latency = [self endLatency];
        self.latencyType = NDLatencyType_ICMP;
        NSLog(@"%@ - PING latency: %@s", self, self.latency);
        [self notifyChanges];
    } else {
        NSLog(@"%@ - PING latency failed! trying other methods...", self);
        [self measureLatencyByHTTPGET];
    }
}

#pragma mark Latency HTTP GET

// Measuring latency by sending HTTP GET. End time is when the first response arrives.
// Before sending, the host url string is prefixed by @"http://".
- (void)measureLatencyByHTTPGET {
    NSLog(@"%@ - measuring HTTP GET latency...", self);
    //NSURL *url = [NSURL URLWithString:[@"http://" stringByAppendingString:self.host]];
    NSURL *url = self.host;
    NSURLRequest *req = [NSURLRequest requestWithURL:url];
    latencyStart = [NSDate date];
    [NSURLConnection connectionWithRequest:req delegate:self];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    // A response has been received, this is where we initialize the instance var you created
    // so that we can append data to it in the didReceiveData method
    // Furthermore, this method is called each time there is a redirect so reinitializing it
    // also serves to clear it
    self.latency = [self endLatency];
    self.latencyType = NDLatencyType_HTTP_GET;
    NSLog(@"%@ - HTTP GET latency: %@s", self, self.latency);
    [self notifyChanges];
    [connection cancel];
}
//- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {}
//- (void)connectionDidFinishLoading:(NSURLConnection *)connection {}
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // The request has failed for some reason!
    // Check the error var
    latencyStart = nil;
    self.latency = nil;
    self.latencyType = NDLatencyType_failed;
    NSLog(@"%@ - HTTP GET latency failed!", self);
    [self notifyChanges];
}

// Adds support for https, skipping certificate checking.
-(void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust] &&
        [challenge.protectionSpace.host hasSuffix:connection.originalRequest.URL.host]) {
        // accept the certificate anyway
        [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]
             forAuthenticationChallenge:challenge];
        
        [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
    }
    else {
        [challenge.sender cancelAuthenticationChallenge:challenge];
    }
}

#pragma mark - utils

+ (NSString *)stringFromStatus:(NetworkStatus)status {
    NSString *string;
    switch (status) {
        case NotReachable:
            string = @"Not Reachable";
            break;
        case ReachableViaWiFi:
            string = @"Reachable via WiFi";
            break;
        case ReachableViaWWAN:
            string = @"Reachable via WWAN";
            break;
        default:
            string = @"Unknown";
            break;
    }
    return string;
}

+ (UIImage*)imageFromStatus:(NetworkStatus)status {
    NSString *string;
    switch (status) {
        case ReachableViaWiFi:
            string = @"wifi";
            break;
        case ReachableViaWWAN:
            string = @"wwan";
            break;
        case NotReachable:
        default:
            string = @"stop";
            break;
    }
    return [UIImage imageNamed:string];
}

@end