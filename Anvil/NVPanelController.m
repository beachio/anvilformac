#import "NVPanelController.h"
#import "NVBackgroundView.h"
#import "NVStatusItemView.h"
#import "NVMenubarController.h"
#import "NVTableRowView.h"
#import "NVTableCellView.h"
#import "NVAppDelegate.h"
#import "NVGroupHeaderTableRowView.h"
#import "NVGroupHeaderTableCellView.h"
#import <QuartzCore/QuartzCore.h>
#import <Sparkle/Sparkle.h>

#define SEARCH_INSET 15

#define OPEN_DURATION .15
#define CLOSE_DURATION .1

#define POPUP_HEIGHT 122
#define PANEL_WIDTH 256

#define WINDOW_VERTICAL_OFFSET 7

#define MENU_ANIMATION_DURATION .1

#define HEADER_HEIGHT 34

#pragma mark -

@interface NVPanelController ()
@property (nonatomic) NSInteger selectedRow;
@property (nonatomic) BOOL isEditing;
@property (nonatomic) BOOL isShowingModal;
@property (nonatomic) BOOL panelIsOpen;
@property (nonatomic) BOOL isPowRunning;
@property (atomic, strong) NSTrackingArea *trackingArea;
@property (nonatomic) BOOL forceOpen;
@property (nonatomic) BOOL awake;
@property (nonatomic) NSTimer *powCheckerTimer;
@property (nonatomic) NSInteger indexOfRowBeingEdited;
@property (strong, nonatomic) NSString *ip;
@property (strong, nonatomic) NVDataSource *dataSource;

@property (strong, nonatomic) NSFileHandle *taskOutput;

@end

@implementation NVPanelController

static NSString *const kAppListTableCellIdentifier = @"appListTableCellIdentifier";
static NSString *const kAppListTableRowIdentifier = @"appListTableRowIdentifier";
static NSString *const kPanelTrackingAreaIdentifier = @"panelTrackingIdentifier";

static NSString *const kPowPath = @"/Library/LaunchDaemons/cx.pow.firewall.plist";

#pragma mark - Initialization

- (id)initWithWindowNibName:(NSString *)windowNibName {
    
    self = [super initWithWindowNibName:windowNibName];
    
    if (self != nil) {
        
        self.dataSource = [NVDataSource sharedDataSource];
        
        self.isEditing = NO;
        
        // Make a fully skinned panel
        NSPanel *panel = (id)[self window];

        [panel setLevel:NSPopUpMenuWindowLevel];
        [panel setOpaque:NO];
        [panel setBackgroundColor:[NSColor clearColor]];
        
        self.switchView.delegate = self;
        
        [self.switchLabel setAlphaValue:0.9999999];
        [self.headerView makeTransparent];
        self.headerView.backgroundImage = [NSImage imageNamed:@"Titlebar"];
        self.headerIconView.backgroundImage = [NSImage imageNamed:@"TitlebarIcon"];
        
        self.backgroundView.backgroundColor = [NSColor colorWithDeviceRed:244.0/255.0 green:244.0/255.0 blue:244.0/255.0 alpha:1];
        
        self.appListTableView.menu = [self menuForTableView];
        self.appListTableView.action = @selector(appListTableViewClicked:);
        self.appListTableView.backgroundColor = [NSColor colorWithDeviceRed:244.0/255.0 green:244.0/255.0 blue:244.0/255.0 alpha:1];
        self.appListTableView.delegate = self;
        
        self.appListTableScrollView.wantsLayer = YES;
        self.appListTableScrollView.layer.opaque = NO;
//        self.appListTableScrollView.layer.cornerRadius = 0;
        self.appListTableScrollView.backgroundColor = [NSColor clearColor];
        [self.appListTableView setIntercellSpacing:NSMakeSize(0, 0)];
        
        NSShadow *shadow = [[NSShadow alloc] init];
        shadow.shadowColor = [NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:0.4];
        shadow.shadowOffset = NSMakeSize(0, -1);
        shadow.shadowBlurRadius = 0.0;
        self.switchLabel.textShadow = shadow;
        
        self.addButton.image            = [NSImage imageNamed:@"AddButton"];
        self.addButton.alternateImage   = [NSImage imageNamed:@"AddButtonPushed"];
        
        self.settingsDivider.backgroundImage = [NSImage imageNamed:@"TitlebarSplit"];
        
        [self setupSettingsButton];
        
        self.installPowButton.image = [NSImage imageNamed:@"BlueButton"];
        self.installPowButton.alternateImage = [NSImage imageNamed:@"BlueButtonPushed"];
        self.installPowButton.isBold = NO;
        self.installPowButton.textSize = 12.0;
        
        self.noSitesAddASiteButton.image = [NSImage imageNamed:@"ButtonAdd"];
        self.noSitesAddASiteButton.alternateImage = [NSImage imageNamed:@"ButtonAddPushed"];
        [self.noSitesAddASiteButton setInsetsWithTop:1.0 right:5.0 bottom:1.0 left:25.0];
        self.noSitesAddASiteButton.textSize = 12.0;
        self.noSitesAddASiteButton.isBold = NO;
        
        CGRect frame = self.welcomeView.frame;
        [self.welcomeView setFrame:CGRectMake(frame.origin.x,
                                              self.backgroundView.frame.size.height - frame.size.height - HEADER_HEIGHT,
                                              frame.size.width,
                                              frame.size.height)];
        
        frame = self.noAppsView.frame;
        [self.noAppsView setFrame:CGRectMake(frame.origin.x,
                                             self.backgroundView.frame.size.height - frame.size.height - HEADER_HEIGHT,
                                             frame.size.width,
                                             frame.size.height)];
        
        self.isPowRunning = YES;
        [self performSelectorInBackground:@selector(checkWhetherPowIsRunning) withObject:nil];
    }
    
    return self;
}

- (void)awakeFromNib {
    
    if (!self.awake) {
        
        [super awakeFromNib];
        [self.appListTableView reloadData];
        [self switchSwitchViewToPowStatus];
        self.awake = YES;
        
        self.powCheckerTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(switchSwitchViewToPowStatus) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:self.powCheckerTimer forMode:NSRunLoopCommonModes];
        
        // Draw it off-screen sure
        [self.window setFrameOrigin:NSMakePoint(10000, 10000)];
        [self.window makeKeyAndOrderFront:nil];
        [self.window resignKeyWindow];
        
        // Give the NSScrollView a backing layer and set its corner radius.
        
//        [self.backgroundView setWantsLayer:YES];
//        [self.backgroundView.layer setCornerRadius:4.0f];
        
        [self.appListTableScrollView setWantsLayer:YES];
        [self.appListTableScrollView.layer setCornerRadius:4.0f];
        
        // Give the NSScrollView's internal clip view a backing layer and set its corner radius.
        [self.appListTableScrollView.contentView setWantsLayer:YES];
        [self.appListTableScrollView.contentView.layer setCornerRadius:4.0f];
    }
}

