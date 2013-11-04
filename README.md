# iOS Netwerk Diagnostics
A view controller with a table view showing a list of host urls, each with reachability and latency information.
 
![Screenshot](/README/ss.png)

## Requirements

* Xcode 5 with iOS 7 Base SDK, but should be OK on Xcode 4.6.3.

## How to use

1. Add `NDViewController.h` to your project.
1. Add these frameworks:
	* `CFNetork.framework`
	* `SystemConfiguration.framework`
1. Follow this example...

```
NDViewController *vc = [NDViewController viewController];`
NDObject *nd1 = [NDObject objectWithTitle:@"Google" host:[NSURL URLWithString:@"https://www.google.com"]];
NDObject *nd2 = [NDObject objectWithTitle:@"The Verge (HTTP)" host:[NSURL URLWithString:@"www.theverge.com"]];
NDObject *nd3 = [NDObject objectWithTitle:@"Bad URL" host:[NSURL URLWithString:@"somebadurlxxx"]];
vc.testHosts = @[nd1,nd2,nd3]; // config urls
```

## Sample Project

Just run `NDSample/NDSample.xcodeproj`.

## Latency Measurement

It uses traditional ICMP ping packets and measure the round trip time.
But some web site blocks ICMP packets for its own safety. Result in ping timeout. In this case, it will fall back by doing HTTP GET instead. When done, `kReachabilityChangedNotification` notification is sent to update the object.

## Credits

- [SimplePing](https://developer.apple.com/library/mac/samplecode/SimplePing/Listings/SimplePing_h.html)
- [Reachability (ARCified)](https://gist.github.com/darkseed/1182373)