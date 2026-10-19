//
//  BPHomeViewController.h
//  BunnyPad iOS 6 Edition
//

#import <UIKit/UIKit.h>

@interface BPHomeViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *headerView;

@end