// Destroys and recreates the tracking area for this table.
- (void)createTrackingArea {
    
    if (!self.hasActivePanel) {
        return;
    }
    
    if (self.trackingArea) {
        
        [self.appListTableView removeTrackingArea:self.trackingArea];
        self.trackingArea = nil;
    }
    
    int opts = (NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingInVisibleRect | NSTrackingActiveAlways);
    self.trackingArea = [ [NSTrackingArea alloc] initWithRect:self.backgroundView.frame
                                                      options:opts
                                                        owner:self
                                                     userInfo:[NSDictionary dictionaryWithObject:kPanelTrackingAreaIdentifier forKey:@"identifier"]];
    [[self appListTableView] addTrackingArea:self.trackingArea];
}

#pragma mark - Generators

- (void)setupSettingsButton {
    
    self.settingsButton.image           = [NSImage imageNamed:@"SettingsButton"];
    self.settingsButton.alternateImage  = [NSImage imageNamed:@"SettingsButtonPushed"];
    
    NSMenu *settingsMenu = [self buildSettingsMenu];
    
    self.settingsButton.menu = settingsMenu;
    self.settingsButton.preferredEdge = NSMaxYEdge;
    self.settingsButton.pullsDown = YES;
    [self.settingsButton selectItem:nil];
    
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:@""
                                                  action:NULL
                                           keyEquivalent:@""];
    item.image = [NSImage imageNamed:@"SettingsButton"];
    item.onStateImage = nil;
    item.mixedStateImage = nil;
    
    NSPopUpButtonCell *cell = [self.settingsButton cell];
    cell.menuItem = item;
    cell.bordered = NO;
    cell.imagePosition = NSImageOnly;
    cell.arrowPosition = NSPopUpNoArrow;
    cell.usesItemFromMenu = NO;
    cell.alternateImage = [NSImage imageNamed:@"SettingsButtonPushed"];
}

- (NSMenu *)buildSettingsMenu {
    
    NSMenu *settingsMenu = [[NSMenu alloc] initWithTitle:@"Settings"];
    [settingsMenu addItem:[[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@""]]; // First one gets eaten by the dropdown button. It's weird.
    
    // TODO: about window
    [settingsMenu addItem:[[NSMenuItem alloc] initWithTitle:@"About Anvil" action:@selector(didClickShowAbout:) keyEquivalent:@""]];
    [settingsMenu addItem:[[NSMenuItem alloc] initWithTitle:@"Check for Updates..." action:@selector(didClickCheckForUpdates:) keyEquivalent:@""]];
    [settingsMenu addItem:[[NSMenuItem alloc] initWithTitle:@"Support & FAQs" action:@selector(didClickSupportMenuItem:) keyEquivalent:@""]];
    [settingsMenu addItem:[NSMenuItem separatorItem]];
    [settingsMenu addItem:[[NSMenuItem alloc] initWithTitle:@"Restart Pow" action:@selector(didClickRestartPow:) keyEquivalent:@""]];
    [settingsMenu addItem:[[NSMenuItem alloc] initWithTitle:@"Uninstall Pow" action:@selector(uninstallPow:) keyEquivalent:@""]];
    [settingsMenu addItem:[[NSMenuItem alloc] initWithTitle:@"Quit" action:@selector(didClickQuit:) keyEquivalent:@""]];
    
    return settingsMenu;
}

#pragma mark - SwitchView and Pow

- (void)switchSwitchViewToPowStatus {
    
    if (self.hasActivePanel) {
        self.selectedRow = -1;
//        BOOL status = [self checkWhetherPowIsRunning];
//        self.isPowRunning = status;

        [self.switchView switchToWithoutCallbacks:self.isPowRunning withAnimation:YES];
        self.switchLabel.text = self.isPowRunning ? @"ON" : @"OFF";
    }
}

- (BOOL)switchView:(NVSwitchView *)switchView shouldSwitchTo:(BOOL)state {

    if (!self.hasActivePanel) {
        return NO;
    }
    
    if (self.isPowRunning == state) {
        return YES;
    }
    
    BOOL success = false;
    
    [NSApp activateIgnoringOtherApps:YES];
    [self.window becomeMainWindow];

    BOOL a, b;
    
    if (state) {
        a = [self runTask:@"/bin/launchctl load /Library/LaunchDaemons/cx.pow.firewall.plist" asRoot:YES];
        b = [self runTask:[NSString stringWithFormat:@"/bin/launchctl load %@/Library/LaunchAgents/cx.pow.powd.plist", NSHomeDirectory()] asRoot:NO];
    } else {
        a = [self runTask:@"/bin/launchctl unload /Library/LaunchDaemons/cx.pow.firewall.plist" asRoot:YES];
        b = [self runTask:[NSString stringWithFormat:@"/bin/launchctl unload %@/Library/LaunchAgents/cx.pow.powd.plist", NSHomeDirectory()] asRoot:NO];
    }
    success = a & b;
    
    [NSApp activateIgnoringOtherApps:YES];
    [self.window becomeMainWindow];

    [self checkWhetherPowIsRunning];
    
    [self performSelector:@selector(checkWhetherPowIsRunning) withObject:nil afterDelay:1.0];
    [self performSelector:@selector(checkWhetherPowIsRunning) withObject:nil afterDelay:2.0];

    [self forcePanelToBeOpen];
    
    [self performSelector:@selector(allowToBeClosed) withObject:nil afterDelay:0.5];
    
    // Don't change by yourself you plonker
    return NO;
}

- (BOOL)runTask:(NSString *)task asRoot:(BOOL)asRoot {
    
    NSDictionary *error = [NSDictionary new];
    NSString *script = [NSString stringWithFormat:@"do shell script \"%@\"", task];
    if (asRoot) {
        script = [script stringByAppendingString:@" with administrator privileges"];
    }
    [[[NSAppleScript new] initWithSource:script] executeAndReturnError:&error];
    if (error.count > 0) {
        NSLog(@"Error running Applescript: %@", error);
    }
    return !error;
}

#pragma mark - Public accessors

- (BOOL)hasActivePanel {
    
    return _hasActivePanel;
}

// We're obvserving hasActivePanel everywhere using key/value observers.
// That value determines whether or not we have an open panel using this method!
// This should probably be based on methods instead. At least this way it only runs once.
- (void)setHasActivePanel:(BOOL)flag {
    
    if (self.isShowingModal) {
        
        return;
    }
    
    if (_hasActivePanel != flag) {
        
        _hasActivePanel = flag;
        if (_hasActivePanel) {
            
            [self openPanel];
        } else {
            
            [self closePanel];
        }
    }
}

#pragma mark - NSWindowDelegate

- (void)windowWillClose:(NSNotification *)notification {
    
    if (!self.forceOpen) {
        self.hasActivePanel = NO;
    }
}

- (void)windowDidResignKey:(NSNotification *)notification; {

    if ([[self window] isVisible] && !self.forceOpen) {
        self.hasActivePanel = NO;
    }
}

- (void)windowDidResize:(NSNotification *)notification {
    
    NSWindow *panel = [notification object];

    NSRect statusRect = [self statusRect];
    NSRect panelRect = panel.frame;

    CGFloat statusX = roundf(NSMidX(statusRect));
    CGFloat panelX = statusX - NSMinX(panelRect);

    self.backgroundView.arrowX = panelX;
    
    // TODO: Make this clip with rounded corners
    NSInteger appListHeight = panel.frame.size.height - HEADER_HEIGHT - 5;
    self.appListTableScrollView.frame = NSMakeRect(0, 0, PANEL_WIDTH, appListHeight);
}

#pragma mark - Keyboard

- (void)cancelOperation:(id)sender {
    
    self.hasActivePanel = NO;
}

#pragma mark - Public methods

- (void)openPanel {
    
    [self.appListTableView reloadData];
    [self checkWhetherPowIsRunning];
    [self updatePanelHeightAndAnimate:self.panelIsOpen];
    
    self.panelIsOpen = YES;
    
    [self.window makeFirstResponder:nil];
    [self.window becomeMainWindow];
    [self.window makeKeyAndOrderFront:nil];
    
    [self performSelector:@selector(switchSwitchViewToPowStatus) withObject:nil afterDelay:0.5];
    [self performSelector:@selector(switchSwitchViewToPowStatus) withObject:nil afterDelay:1.0];
}

- (void)closePanel {
    
    self.panelIsOpen = NO;
    
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:(0.1)];
    [self.window.animator setAlphaValue:0];
    [NSAnimationContext endGrouping];
    [self.window close];
}

