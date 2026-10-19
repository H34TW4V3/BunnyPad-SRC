//
//  BPAppDelegate.m
//  BunnyPad iOS 6 Edition
//

#import "BPAppDelegate.h"
#import "BPHomeViewController.h"
#import "BPEditorViewController.h"
#import "BPNoteManager.h"
#import "BPTheme.h"

@implementation BPAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [BPTheme applyAppearance];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.homeViewController = [[BPHomeViewController alloc] init];
    self.navigationController = [[UINavigationController alloc] initWithRootViewController:self.homeViewController];

    self.window.rootViewController = self.navigationController;
    [self.window makeKeyAndVisible];
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    if ([url isFileURL]) {
        NSString *filename = [url lastPathComponent];
        NSString *content = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
        if (content) {
            BPNote *note = [[BPNoteManager sharedManager] createNoteWithTitle:[filename stringByDeletingPathExtension] content:content];
            BPEditorViewController *editor = [[BPEditorViewController alloc] initWithNote:note];
            [self.navigationController pushViewController:editor animated:YES];
            return YES;
        }
    }
    return NO;
}

- (void)applicationWillResignActive:(UIApplication *)application {
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [self.homeViewController viewWillAppear:NO];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
}

- (void)applicationWillTerminate:(UIApplication *)application {
}

@end
