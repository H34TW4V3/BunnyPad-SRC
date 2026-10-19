//
//  BPEditorViewController.h
//  BunnyPad iOS 6 Edition
//

#import <UIKit/UIKit.h>
#import "BPNoteManager.h"

@interface BPEditorViewController : UIViewController <UITextViewDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) BPNote *note;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIToolbar *toolbar;

- (instancetype)initWithNote:(BPNote *)note;

@end
