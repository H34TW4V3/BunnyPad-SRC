//
//  BPHomeViewController.m
//  BunnyPad iOS 6 Edition
//

#import "BPHomeViewController.h"
#import "BPEditorViewController.h"
#import "BPSettingsViewController.h"
#import "BPAboutViewController.h"
#import "BPNoteManager.h"
#import "BPTheme.h"

@interface BPHomeViewController ()
@property (nonatomic, strong) NSArray<BPNote *> *notes;
@end

@implementation BPHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"BunnyPad";

    // Setup Navigation Bar Items
    UIBarButtonItem *settingsBtn = [[UIBarButtonItem alloc] initWithTitle:@"Settings" style:UIBarButtonItemStyleBordered target:self action:@selector(openSettingsAction:)];
    self.navigationItem.leftBarButtonItem = settingsBtn;

    UIBarButtonItem *aboutBtn = [[UIBarButtonItem alloc] initWithTitle:@"About" style:UIBarButtonItemStyleBordered target:self action:@selector(openAboutAction:)];
    self.navigationItem.rightBarButtonItem = aboutBtn;

    // Table view for notes list with custom header
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];

    [self setupHeaderView];
    [self reloadNotes];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadNotes];
    [self applyTheme];
}

- (void)applyTheme {
    BPAppTheme theme = [BPTheme currentTheme];
    self.view.backgroundColor = [BPTheme backgroundColorForTheme:theme];
    self.tableView.backgroundColor = [BPTheme backgroundColorForTheme:theme];
    [self.tableView reloadData];
}

- (void)setupHeaderView {
    CGFloat headerHeight = 220.0;
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, headerHeight)];
    header.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    // Logo Image
    UIImage *logoImg = [UIImage imageNamed:@"BunnyPadLogo.png"];
    UIImageView *logoView = [[UIImageView alloc] initWithImage:logoImg];
    logoView.contentMode = UIViewContentModeScaleAspectFit;
    logoView.frame = CGRectMake((header.bounds.size.width - 70) / 2.0, 15, 70, 70);
    logoView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [header addSubview:logoView];

    // Title
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 90, header.bounds.size.width - 20, 28)];
    titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    titleLabel.text = @"BunnyPad";
    titleLabel.font = [UIFont boldSystemFontOfSize:24.0];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.textColor = [BPTheme goldColor];
    titleLabel.backgroundColor = [UIColor clearColor];
    [header addSubview:titleLabel];

    // Subtitle
    UILabel *subLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 118, header.bounds.size.width - 20, 18)];
    subLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    subLabel.text = @"The Newest and Cutest way to take notes";
    subLabel.font = [UIFont systemFontOfSize:12.0];
    subLabel.textAlignment = NSTextAlignmentCenter;
    subLabel.textColor = [UIColor whiteColor];
    subLabel.backgroundColor = [UIColor clearColor];
    [header addSubview:subLabel];

    // Action Buttons
    CGFloat btnWidth = (header.bounds.size.width - 40) / 2.0;
    UIButton *newNoteBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    newNoteBtn.frame = CGRectMake(15, 150, btnWidth, 44);
    newNoteBtn.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
    newNoteBtn.backgroundColor = [BPTheme goldColor];
    newNoteBtn.layer.cornerRadius = 8.0;
    newNoteBtn.clipsToBounds = YES;
    [newNoteBtn setTitle:@"★ New Note" forState:UIControlStateNormal];
    [newNoteBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    newNoteBtn.titleLabel.font = [UIFont boldSystemFontOfSize:15.0];
    [newNoteBtn addTarget:self action:@selector(createNewNoteAction:) forControlEvents:UIControlEventTouchUpInside];
    [header addSubview:newNoteBtn];

    UIButton *quickNoteBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    quickNoteBtn.frame = CGRectMake(header.bounds.size.width - btnWidth - 15, 150, btnWidth, 44);
    quickNoteBtn.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin;
    quickNoteBtn.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.2];
    quickNoteBtn.layer.cornerRadius = 8.0;
    quickNoteBtn.layer.borderColor = [BPTheme goldColor].CGColor;
    quickNoteBtn.layer.borderWidth = 1.0;
    quickNoteBtn.clipsToBounds = YES;
    [quickNoteBtn setTitle:@"⚡ Quick Note" forState:UIControlStateNormal];
    [quickNoteBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    quickNoteBtn.titleLabel.font = [UIFont boldSystemFontOfSize:15.0];
    [quickNoteBtn addTarget:self action:@selector(createQuickNoteAction:) forControlEvents:UIControlEventTouchUpInside];
    [header addSubview:quickNoteBtn];

    self.tableView.tableHeaderView = header;
}

- (void)reloadNotes {
    self.notes = [[BPNoteManager sharedManager] allNotes];
    [self.tableView reloadData];
}

#pragma mark - Actions

- (void)createNewNoteAction:(id)sender {
    BPNote *note = [[BPNoteManager sharedManager] createNoteWithTitle:@"New Note" content:@""];
    BPEditorViewController *editor = [[BPEditorViewController alloc] initWithNote:note];
    [self.navigationController pushViewController:editor animated:YES];
}

- (void)createQuickNoteAction:(id)sender {
    BPNote *note = [[BPNoteManager sharedManager] createQuickNote];
    BPEditorViewController *editor = [[BPEditorViewController alloc] initWithNote:note];
    [self.navigationController pushViewController:editor animated:YES];
}

- (void)openSettingsAction:(id)sender {
    BPSettingsViewController *settings = [[BPSettingsViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:settings];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)openAboutAction:(id)sender {
    BPAboutViewController *about = [[BPAboutViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:about];
    [self presentViewController:nav animated:YES completion:nil];
}

#pragma mark - UITableViewDataSource & Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"Saved Notes";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.notes.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellId = @"NoteCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellId];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    BPNote *note = self.notes[indexPath.row];
    cell.textLabel.text = [note.filename stringByDeletingPathExtension];
    cell.textLabel.font = [UIFont boldSystemFontOfSize:16.0];

    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateStyle:NSDateFormatterShortStyle];
    [df setTimeStyle:NSDateFormatterShortStyle];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"Modified: %@", [df stringFromDate:note.modificationDate]];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    BPNote *note = self.notes[indexPath.row];
    BPEditorViewController *editor = [[BPEditorViewController alloc] initWithNote:note];
    [self.navigationController pushViewController:editor animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        BPNote *note = self.notes[indexPath.row];
        [[BPNoteManager sharedManager] deleteNote:note error:nil];
        [self reloadNotes];
    }
}

@end
