//
//  SimplePingHelper.m
//  PingTester
//
//  Created by Hlung on 11/1/13.
//  Copyright (c) 2013 Oozou. All rights reserved.
//

#import "SimplePingHelper.h"

#define SEC_TIMEOUT 1

@interface SimplePingHelper()
@property(nonatomic,strong) SimplePing* simplePing;
@property(nonatomic,strong) id target;
@property(nonatomic,assign) SEL sel;
@end

@implementation SimplePingHelper

+ (void)ping:(NSString*)address target:(id)target sel:(SEL)sel {
    [[[SimplePingHelper alloc] initWithAddress:address target:target sel:sel] start];
}

- (id)initWithAddress:(NSString*)address target:(id)target sel:(SEL)sel {
	if (self = [self init]) {
		self.simplePing = [SimplePing simplePingWithHostName:address];
		self.simplePing.delegate = self;
		self.target = target;
		self.sel = sel;
	}
	return self;
}

- (void)start {
	[self.simplePing start];
	[self performSelector:@selector(endTime) withObject:nil afterDelay:SEC_TIMEOUT];
}

#pragma mark - Finishing and timing out

// Called after SEC_TIMEOUT seconds after ping start to check if it timed out.
- (void)endTime {
    // If it hasn't already been killed, then it's timed out.
	if (self.simplePing) [self failPing:@"timeout"];
}

// Called on success or failure to clean up
- (void)killPing {
	[self.simplePing stop];
	self.simplePing = nil;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
- (void)successPing {
	[self killPing];
	[self.target performSelector:self.sel withObject:[NSNumber numberWithBool:YES]];
}

- (void)failPing:(NSString*)reason {
	[self killPing];
	[self.target performSelector:self.sel withObject:[NSNumber numberWithBool:NO]];
}
#pragma clang diagnostic pop

#pragma mark - Pinger delegate

// When the pinger starts, send the ping immediately
- (void)simplePing:(SimplePing *)pinger didStartWithAddress:(NSData *)address {
	[self.simplePing sendPingWithData:nil];
}

- (void)simplePing:(SimplePing *)pinger didFailWithError:(NSError *)error {
	[self failPing:@"didFailWithError"];
}

- (void)simplePing:(SimplePing *)pinger didFailToSendPacket:(NSData *)packet error:(NSError *)error {
	[self failPing:@"didFailToSendPacket"];
}

- (void)simplePing:(SimplePing *)pinger didReceivePingResponsePacket:(NSData *)packet {
	[self successPing];
}

@end
