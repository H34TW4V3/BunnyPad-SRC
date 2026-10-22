//
//  BPSettingsViewController.m
//  BunnyPad iOS 6 Edition
//

#import "BPSettingsViewController.h"
#import "BPTheme.h"

@interface BPSettingsViewController ()
@property (nonatomic, assign) BPAppTheme selectedTheme;
@end

@implementation BPSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Settings";

    UIBarButtonItem *doneBtn = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(doneAction:)];
    self.navigationItem.rightBarButtonItem = doneBtn;

    self.selectedTheme = [BPTheme currentTheme];

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];

    [self applyTheme];
}

- (void)applyTheme {
    BPAppTheme theme = [BPTheme currentTheme];
    self.view.backgroundColor = [BPTheme backgroundColorForTheme:theme];
    self.tableView.backgroundColor = [BPTheme backgroundColorForTheme:theme];
}

- (void)doneAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableViewDataSource & Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) return @"App Theme";
    if (section == 1) return @"Editor Preferences";
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return 3; // Gradient, Dark, Light
    if (section == 1) return 2; // Word wrap, Status bar
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        static NSString *ThemeCellId = @"ThemeCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ThemeCellId];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ThemeCellId];
        }

        if (indexPath.row == 0) {
            cell.textLabel.text = @"Bunny Gradient";
            cell.accessoryType = (self.selectedTheme == BPAppThemeGradient) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        } else if (indexPath.row == 1) {
            cell.textLabel.text = @"Classic Dark";
            cell.accessoryType = (self.selectedTheme == BPAppThemeDark) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        } else if (indexPath.row == 2) {
            cell.textLabel.text = @"Classic Light";
            cell.accessoryType = (self.selectedTheme == BPAppThemeLight) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        }
        return cell;
    } else {
        static NSString *SwitchCellId = @"SwitchCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:SwitchCellId];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:SwitchCellId];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            UISwitch *sw = [[UISwitch alloc] init];
            cell.accessoryView = sw;
        }

        UISwitch *sw = (UISwitch *)cell.accessoryView;
        if (indexPath.row == 0) {
            cell.textLabel.text = @"Word Wrap";
            sw.on = YES;
        } else {
            cell.textLabel.text = @"Show Status Bar";
            sw.on = YES;
        }
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0) {
        self.selectedTheme = (BPAppTheme)indexPath.row;
        [BPTheme setCurrentTheme:self.selectedTheme];
        [self applyTheme];
        [self.tableView reloadData];
    }
}

@end
