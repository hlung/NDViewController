//
//  NDViewController.h
//  NetworkDiagnostics
//
//  Created by Hlung on 10/30/13.
//  Copyright (c) 2013 Oozou. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NDObject.h"

@class Reachability;


@interface NDViewController : UIViewController
// ------------
// Customizable
/** An array of NDObject objects */
@property (nonatomic,strong) NSArray *testHosts;
// ------------

@property (nonatomic,strong) Reachability* internetReach;   // internet reachability
@property (weak, nonatomic) IBOutlet UIImageView *internetIV;
@property (weak, nonatomic) IBOutlet UILabel *internetLB;
@property (weak, nonatomic) IBOutlet UILabel *summaryLB;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

/** Instantiates view controller from the storyboard */
+ (NDViewController*)viewController;

@end


@interface NDCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *titleLB;
@property (weak, nonatomic) IBOutlet UILabel *urlLB;
@property (weak, nonatomic) IBOutlet UIImageView *connectionIV;
@property (weak, nonatomic) IBOutlet UILabel *reachableLB;
@property (weak, nonatomic) IBOutlet UILabel *latencyLB;
@property (weak, nonatomic) IBOutlet UILabel *summaryLB;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityView;
@property (nonatomic,assign) NDObject *object;  // set object will populate cell automatically
@end