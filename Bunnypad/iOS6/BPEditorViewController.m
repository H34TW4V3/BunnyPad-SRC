//
//  BPEditorViewController.m
//  BunnyPad iOS 6 Edition
//

#import "BPEditorViewController.h"
#import "BPTheme.h"

@interface BPEditorViewController ()
@property (nonatomic, assign) BOOL isSearching;
@property (nonatomic, copy) NSString *currentSearchQuery;
@end

@implementation BPEditorViewController

- (instancetype)initWithNote:(BPNote *)note {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _note = note;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = self.note.filename ? [self.note.filename stringByDeletingPathExtension] : @"Untitled Note";

    // Setup Navigation Bar Items
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveNoteAction:)];
    UIBarButtonItem *actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareNoteAction:)];
    self.navigationItem.rightBarButtonItems = @[saveButton, actionButton];

    // Setup Text View
    self.textView = [[UITextView alloc] initWithFrame:self.view.bounds];
    self.textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.textView.delegate = self;
    self.textView.text = self.note.content ?: @"";
    self.textView.font = [UIFont fontWithName:@"HelveticaNeue" size:16.0] ?: [UIFont systemFontOfSize:16.0];
    [self.view addSubview:self.textView];

    // Setup Bottom Toolbar
    CGFloat toolbarHeight = 44.0;
    CGFloat statusHeight = 20.0;
    CGRect toolbarFrame = CGRectMake(0, self.view.bounds.size.height - toolbarHeight - statusHeight, self.view.bounds.size.width, toolbarHeight);
    self.toolbar = [[UIToolbar alloc] initWithFrame:toolbarFrame];
    self.toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;

    UIBarButtonItem *undoItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemUndo target:self action:@selector(undoAction:)];
    UIBarButtonItem *redoItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRedo target:self action:@selector(redoAction:)];
    UIBarButtonItem *flex1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *dateItem = [[UIBarButtonItem alloc] initWithTitle:@"Date" style:UIBarButtonItemStyleBordered target:self action:@selector(insertDateAction:)];
    UIBarButtonItem *flex2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *searchItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(searchAction:)];
    UIBarButtonItem *dismissKeyboardItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(dismissKeyboardAction:)];

    self.toolbar.items = @[undoItem, redoItem, flex1, dateItem, flex2, searchItem, dismissKeyboardItem];
    [self.view addSubview:self.toolbar];

    // Setup Status Bar at bottom
    CGRect statusFrame = CGRectMake(0, self.view.bounds.size.height - statusHeight, self.view.bounds.size.width, statusHeight);
    self.statusLabel = [[UILabel alloc] initWithFrame:statusFrame];
    self.statusLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    self.statusLabel.font = [UIFont systemFontOfSize:11.0];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.statusLabel];

    // Inset text view content so toolbar doesn't overlap
    self.textView.contentInset = UIEdgeInsetsMake(0, 0, toolbarHeight + statusHeight, 0);
    self.textView.scrollIndicatorInsets = self.textView.contentInset;

    [self applyTheme];
    [self updateStatus];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self applyTheme];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self autoSave];
}

- (void)applyTheme {
    BPAppTheme theme = [BPTheme currentTheme];
    self.view.backgroundColor = [BPTheme editorBackgroundColorForTheme:theme];
    self.textView.backgroundColor = [BPTheme editorBackgroundColorForTheme:theme];
    self.textView.textColor = [BPTheme textColorForTheme:theme];
    self.statusLabel.backgroundColor = [BPTheme cardBackgroundColorForTheme:theme];
    self.statusLabel.textColor = [BPTheme secondaryTextColorForTheme:theme];
}

- (void)updateStatus {
    NSString *text = self.textView.text ?: @"";
    NSUInteger length = text.length;

    NSScanner *scanner = [NSScanner scannerWithString:text];
    NSCharacterSet *whiteSpace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSUInteger words = 0;
    while ([scanner scanUpToCharactersFromSet:whiteSpace intoString:nil]) {
        words++;
    }

    NSArray *lines = [text componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSUInteger lineCount = lines.count;

    self.statusLabel.text = [NSString stringWithFormat:@"Words: %lu  •  Characters: %lu  •  Lines: %lu", (unsigned long)words, (unsigned long)length, (unsigned long)lineCount];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView {
    self.note.content = textView.text;
    [self updateStatus];
}

#pragma mark - Actions

- (void)saveNoteAction:(id)sender {
    [self autoSave];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Saved" message:@"Your note has been saved." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

- (void)autoSave {
    self.note.content = self.textView.text;
    [[BPNoteManager sharedManager] saveNote:self.note error:nil];
}

- (void)shareNoteAction:(id)sender {
    [self autoSave];
    NSString *textToShare = self.textView.text ?: @"";
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[textToShare] applicationActivities:nil];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        // iPad popover handling
        [self presentViewController:activityVC animated:YES completion:nil];
    } else {
        [self presentViewController:activityVC animated:YES completion:nil];
    }
}

- (void)undoAction:(id)sender {
    if ([self.textView.undoManager canUndo]) {
        [self.textView.undoManager undo];
    }
}

- (void)redoAction:(id)sender {
    if ([self.textView.undoManager canRedo]) {
        [self.textView.undoManager redo];
    }
}

- (void)insertDateAction:(id)sender {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    NSString *dateString = [formatter stringFromDate:[NSDate date]];

    NSRange range = self.textView.selectedRange;
    NSString *text = self.textView.text;
    NSString *newText = [text stringByReplacingCharactersInRange:range withString:dateString];
    self.textView.text = newText;
    self.textView.selectedRange = NSMakeRange(range.location + dateString.length, 0);
    [self textViewDidChange:self.textView];
}

- (void)searchAction:(id)sender {
    UIAlertView *searchAlert = [[UIAlertView alloc] initWithTitle:@"Find Text" message:@"Enter text to find:" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Find", nil];
    searchAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [searchAlert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) { // "Find"
        UITextField *textField = [alertView textFieldAtIndex:0];
        NSString *query = textField.text;
        if (query.length > 0) {
            NSRange range = [self.textView.text rangeOfString:query options:NSCaseInsensitiveSearch];
            if (range.location != NSNotFound) {
                self.textView.selectedRange = range;
                [self.textView scrollRangeToVisible:range];
                [self.textView becomeFirstResponder];
            } else {
                UIAlertView *notFound = [[UIAlertView alloc] initWithTitle:@"Not Found" message:[NSString stringWithFormat:@"\"%@\" was not found in this note.", query] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [notFound show];
            }
        }
    }
}

- (void)dismissKeyboardAction:(id)sender {
    [self.textView resignFirstResponder];
}

@end
