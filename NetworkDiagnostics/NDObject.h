//
//  NDObject.h
//  NDSample
//
//  Created by Hlung on 11/1/13.
//  Copyright (c) 2013 Oozou. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Reachability.h"

#define kNDObjectChangeNotification @"kNDObjectChangeNotification"

typedef NS_ENUM(NSInteger, NDLatencyType) {
    NDLatencyType_unknown, // initial state
    NDLatencyType_measuring,
    NDLatencyType_failed,
    NDLatencyType_ICMP,
    NDLatencyType_HTTP_GET,
};

/** Holds a host information for testing reachability and latency */
@interface NDObject : NSObject
/** Host name or URL. If no URL scheme is specified, the url is reconstructed using "http" scheme, 
 to allow calculating HTTP latency. HTTPS URLs are supported by skipping certificate checking. */
@property (nonatomic,strong,readonly) NSURL *host;
/** Host name for display */
@property (nonatomic,strong,readonly) NSString *title;
/** Latency time, in seconds. Double type. */
@property (nonatomic,strong,readonly) NSNumber *latency;
/** Specifies how the latency value was calculated */
@property (nonatomic,assign,readonly) NDLatencyType latencyType;
/** Host reachability object.
 @see -start */
@property (nonatomic,strong,readonly) Reachability* hostReach;

/** Initializes a new object */
+ (NDObject*)objectWithTitle:(NSString*)title host:(NSString*)host;

/** Starts reachability notifications and latency tests. */
- (void)start;

/** Starts measuring latency by pinging to host. If failed, measure by doing HTTP GET instead. 
 When done, kNDObjectChangeNotification notification is sent.
 It is automatically called in -start, but you can call it again manually to refresh latency.
 Does nothing if host is not reachable or latencyType is NDLatencyType_measuring. */
- (void)measureLatency;

// utils
+ (NSString *)stringFromStatus:(NetworkStatus)status;
+ (UIImage *)imageFromStatus:(NetworkStatus)status;

@end
