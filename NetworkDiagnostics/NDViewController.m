//
//  NDViewController.m
//  NetworkDiagnostics
//
//  Created by Hlung on 10/30/13.
//  Copyright (c) 2013 Oozou. All rights reserved.
//

#import "NDViewController.h"
#import "Reachability.h"
#import "NDObject.h"

@implementation NDCell
- (void)setObject:(NDObject *)object {
    _object = object;
    
    [self update];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(ndObjectChanged:)
                                                 name:kNDObjectChangeNotification
                                               object:nil];
}

- (void)ndObjectChanged:(NSNotification *)notification {
    NDObject *object = [notification object];
    if([object isKindOfClass:[NDObject class]] && object == self.object) {
        [self update];
    }
}

- (void)update {
    NetworkStatus status = [self.object.hostReach currentReachabilityStatus];
    NSString *str = [NDObject stringFromStatus:status];
    //NSLog(@"- %@: status = \"%@\"", self.object.host, str);
    self.titleLB.text = self.object.title;
    self.urlLB.text = self.object.host;
    self.connectionIV.image = [NDObject imageFromStatus:status];
    self.reachableLB.text = str;
    
    NSString *latencyStr = @"-";
    if (status != NotReachable) {
        [self.activityView stopAnimating];
        
        switch (self.object.latencyType) {
            case NDLatencyType_unknown:
                break;
            case NDLatencyType_measuring:
                latencyStr = @"";
                [self.activityView startAnimating];
                break;
            case NDLatencyType_failed:
                latencyStr = @"measuring failed";
                break;
            default: {
                NSString *httpGet = self.object.latencyType == NDLatencyType_HTTP_GET ? @" (HTTP)" : @"";
                latencyStr = self.object.latency ? [NSString stringWithFormat:@"%.3f ms%@", self.object.latency.doubleValue*1000, httpGet] : @"-";
            }
                break;
        }
	}
    self.latencyLB.text = latencyStr;
}

@end

@interface NDViewController ()
@property (strong, nonatomic) UIRefreshControl *refreshControl;
@end

@implementation NDViewController

+ (NDViewController*)viewController {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"NDViewController" bundle:[NSBundle mainBundle]];
    return [sb instantiateViewControllerWithIdentifier:@"NDViewController"];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Custom initialization

        // Example
        NDObject *nd1 = [NDObject objectWithTitle:@"Google" host:@"www.google.com"];
        NDObject *nd2 = [NDObject objectWithTitle:@"The Verge (HTTP)" host:@"www.theverge.com"];
        NDObject *nd3 = [NDObject objectWithTitle:@"Bad URL" host:@"somebadurlxxx"];
        self.testHosts = @[nd1,nd2,nd3];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reachabilityChanged:)
                                                 name:kReachabilityChangedNotification
                                               object:nil];

    self.internetReach = [Reachability reachabilityForInternetConnection];
	[self.internetReach startNotifier];
    [self updateInterfaceWithReachability:self.internetReach];
    
    [self addRefreshControl];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self start];
}

- (void)start {
    for (NDObject *o in self.testHosts) {
        if ([o isKindOfClass:[NDObject class]]) {
            [o start];
        }
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.internetReach stopNotifier];
}

#pragma mark - UIRefreshControl

- (void)refreshTableView {
    [self.refreshControl beginRefreshing];
    for (NDObject *o in self.testHosts) {
        if ([o isKindOfClass:[NDObject class]]) {
            [o measureLatency];
            //[o performSelector:@selector(measureLatency) withObject:nil afterDelay:0.1];
        }
    }
    [self.refreshControl performSelector:@selector(endRefreshing) withObject:nil afterDelay:1];
}

- (void)addRefreshControl {
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshTableView) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
}

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"NDCell";
    NDCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    NDObject *r = self.testHosts[indexPath.row];
    cell.object = r;
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.testHosts.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - reachability

- (void)reachabilityChanged:(NSNotification *)notification {
    Reachability *reach = [notification object];
    if([reach isKindOfClass:[Reachability class]]) {
        [self updateInterfaceWithReachability:reach];
    }
}

- (void)updateInterfaceWithReachability:(Reachability*)curReach {
    if (curReach == self.internetReach) {
        NetworkStatus status = [curReach currentReachabilityStatus];

        NSString *s = [NDObject stringFromStatus:status];
        NSLog(@"internetReach: status = \"%@\"", s);
        self.internetLB.text = s;
        self.internetIV.image = [NDObject imageFromStatus:status];
    }
}

@end