- (BOOL)isPowInstalled {
    
    BOOL isDirectory;
    BOOL isThere = [[NSFileManager defaultManager] fileExistsAtPath:kPowPath isDirectory:&isDirectory];
    return isThere && !isDirectory;
}

- (void)forcePanelToBeOpen {
    self.forceOpen = YES;
}

// When forced open, this allows the window to be closed again.
- (void)allowToBeClosed {
    
    if (self.forceOpen) {
        self.forceOpen = NO;
    }
}

- (NSRect)statusRect {
    
    NSRect screenRect = [[[NSScreen screens] objectAtIndex:0] frame];
    NSRect statusRect = NSZeroRect;
    
    NVStatusItemView *statusItemView = nil;
    if ([self.delegate respondsToSelector:@selector(statusItemViewForPanelController:)]) {
        statusItemView = [self.delegate statusItemViewForPanelController:self];
    }
    
    if (statusItemView) {
        statusRect = statusItemView.globalRect;
        statusRect.origin.y = NSMinY(statusRect) - NSHeight(statusRect);
    } else {
        statusRect.size = NSMakeSize(STATUS_ITEM_VIEW_WIDTH, [[NSStatusBar systemStatusBar] thickness]);
        statusRect.origin.x = roundf((NSWidth(screenRect) - NSWidth(statusRect)) / 2);
        statusRect.origin.y = NSHeight(screenRect) - NSHeight(statusRect) * 2;
    }
    return statusRect;
}

#pragma mark - Sizing

- (NSInteger *)numberOfNonHammerSites {
    
    return self.dataSource.apps.count - self.dataSource.hammerApps.count;
}

- (BOOL)hasHammerSites {
    
    return (int)self.dataSource.numberOfHammerSites > 0;
}

- (void)updatePanelHeightAndAnimate:(BOOL)shouldAnimate {
    
    if (!self.hasActivePanel) {
        NSLog(@"An attempt to update the panel height was made while the panel was closed! :(");
        return;
    }

    [self.appListTableView sizeToFit];
    
    NSWindow *panel = [self window];
    NSRect panelRect = panel.frame;
    NSRect statusRect = [self statusRect];
    
    NSInteger panelHeight = (self.appListTableView.rowHeight + self.appListTableView.intercellSpacing.height) * [self.appListTableView numberOfRows] + ARROW_HEIGHT + HEADER_HEIGHT;
    
    if ([self hasHammerSites]) {
        
        // THE MAGIC NUMBER
        // TODO: Make this cleverer about the actual difference in heights.
        panelHeight += 2;
    } else {
        
        panelHeight += 11;
    }

    // Set our maximum height
    NSInteger maxHeight = round([[NSScreen mainScreen] frame].size.height / 2);
    if (panelHeight > maxHeight) {
        
        panelHeight = maxHeight;
    }

    panelRect.origin.x = roundf(NSMidX(statusRect) - NSWidth(panelRect) / 2);
    
    // Better make sure the panel's inside the window.
    NSRect screenRect = [[[NSScreen screens] objectAtIndex:0] frame];
    if (NSMaxX(panelRect) > (NSMaxX(screenRect) - ARROW_HEIGHT))
        panelRect.origin.x -= NSMaxX(panelRect) - (NSMaxX(screenRect) - ARROW_HEIGHT);
    
    CGRect menuBarViewFrame = [self.delegate globalMenubarViewFrame];
    
    NSInteger bottomOfMenubarViewOffset = menuBarViewFrame.origin.y - WINDOW_VERTICAL_OFFSET;
    
    // This is the y-position of the panel. Bottom of the menubar icon frame, minus its height.
    NSInteger panelY = bottomOfMenubarViewOffset - panelHeight;
    
    panelRect = CGRectMake(panelRect.origin.x, panelY, PANEL_WIDTH, panelHeight);

    if (![self isPowInstalled]) {
        
        self.appListTableView.hidden = YES;
        self.appListTableScrollView.hidden = YES;
        self.noAppsView.hidden = YES;
        self.welcomeView.hidden = NO;
        
        // In this case, appListTableView can actually be tall without being visible!
        // 24 is the menubar height. 6 is the arrow height. HEADER_HEIGHT is the header height.
        // TODO: Clean up these numbers.

        panelHeight = self.welcomeView.frame.size.height + HEADER_HEIGHT + ARROW_HEIGHT;
        NSInteger panelY = bottomOfMenubarViewOffset - panelHeight - WINDOW_VERTICAL_OFFSET;
        panelRect = CGRectMake(panelRect.origin.x, panelY, PANEL_WIDTH, panelHeight);
        
    } else if ([[self.dataSource apps] count] == 0) {
        
        self.appListTableView.hidden = YES;
        self.appListTableScrollView.hidden = YES;
        self.noAppsView.hidden = NO;
        self.welcomeView.hidden = YES;
//        
//        panelRect.origin.y -= self.noAppsView.frame.size.height;
//        panelRect.size.height += self.noAppsView.frame.size.height;
        
        panelHeight = self.noAppsView.frame.size.height + HEADER_HEIGHT + ARROW_HEIGHT;
        NSInteger panelY = bottomOfMenubarViewOffset - panelHeight - WINDOW_VERTICAL_OFFSET;
        panelRect = CGRectMake(panelRect.origin.x, panelY, PANEL_WIDTH, panelHeight);

        
    } else {
        self.appListTableView.hidden = NO;
        self.appListTableScrollView.hidden = NO;
        self.noAppsView.hidden = YES;
        self.welcomeView.hidden = YES;
    }
    
    [panel setAlphaValue:1];
    
    if (shouldAnimate) {
        [[[self window] animator] setFrame:panelRect display:YES];
    } else {
        [self.window setFrame:panelRect display:YES];
    }
    
    // Fuck you, Cocoa. Why doesn't createTrackingArea work here? Why?
    // Is this some kind of race condition? Are you making me do this just to mess with me?
    // I'll never know. I leave you with a haiku.
    // Do not touch this bit -
    // It has caused me much despair!
    // This should do the trick.
    [self createTrackingArea];
    [self performSelector:@selector(createTrackingArea) withObject:NULL afterDelay:0.3];
    [self performSelector:@selector(createTrackingArea) withObject:NULL afterDelay:1.0];
}

