//
//  BPSettingsViewController.h
//  BunnyPad iOS 6 Edition
//

#import <UIKit/UIKit.h>

@interface BPSettingsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;

@end
