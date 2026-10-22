//
//  BPAppDelegate.h
//  BunnyPad iOS 6 Edition
//

#import <UIKit/UIKit.h>

@class BPHomeViewController;

@interface BPAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UINavigationController *navigationController;
@property (strong, nonatomic) BPHomeViewController *homeViewController;

@end