#pragma mark - Alternate panels

- (void)renderAlternatePanels {
    
    [self.appListTableView setHidden:YES];
    
    if ([[self.dataSource apps] count] > 0) {
        
    } else {
        [self.noAppsView setHidden:NO];
        [self.noAppsView setFrame:self.window.frame];
    }
}

#pragma mark - Table View Delegate

- (BOOL)selectionShouldChangeInTableView:(NSTableView *)aTableView {
    
    return NO;
}

- (BOOL)tableView:(NSTableView *)tableView shouldTrackCell:(NSCell *)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    
    return YES;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {

    NSInteger sites = self.dataSource.apps.count + self.dataSource.hammerApps.count;

    if (self.dataSource.hammerApps.count > 0) {
        
        sites += 1;
    }
    
    return sites;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    
    if (self.isEditing) {
        return;
    }
    
    self.appListTableView.menu = nil;
    self.appListTableView.menu = [self menuForTableView];
    
    [self clearRows];
}

- (void)clearRows {
    
    int i = 0;
    
    while (i < self.appListTableView.numberOfRows) {
        
        NSTableCellView *view = [self.appListTableView viewAtColumn:0 row:i makeIfNecessary:NO];
        
        if (view && i == self.appListTableView.selectedRow && i < [self hammerGroupHeaderRowNumber]) {
            
            [[self.appListTableView rowViewAtRow:i makeIfNecessary:NO] setBackgroundColor:[NSColor whiteColor]];
            [[self.appListTableView viewAtColumn:0 row:i makeIfNecessary:NO] showControls];
            [[self.appListTableView rowViewAtRow:i makeIfNecessary:NO] setNeedsDisplay:YES];
        } else {
            
            [[self.appListTableView rowViewAtRow:i makeIfNecessary:NO] setBackgroundColor:[NSColor clearColor]];
            [[self.appListTableView viewAtColumn:0 row:i makeIfNecessary:NO] setNeedsDisplay:YES];
            [[self.appListTableView viewAtColumn:0 row:i makeIfNecessary:NO] hideControls];
        }
        
        self.selectedRow = self.appListTableView.selectedRow;
        
        i++;
    }
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    
    NVApp *app;
    NVTableCellView *cellView = (NVTableCellView *)[tableView makeViewWithIdentifier:kAppListTableCellIdentifier owner:self];
    
    NSInteger hammerGroupHeaderRowNumber = [self hammerGroupHeaderRowNumber];
    
    if (row < hammerGroupHeaderRowNumber) {
        
        app = [self.dataSource.apps objectAtIndex:row];
    } else if (row > hammerGroupHeaderRowNumber && row > 0){
        
        cellView.isHammer = YES;
        long hammerGroupRow = row - self.dataSource.apps.count - 1;
        app = [self.dataSource.hammerApps objectAtIndex:hammerGroupRow];
    } else if (row == hammerGroupHeaderRowNumber){
        
        return [[NVGroupHeaderTableCellView alloc] init];
    }
    
    if (cellView.isHammer) {
        
        [cellView.siteLabel setText:[app.name stringByReplacingOccurrencesOfString:@".hammer" withString:@""]];
    } else {
        
        [cellView.siteLabel setText:app.name];
    }
    
    cellView.darkTopBorder = (row == (hammerGroupHeaderRowNumber+1));
    
    cellView.hideBottomBorder = NO;
    cellView.hideTopBorder = NO;
    if (row == self.dataSource.apps.count + self.dataSource.hammerApps.count) {
        
        cellView.hideBottomBorder = YES;
    } else if(row == 0) {
        
        cellView.hideTopBorder = YES;
    }
    
    [cellView.siteLabel setTextColor:[NSColor colorWithDeviceRed:68.0/255.0 green:68.0/255.0 blue:68.0/255.0 alpha:1.0]];
    [cellView.siteLabel setEnabled:NO];
    [cellView.siteLabel sizeToFit];
    cellView.siteLabel.delegate = self;
    [cellView.siteLabel setWidth];
    
    [cellView hideControls];
    [cellView.siteLabel setWidth];
    
//    [cellView resizeSubviewsWithOldSize:cellView.frame.size];
    
    cellView.showRestartButton = [app isARackApp];
    
    if (app.faviconURL) {
    
        cellView.faviconImageView.backgroundImage = [NSImage imageNamed:@"SiteIcon"];
        NSImage *faviconImage = [[NSImage alloc] initWithContentsOfURL:app.faviconURL];
        cellView.faviconImageView.foregroundImage = [self imageRepresentationOfImage:faviconImage
                                                                            withSize:NSMakeSize(16, 16)];
    } else {
        
//        cellView.faviconImageView.backgroundImage = [NSImage imageNamed:@"SiteIconDefault"];
        cellView.faviconImageView.foregroundImage = nil;
    }

    return cellView;
}

