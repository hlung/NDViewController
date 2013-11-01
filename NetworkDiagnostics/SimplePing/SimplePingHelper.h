//
//  SimplePingHelper.h
//  PingTester
//
//  Created by Hlung on 11/1/13.
//  Copyright (c) 2013 Oozou. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SimplePing.h"

@interface SimplePingHelper : NSObject <SimplePingDelegate>

// Pings the address, and then calls the selector when done.
// The selector takes a NSNumber which is a bool for success.
+ (void)ping:(NSString*)address target:(id)target sel:(SEL)sel;

@end
