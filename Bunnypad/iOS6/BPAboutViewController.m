//
//  BPAboutViewController.m
//  BunnyPad iOS 6 Edition
//

#import "BPAboutViewController.h"
#import "BPTheme.h"

@implementation BPAboutViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"About BunnyPad";

    UIBarButtonItem *doneBtn = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(doneAction:)];
    self.navigationItem.rightBarButtonItem = doneBtn;

    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:scrollView];

    CGFloat width = self.view.bounds.size.width;

    // Logo
    UIImage *logo = [UIImage imageNamed:@"BunnyPadLogo.png"];
    UIImageView *logoView = [[UIImageView alloc] initWithImage:logo];
    logoView.contentMode = UIViewContentModeScaleAspectFit;
    logoView.frame = CGRectMake((width - 90) / 2.0, 30, 90, 90);
    logoView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [scrollView addSubview:logoView];

    // App Name
    UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 135, width - 40, 32)];
    nameLabel.text = @"BunnyPad";
    nameLabel.font = [UIFont boldSystemFontOfSize:26.0];
    nameLabel.textAlignment = NSTextAlignmentCenter;
    nameLabel.textColor = [BPTheme goldColor];
    nameLabel.backgroundColor = [UIColor clearColor];
    nameLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [scrollView addSubview:nameLabel];

    // Version
    UILabel *verLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 168, width - 40, 20)];
    verLabel.text = @"Version 3.0 (iOS 6 Edition)";
    verLabel.font = [UIFont systemFontOfSize:13.0];
    verLabel.textAlignment = NSTextAlignmentCenter;
    verLabel.textColor = [UIColor whiteColor];
    verLabel.backgroundColor = [UIColor clearColor];
    verLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [scrollView addSubview:verLabel];

    // Description Card
    UIView *card = [[UIView alloc] initWithFrame:CGRectMake(20, 205, width - 40, 130)];
    card.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.35];
    card.layer.cornerRadius = 10.0;
    card.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.2].CGColor;
    card.layer.borderWidth = 1.0;
    card.clipsToBounds = YES;
    card.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    UILabel *descLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 12, card.bounds.size.width - 30, 106)];
    descLabel.text = @"BunnyPad is the newest and cutest way to take notes.\n\nNow natively backported to iOS 6 devices with complete plain-text editing, customizable themes, and full document management.";
    descLabel.font = [UIFont systemFontOfSize:14.0];
    descLabel.textColor = [UIColor whiteColor];
    descLabel.backgroundColor = [UIColor clearColor];
    descLabel.numberOfLines = 0;
    descLabel.textAlignment = NSTextAlignmentCenter;
    descLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [card addSubview:descLabel];
    [scrollView addSubview:card];

    // GitHub Link Button
    UIButton *linkBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    linkBtn.frame = CGRectMake((width - 220) / 2.0, 355, 220, 44);
    linkBtn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [linkBtn setTitle:@"View on GitHub" forState:UIControlStateNormal];
    [linkBtn setTitleColor:[BPTheme goldColor] forState:UIControlStateNormal];
    linkBtn.titleLabel.font = [UIFont boldSystemFontOfSize:15.0];
    [linkBtn addTarget:self action:@selector(openGitHubAction:) forControlEvents:UIControlEventTouchUpInside];
    [scrollView addSubview:linkBtn];

    scrollView.contentSize = CGSizeMake(width, 420);

    [self applyTheme];
}

- (void)applyTheme {
    BPAppTheme theme = [BPTheme currentTheme];
    self.view.backgroundColor = [BPTheme backgroundColorForTheme:theme];
}

- (void)doneAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)openGitHubAction:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/GSYT-Productions/BunnyPad-SRC"]];
}

@end