- (BOOL)tableView:(NSTableView *)tableView isGroupRow:(NSInteger)row {
    
    return row == [self hammerGroupHeaderRowNumber];
}

- (double)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    
    NSInteger groupHeaderRowNumber = [self hammerGroupHeaderRowNumber];
    if (row == (groupHeaderRowNumber + 1)) {
        
        return 33;
    } else if (row == groupHeaderRowNumber - 1) {
        
        return 33;
    } else if (row == groupHeaderRowNumber) {
        
        return 24;
    } else {
        
        return 33;
    }
}

- (NSInteger)hammerGroupHeaderRowNumber {
    
    int number = (int)[NVDataSource sharedDataSource].apps.count; //- (int)[NVDataSource sharedDataSource].hammerApps.count + 1;

    if ((int)[NVDataSource sharedDataSource].numberOfHammerSites == 0) {
        
        return number + 100;
    }
    
    return number;
}

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row {
    
    // Hammer sites bar
    NSInteger groupHeaderRowNumber = [self hammerGroupHeaderRowNumber];
    
    if (row == groupHeaderRowNumber) {
        
        NVGroupHeaderTableRowView *rowView = [[NVGroupHeaderTableRowView alloc] init];
        return rowView;
    }
    
    NVTableRowView *rowView = (NVTableRowView *)[tableView makeViewWithIdentifier:kAppListTableRowIdentifier owner:self];
    
    if (rowView == nil) {
        
        rowView = [[NVTableRowView alloc] init];
        rowView.identifier = kAppListTableRowIdentifier;
    }
    
    rowView.darkTopBorder = (row == (groupHeaderRowNumber + 1));
//    rowView.hideTopBorder    = (row == (groupHeaderRowNumber + 1));
//    rowView.hideBottomBorder = (row == (groupHeaderRowNumber - 1));

    return rowView;
}

- (NSImage *)imageRepresentationOfImage:(NSImage *)image withSize:(NSSize)size {
    
    NSImage *requestedRepresentationImage = nil;
    for (NSBitmapImageRep *representation in image.representations) {
        
        if (CGSizeEqualToSize(representation.size, size)) {
            requestedRepresentationImage = [[NSImage alloc] initWithData:[representation TIFFRepresentation]];
        }
    }
    
    return requestedRepresentationImage;
}

#pragma mark - Mouse moving in the table view
// Mouse movements are handled here for selecting rows

- (void)highlightRow:(NSInteger)row {
    
    if (!self.isEditing) {
        
        for (int i = 0; i<self.appListTableView.numberOfRows; i++) {
            
            NVTableCellView *cellView = [self.appListTableView viewAtColumn:0 row:i makeIfNecessary:NO];
            
            if ([cellView isKindOfClass:[NVTableCellView class]]) {
                
                if (i == row) {
                    
                    if (!cellView.isHovered) {
                        [cellView setIsHovered:YES];
                        [cellView setNeedsDisplay:YES];
                    }
                } else {
                    
                    if (cellView.isHovered) {
                        [cellView setIsHovered:NO];
                        [cellView setNeedsDisplay:YES];
                    }
                }
            }
            
        }
        
        [self.appListTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    }

}

- (void)mouseMoved:(NSEvent *)theEvent {
    
    NSPoint point = [self.appListTableView convertPoint:[theEvent locationInWindow] fromView:self.backgroundView];
    NSInteger row = [self.appListTableView rowAtPoint:point];
    
    [self highlightRow:row];
    self.appListTableView.needsDisplay = YES;
    
    self.appListTableView.menu = nil;
    self.appListTableView.menu = [self menuForTableView];
}

- (void)mouseExited:(NSEvent *)theEvent {
    
    NSString *trackingAreaName = [theEvent.trackingArea.userInfo objectForKey:@"identifier"];
    
    if (trackingAreaName == kPanelTrackingAreaIdentifier) {

//        [self.appListTableView deselectRow:self.selectedRow];
        NSIndexSet *rowToSelect = [NSIndexSet indexSetWithIndex:-1];
        [self.appListTableView selectRowIndexes:rowToSelect byExtendingSelection:NO];
        self.selectedRow = -1;
//        [self clearRows];
        self.appListTableView.needsDisplay = YES;
        
        for (int i = 0; i < self.appListTableView.numberOfRows; i++) {
            
            [[self.appListTableView viewAtColumn:0 row:i makeIfNecessary:NO] hideControls];
        }
    }
    
    [self highlightRow:-1];
}

- (void)mouseEntered:(NSEvent *)theEvent {
    
    NSPoint point = [self.appListTableView convertPoint:[theEvent locationInWindow] fromView:self.backgroundView];
    NSInteger row = [self.appListTableView rowAtPoint:point];
    
    if (row >= 0) {
        [self highlightRow:row];
        [[self.appListTableView viewAtColumn:0 row:row makeIfNecessary:NO] showControls];
    }
}

//- (void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)tableColumn {
//    
////    NSEvent *theEvent = [NSApp currentEvent];
////    NSPoint point = [self.appListTableView convertPoint:[theEvent locationInWindow] fromView:self.backgroundView];
////    NSInteger row = [self.appListTableView rowAtPoint:point];
//    
//    NSInteger row = [self.appListTableView clickedRow];
//    
//    NSLog(@"A");
//    if (!self.isEditing && row != [self.appListTableView selectedRow]) {
//        
//        NSLog(@"A");
//        [self.appListTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
//    }
//}

#pragma mark - Renaming

- (void)resizeTextField:(NVLabel *)textField {
    
    NSRect frame = textField.frame;
    
    float fontSize = [[textField.font.fontDescriptor objectForKey:NSFontSizeAttribute] floatValue];
    NSString *fontName = [textField.font.fontDescriptor objectForKey:NSFontNameAttribute];
    
    NSDictionary* attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                fontName, NSFontNameAttribute,
                                [NSNumber numberWithFloat:fontSize], NSFontSizeAttribute,
                                nil];
    
    NSAttributedString* attributedString = [[NSAttributedString alloc] initWithString:textField.text attributes:attributes];
    NSSize size = attributedString.size;
    NSInteger width = (int)size.width + 8;
    
    [textField setFrame:CGRectMake(frame.origin.x, frame.origin.y, width, frame.size.height)];
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector {
    
    if (commandSelector == @selector(cancelOperation:)) {
        
        self.isEditing = NO;
        [self.appListTableView performSelector:@selector(reloadData) withObject:nil afterDelay:0.0];
    }
    return NO;
}

- (void)controlTextDidBeginEditing:(NSNotification *)obj {
    
    
}

- (void)beginEditingRowAtIndex:(NSNumber *)indexNumber {
    
    NSInteger index = [self.appListTableView clickedRow];
    
    if (index > -1 && index < self.appListTableView.numberOfRows) {
        
        NSIndexSet *rowToSelect = [NSIndexSet indexSetWithIndex:index];
        [self.appListTableView selectRowIndexes:rowToSelect byExtendingSelection:NO];
        
        NVTableCellView *cell = (NVTableCellView *)[self.appListTableView viewAtColumn:0 row:index makeIfNecessary:YES];
        self.isEditing = YES;
        
        self.indexOfRowBeingEdited = index;
        
        [cell.textField setEnabled:YES];
        [cell.textField becomeFirstResponder];
    }
}

- (void)controlTextDidChange:(NSNotification *)obj  {
    
    NVLabel *label = [obj object];
    NVTableCellView *tableCellView = (NVTableCellView *)[label superview];
    
    tableCellView.localLabel.hidden =  YES;
    
    [self resizeTextField: [obj object]];
}

- (void)controlTextDidEndEditing:(NSNotification *)obj {
    
    self.isEditing = NO;
    NVLabel *label = [obj object];
    
    NVTableCellView *tableCellView = (NVTableCellView *)[label superview];
    tableCellView.localLabel.hidden =  NO;
    
    if (self.indexOfRowBeingEdited != -1) {
        NVApp *app = (NVApp *)[[NVDataSource sharedDataSource].apps objectAtIndex:self.indexOfRowBeingEdited];
        [app renameTo:label.stringValue];
    }

    self.indexOfRowBeingEdited = -1;
    
    [[NVDataSource sharedDataSource] readInSavedAppDataFromDisk];
    [self.appListTableView reloadData];
}

#pragma mark - Menus

- (NSMenu *)menuForTableView {
    
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Site Menu"];
    
    NSIndexSet *thisIndexSet = [NSIndexSet indexSetWithIndex:self.appListTableView.clickedRow];
    [self.appListTableView selectRowIndexes:thisIndexSet byExtendingSelection:NO];
    
    if (self.appListTableView.selectedRow < self.appListTableView.numberOfRows && self.appListTableView.selectedRow > -1) {
        
        NVApp *app = [self appForSelectedRow:self.appListTableView.selectedRow];
        
        if (app.isARackApp) {
            NSMenuItem *restartApp = [[NSMenuItem alloc] initWithTitle:@"Restart" action:@selector(didClickRestartButton:) keyEquivalent:@""];
            [menu addItem:restartApp];
        }
        
        NSMenuItem *openInFinderMenuItem = [[NSMenuItem alloc] initWithTitle:@"Open in Finder" action:@selector(didClickOpenInFinder:) keyEquivalent:@""];
        [menu addItem:openInFinderMenuItem];
        NSMenuItem *openInTerminalMenuItem = [[NSMenuItem alloc] initWithTitle:@"Open in Terminal" action:@selector(didClickOpenInTerminal:) keyEquivalent:@""];
        [menu addItem:openInTerminalMenuItem];

        
        if ([self ipAddress]) {
            [menu addItem:[NSMenuItem separatorItem]];
            
            NSString *ipMenuItemName = [NSString stringWithFormat:@"%@.%@.xip.io", app.name, [self ipAddress]];
            NSMenuItem *xipIOMenuItem = [[NSMenuItem alloc] initWithTitle:ipMenuItemName action:@selector(didClickOpenInXipIo:) keyEquivalent:@""];
            xipIOMenuItem.enabled = NO;
            xipIOMenuItem.indentationLevel = 0;
            [menu addItem:xipIOMenuItem];
            
            NSString *copyItemName = @"Copy to Clipboard";
            NSMenuItem *copyItem = [[NSMenuItem alloc] initWithTitle:copyItemName action:@selector(didClickCopyXipIo:) keyEquivalent:@""];
            copyItem.indentationLevel = 1;
            [menu addItem:copyItem];

            NSString *openItemName = @"Open in Browser";
            NSMenuItem *openItem = [[NSMenuItem alloc] initWithTitle:openItemName action:@selector(didClickOpenInXipIo:) keyEquivalent:@""];
            openItem.indentationLevel = 1;
            [menu addItem:openItem];
        }
    }


    if (self.appListTableView.selectedRow < [self hammerGroupHeaderRowNumber]) {
        
        [menu addItem:[NSMenuItem separatorItem]];
        
        NSMenuItem *renameMenuItem = [[NSMenuItem alloc] initWithTitle:@"Rename" action:@selector(didClickRename:) keyEquivalent:@""];
        NSMenuItem *removeMenuItem = [[NSMenuItem alloc] initWithTitle:@"Remove" action:@selector(didClickRemove:) keyEquivalent:@""];
        [menu addItem:renameMenuItem];
        [menu addItem:removeMenuItem];
    }
    [menu setAutoenablesItems:NO];
    
    return menu;
}

- (void)didClickCopyXipIo:(id)sender {
    
    NSInteger clickedRow = self.appListTableView.selectedRow;
    NVDataSource *dataSource = [NVDataSource sharedDataSource];
    NVApp *app = [dataSource.apps objectAtIndex:clickedRow];
    
    NSString *xipString = [NSString stringWithFormat:@"http://%@.%@.xip.io/", app.name, [self ipAddress]];
    
    NSPasteboard *pboard = [NSPasteboard generalPasteboard];
    [pboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:self];
    [pboard setString:xipString forType:NSStringPboardType];
    
    self.hasActivePanel = NO;
}

- (void)didClickOpenInXipIo:(id)sender {
    
    NSInteger clickedRow = self.appListTableView.selectedRow;
    NVDataSource *dataSource = [NVDataSource sharedDataSource];
    NVApp *app = [dataSource.apps objectAtIndex:clickedRow];

    NSString *xipString = [NSString stringWithFormat:@"http://%@.%@.xip.io/", app.name, [self ipAddress]];

    NSURL *ipURL = [[NSURL alloc] initWithString:xipString];
    [[NSWorkspace sharedWorkspace] openURL:ipURL];

    self.hasActivePanel = NO;    
}

- (NSString *)ipAddress {
    
    if ([self.ip isNotEqualTo:nil]) {
        
        return self.ip;
    }
    
    // Cycle through ethernet and AirPort looking for our IP.
    for (NSString *interface in @[@"en1", @"en0"]) {
        
        NSTask *ipTask = [[NSTask alloc] init];
        ipTask.launchPath = @"/usr/sbin/ipconfig";
        ipTask.arguments = @[@"getifaddr", interface];
        NSPipe *pipe = [[NSPipe alloc] init];;
        ipTask.standardOutput = pipe;
        [ipTask launch];
        [ipTask waitUntilExit];
        
        NSData *pipeData        = [[pipe fileHandleForReading] readDataToEndOfFile];
        NSString *pipeString    = [[NSString alloc] initWithData:pipeData encoding:NSUTF8StringEncoding];
        
        // It's blank when it's not assigned
        if ([pipeString length] > 0) {
            
            NSString *ip = [pipeString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
            self.ip = ip;
            return ip;
        }
        
    }
    
    self.ip = false;
    return false;
}

- (void)appListTableViewClicked:(id)sender {
    
    if (self.appListTableView.clickedRow != self.appListTableView.selectedRow) {
        
        return;
    }
    
    NSEvent *theEvent = [NSApp currentEvent];
    
    if ([theEvent modifierFlags] & NSControlKeyMask) //Command + LMB
    {
        
        [NSMenu popUpContextMenu:self.appListTableView.menu withEvent:theEvent forView:self.appListTableView];
    } else {
        
        NVApp *app = [self appForSelectedRow:self.appListTableView.clickedRow];
        
        if (app) {
            [[NSWorkspace sharedWorkspace] openURL:app.browserURL];
            self.hasActivePanel = NO;
        }
    }
}

- (NVApp *)appForSelectedRow:(NSInteger)row {
    
//    NSInteger realRowIndex = selectedRow;
//    NSInteger hammerGroupHeaderRowNumber = [self hammerGroupHeaderRowNumber];
    
    NVApp *app;
    NSInteger hammerGroupHeaderRowNumber = [self hammerGroupHeaderRowNumber];
    if (row < hammerGroupHeaderRowNumber) {
        
        app = [self.dataSource.apps objectAtIndex:row];
    } else if (row > hammerGroupHeaderRowNumber && row > 0){
        
        row = row - self.dataSource.apps.count - 1;
        app = [self.dataSource.hammerApps objectAtIndex:row];
    } else {
        return nil;
    }
//    
//    if (selectedRow > hammerGroupHeaderRowNumber) {
//
//        realRowIndex -= 1;
//    } else if(selectedRow == hammerGroupHeaderRowNumber) {
//        
//        return nil;
//    }
//    
//    NVDataSource *dataSource = [NVDataSource sharedDataSource];
//    NVApp *app;
//    if (realRowIndex < dataSource.apps.count) {
//        app = [dataSource.apps objectAtIndex:realRowIndex];
//    } else {
//        return nil;
//    }
    return app;
}

- (void)setSelectionFromClick{
    
    NSInteger theClickedRow = [self.appListTableView clickedRow];
    NSIndexSet *thisIndexSet = [NSIndexSet indexSetWithIndex:theClickedRow];
    [self.appListTableView selectRowIndexes:thisIndexSet byExtendingSelection:NO];
}

#pragma mark - Pow 

- (void)installPow:(id)sender {

    NSTask *task = [[NSTask alloc] init];
    
    [task setLaunchPath:@"/bin/sh"];
    
//    NSString *installPowPath = [[NSBundle mainBundle] pathForResource:@"InstallPow" ofType:@"sh"];
//    NSString *command = [NSString stringWithFormat:
//                   @"tell application \"Terminal\" to do script \"/bin/sh \\\"%@\\\"; exit\"", installPowPath];
    
    NSString *command = @"curl get.pow.cx | sh";
    command = [NSString stringWithFormat:@"tell application \"Terminal\" to do script \"%@\"", command];
    
    NSAppleScript *as = [[NSAppleScript alloc] initWithSource: command];
    
    [as executeAndReturnError:nil];
    
    NSString *command2 = [NSString stringWithFormat:
                         @"tell application \"Terminal\" to activate"];
    
    NSAppleScript *as2 = [[NSAppleScript alloc] initWithSource: command2];
    
    [as2 executeAndReturnError:nil];
}

- (void)uninstallPow:(id)sender {
    
    self.hasActivePanel = NO;
    
    NSTask *task = [[NSTask alloc] init];
    
    [task setLaunchPath:@"/bin/sh"];
    
    NSString *command = [NSString stringWithFormat:
                         @"tell application \"Terminal\" to do script \"curl get.pow.cx/uninstall.sh | sh\""];
    
    NSAppleScript *as = [[NSAppleScript alloc] initWithSource: command];
    
    [as executeAndReturnError:nil];
    
    NSString *command2 = [NSString stringWithFormat:
                          @"tell application \"Terminal\" to activate"];
    
    NSAppleScript *as2 = [[NSAppleScript alloc] initWithSource: command2];
    
    [as2 executeAndReturnError:nil];

}

- (void)restartPow:(id)sender {

    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/usr/bin/touch"];
    [task setArguments:[NSArray arrayWithObjects:[@"~/.pow/restart.txt" stringByExpandingTildeInPath], nil]];
    [task launch];
}

- (BOOL)checkWhetherPowIsRunning {

    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/usr/bin/curl"];
    [task setArguments:[NSArray arrayWithObjects:@"-I", @"--silent", @"--connect-timeout", @"5", @"-H", @"host:pow", @"localhost:20559/status.json", nil]];
    
    NSPipe *outputPipe = [NSPipe pipe];
    [task setStandardInput:[NSPipe pipe]];
    [task setStandardError:[NSPipe pipe]];
    [task setStandardOutput:outputPipe];
    [task launch];
//    [task waitUntilExit];
    
    self.taskOutput = [outputPipe fileHandleForReading];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(taskDataAvailable:) name:NSFileHandleReadCompletionNotification object:self.taskOutput];
    [self.taskOutput readInBackgroundAndNotify];
    
    return NO;
}

- (void)taskDataAvailable:(NSNotification *)notification {
    
    NSData *incomingData = [[notification userInfo] objectForKey:NSFileHandleNotificationDataItem];
    if (incomingData && [incomingData length])
    {
        self.isPowRunning = YES;
    } else {
        self.isPowRunning = NO;
    }
    
    [self switchSwitchViewToPowStatus];
}

- (void)taskCompleted:(NSNotification *)notification {

    int exitCode = [[notification object] terminationStatus];
    
    if (exitCode != 0)
        NSLog(@"Error: Task exited with code %d", exitCode);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    // Do whatever else you need to do when the task finished
    
//    BOOL powIsRunning = [responseCode rangeOfString:@"200"].location != NSNotFound;
//    self.isPowRunning = powIsRunning;
//    [self switchSwitchViewToPowStatus];
//    
//    return powIsRunning;

}

#pragma mark - Clicking and actions

- (IBAction)didClickAddButton:(id)sender {
    
    NSOpenPanel *openPanel = [[NSOpenPanel alloc] init];
    openPanel.delegate = self;
    
    NSURL *sitesURL = [NSURL URLWithString:[@"~/Sites" stringByExpandingTildeInPath]];
    NSString *sitesURLString = [NSString stringWithFormat:@"file://%@", sitesURL.path];
    [openPanel setCanChooseDirectories:YES];
    openPanel.directoryURL = [NSURL URLWithString:sitesURLString];
    
    self.isShowingModal = YES;
    
    [self.addButton setEnabled:NO];
    [self.noSitesAddASiteButton setEnabled:NO]; // This button needs a disabled style
    
    [NSApp activateIgnoringOtherApps:YES];
    [self.window becomeMainWindow];
    
    [openPanel beginSheetModalForWindow:nil completionHandler:^(NSInteger result) {
        
        [self.addButton setEnabled:YES];
        [self.noSitesAddASiteButton setEnabled:YES];
        
        self.isShowingModal = NO;
        if (result == NSFileHandlingPanelCancelButton) {
            return;
        }
        
        [(NVAppDelegate *)[NSApp delegate] addAppWithURL:openPanel.URL];
        NVDataSource *dataSource = [NVDataSource sharedDataSource];
        [self.appListTableView reloadData];
        [self updatePanelHeightAndAnimate:YES];
        
        NSInteger indexOfNewlyAddedRow = [dataSource indexOfAppWithURL:openPanel.URL];
        [self beginEditingRowAtIndex:[NSNumber numberWithInteger:indexOfNewlyAddedRow]];
        
    }];
}

//- (IBAction)didClickRestart:(id)sender {
//    
//    NVDataSource *dataSource = [NVDataSource sharedDataSource];
//    NVApp *app = [dataSource.apps objectAtIndex:self.appListTableView.clickedRow];
//    
//    [app restart];
//}

- (IBAction)didClickReallyDeleteButton:(id)sender {
    
    if (self.isEditing) {
        
        return;
    }
    
    NSInteger clickedRow = self.appListTableView.selectedRow;
    NVDataSource *dataSource = [NVDataSource sharedDataSource];
    
    NVApp *app = [self appForSelectedRow:self.appListTableView.selectedRow];
    
    [dataSource removeApp:app];
    
    self.selectedRow = -1;
    NSIndexSet *thisIndexSet = [NSIndexSet indexSetWithIndex:clickedRow];
    [self.appListTableView removeRowsAtIndexes:thisIndexSet withAnimation:NSTableViewAnimationEffectFade];
    
    [self updatePanelHeightAndAnimate:YES];
}

- (IBAction)didClickRestartButton:(id)sender {

    NVApp *app = [self appForSelectedRow:self.appListTableView.selectedRow];
    
    [app restart];
    
    NVTableCellView *cellView = [self.appListTableView viewAtColumn:0 row:self.appListTableView.selectedRow makeIfNecessary:NO];
    [cellView spinRestartButton];
}

- (IBAction)didClickInstallPowButton:(id)sender {
    
    self.hasActivePanel = NO;
    
    [self performSelectorInBackground:@selector(installPow:) withObject:nil];
}

#pragma mark - Menus

- (void)didClickSupportMenuItem:(id)sender {
    
    NSURL *supportURL = [NSURL URLWithString:@"http://anvilformac.com/support"];
    [[NSWorkspace sharedWorkspace] openURL:supportURL];
}

- (void)didClickShowAbout:(id)sender {
    
    [NSApp activateIgnoringOtherApps:YES];
    [self.window becomeMainWindow];
    [[NSApplication sharedApplication] orderFrontStandardAboutPanel:sender];
}

- (void)didClickCheckForUpdates:(id)sender {
    
    SUUpdater *updater = [[SUUpdater alloc] init];
    [updater checkForUpdates:sender];
}

- (void)didClickQuit:(id)sender {
    
    [[NSApplication sharedApplication] terminate:nil];
}

- (void)didClickRestartPow:(id)sender {
    
    [self restartPow:self];
}

- (void)didClickRename:(id)sender {
    
    NSIndexSet *rowToSelect = [NSIndexSet indexSetWithIndex:self.appListTableView.clickedRow];
    [self.appListTableView selectRowIndexes:rowToSelect byExtendingSelection:NO];
    NVTableCellView *cell = (NVTableCellView *)[self.appListTableView viewAtColumn:0 row:self.appListTableView.clickedRow makeIfNecessary:YES];
    self.indexOfRowBeingEdited = self.appListTableView.clickedRow;
    
    self.isEditing = YES;
    [cell.textField setEnabled:YES];
    [cell.textField becomeFirstResponder];
}

- (void)didClickRemove:(id)sender {
    
    NSInteger clickedRow = self.appListTableView.selectedRow;
    NVDataSource *dataSource = [NVDataSource sharedDataSource];
    NVApp *app = [self appForSelectedRow:self.appListTableView.clickedRow];
    
    [dataSource removeApp:app];
    
    self.selectedRow = -1;
    NSIndexSet *thisIndexSet = [NSIndexSet indexSetWithIndex:clickedRow];
    [self.appListTableView removeRowsAtIndexes:thisIndexSet withAnimation:NSTableViewAnimationEffectFade];
    
    [self updatePanelHeightAndAnimate:YES];
}

- (void)didClickOpenInTerminal:(id)sender {
    
    NVApp *app = [self appForSelectedRow:self.appListTableView.clickedRow];
    
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/usr/bin/open"];
    [task setArguments:[NSArray arrayWithObjects:@"-a", @"Terminal", app.url.path, nil]];
    [task launch];
}

- (void)didClickOpenInFinder:(id)sender {
    
    NVApp *app = [self appForSelectedRow:self.appListTableView.clickedRow];
    
    [[NSWorkspace sharedWorkspace] openURL:app.url];
}

- (void)didClickOpenWithBrowser:(id)sender {
    
    NVApp *app = [self appForSelectedRow:self.appListTableView.clickedRow];
    
    [[NSWorkspace sharedWorkspace] openURL:app.browserURL];
}

#pragma mark - Deallocation

- (void)dealloc {
    
    [self.powCheckerTimer invalidate];
    self.powCheckerTimer = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSControlTextDidChangeNotification object:self.searchField];
}


@end
