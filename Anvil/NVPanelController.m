#import "NVPanelController.h"
#import "NVBackgroundView.h"
#import "NVStatusItemView.h"
#import "NVMenubarController.h"
#import "NVTableRowView.h"
#import "NVTableCellView.h"
#import "NVAppDelegate.h"
#import <QuartzCore/QuartzCore.h>
#import <Sparkle/Sparkle.h>

#define SEARCH_INSET 15

#define OPEN_DURATION .15
#define CLOSE_DURATION .1

#define POPUP_HEIGHT 122
#define PANEL_WIDTH 256

#define WINDOW_VERTICAL_OFFSET 4

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
        
        self.isEditing = NO;
        
        // Make a fully skinned panel
        NSPanel *panel = (id)[self window];

        [panel setLevel:NSPopUpMenuWindowLevel];
        [panel setOpaque:NO];
        [panel setBackgroundColor:[NSColor clearColor]];
        
        self.switchView.delegate = self;
        
        self.headerView.backgroundImage = [NSImage imageNamed:@"Titlebar"];
        self.headerIconView.backgroundImage = [NSImage imageNamed:@"TitlebarIcon"];
        
        self.backgroundView.backgroundColor = [NSColor colorWithDeviceRed:244.0/255.0 green:244.0/255.0 blue:244.0/255.0 alpha:1];
        
        self.appListTableView.menu = [self menuForTableView];
        self.appListTableView.action = @selector(appListTableViewClicked:);
        self.appListTableView.backgroundColor = [NSColor colorWithDeviceRed:244.0/255.0 green:244.0/255.0 blue:244.0/255.0 alpha:1];
        
        self.appListTableView.delegate = self;
        
        self.appListTableScrollView.wantsLayer = YES;
        self.appListTableScrollView.layer.opaque = NO;
        self.appListTableScrollView.layer.cornerRadius = 0;
        self.appListTableScrollView.backgroundColor = [NSColor clearColor];
        
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
        
        self.noSitesAddASiteButton.image = [NSImage imageNamed:@"BlueButtonAdd"];
        self.noSitesAddASiteButton.alternateImage = [NSImage imageNamed:@"BlueButtonAddPushed"];
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
    }
    
    return self;
}

- (void)awakeFromNib {
    
    if (!self.awake) {
        [super awakeFromNib];
        [self switchSwitchViewToPowStatus];
        self.awake = YES;
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
    
    self.settingsButton.image           = [NSImage imageNamed:@"Settings"];
    self.settingsButton.alternateImage  = [NSImage imageNamed:@"SettingsAlt"];
    
    NSMenu *settingsMenu = [self buildSettingsMenu];
    
    self.settingsButton.menu = settingsMenu;
    self.settingsButton.preferredEdge = NSMaxYEdge;
    self.settingsButton.pullsDown = YES;
    [self.settingsButton selectItem:nil];
    
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:@""
                                                  action:NULL
                                           keyEquivalent:@""];
    item.image = [NSImage imageNamed:@"Settings"];
    item.onStateImage = nil;
    item.mixedStateImage = nil;
    
    NSPopUpButtonCell *cell = [self.settingsButton cell];
    cell.menuItem = item;
    cell.bordered = NO;
    cell.imagePosition = NSImageOnly;
    cell.arrowPosition = NSPopUpNoArrow;
    cell.usesItemFromMenu = NO;
    cell.alternateImage = [NSImage imageNamed:@"SettingsAlt"];
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
        BOOL status = [self checkWhetherPowIsRunning];
        self.isPowRunning = status;

        [self.switchView switchToWithoutCallbacks:status withAnimation:YES];
        self.switchLabel.text = status ? @"ON" : @"OFF";
    }
}

- (void)beginEditingRowAtIndex:(NSNumber *)indexNumber {
    
    NSInteger index = [indexNumber integerValue];

    if (index > -1 && index < self.appListTableView.numberOfRows) {
        
        NSIndexSet *rowToSelect = [NSIndexSet indexSetWithIndex:index];
        [self.appListTableView selectRowIndexes:rowToSelect byExtendingSelection:NO];
        
        NVTableCellView *cell = (NVTableCellView *)[self.appListTableView viewAtColumn:0 row:index makeIfNecessary:YES];
        self.isEditing = YES;
        [cell.textField setEnabled:YES];
        [cell.textField becomeFirstResponder];
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
        a = [self runTask:@"apachectl stop & /bin/launchctl load /Library/LaunchDaemons/cx.pow.firewall.plist" asRoot:YES];
        b = [self runTask:[NSString stringWithFormat:@"/bin/launchctl load %@/Library/LaunchAgents/cx.pow.powd.plist", NSHomeDirectory()] asRoot:NO];
    } else {
        a = [self runTask:@"/bin/launchctl unload /Library/LaunchDaemons/cx.pow.firewall.plist" asRoot:YES];
        b = [self runTask:[NSString stringWithFormat:@"/bin/launchctl unload %@/Library/LaunchAgents/cx.pow.powd.plist", NSHomeDirectory()] asRoot:NO];
    }
    success = a & b;
    
    [NSApp activateIgnoringOtherApps:YES];
    [self.window becomeMainWindow];

    [self performSelector:@selector(switchSwitchViewToPowStatus) withObject:nil afterDelay:0.5];
    [self performSelector:@selector(switchSwitchViewToPowStatus) withObject:nil afterDelay:1.0];

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
    
    NSInteger appListHeight = panel.frame.size.height - HEADER_HEIGHT - 5;
    self.appListTableScrollView.frame = NSMakeRect(1, 1, PANEL_WIDTH - 2, appListHeight);
}

#pragma mark - Keyboard

- (void)cancelOperation:(id)sender {
    
    self.hasActivePanel = NO;
}

#pragma mark - Public methods

- (void)openPanel {
    
    [self.appListTableView reloadData];
    [self switchSwitchViewToPowStatus];
    
    [self updatePanelHeightAndAnimate:self.panelIsOpen];
    self.panelIsOpen = YES;
    
    [self.window makeFirstResponder:nil];
    [self.window becomeMainWindow];
    [self.window makeKeyAndOrderFront:nil];
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

    // Set our maximum height
    NSInteger maxHeight = round([[NSScreen mainScreen] frame].size.height / 2);
    if (panelHeight > maxHeight) {
        
        panelHeight = maxHeight;
    }
    
    panelRect.origin.x = roundf(NSMidX(statusRect) - NSWidth(panelRect) / 2) - 2;
    
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
        self.noAppsView.hidden = YES;
        self.welcomeView.hidden = NO;
        
        // In this case, appListTableView can actually be tall without being visible!
        // 24 is the menubar height. 6 is the arrow height. HEADER_HEIGHT is the header height.
        // TODO: Clean up these numbers.

        panelHeight = self.welcomeView.frame.size.height + HEADER_HEIGHT + ARROW_HEIGHT;
        NSInteger panelY = bottomOfMenubarViewOffset - panelHeight - WINDOW_VERTICAL_OFFSET;
        panelRect = CGRectMake(panelRect.origin.x, panelY, PANEL_WIDTH, panelHeight);
        
    } else if ([[[NVDataSource sharedDataSource] apps] count] == 0) {
        
        self.appListTableView.hidden = YES;
        self.noAppsView.hidden = NO;
        self.welcomeView.hidden = YES;
        
        panelRect.origin.y -= self.noAppsView.frame.size.height;
        panelRect.size.height += self.noAppsView.frame.size.height;
    } else {
        self.appListTableView.hidden = NO;
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
    
    if ([[[NVDataSource sharedDataSource] apps] count] > 0) {
        
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
    
    return [[[NVDataSource sharedDataSource] apps] count];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {

    if (self.isEditing) {
        return;
    }
    
    [self.appListTableView deselectRow:self.selectedRow];
    
    if (self.selectedRow > -1 && self.selectedRow < self.appListTableView.numberOfRows) {
        [[self.appListTableView rowViewAtRow:self.selectedRow makeIfNecessary:NO] setBackgroundColor:[NSColor clearColor]];
        [[self.appListTableView viewAtColumn:0 row:self.selectedRow makeIfNecessary:NO] setNeedsDisplay:YES];
        [[self.appListTableView viewAtColumn:0 row:self.selectedRow makeIfNecessary:NO] hideControls];
    }

    self.selectedRow = [self.appListTableView selectedRow];
    
    if ([self.appListTableView selectedRow] > -1) {
        
        [[self.appListTableView viewAtColumn:0 row:self.selectedRow makeIfNecessary:NO] showControls];
        [[self.appListTableView rowViewAtRow:[self.appListTableView selectedRow] makeIfNecessary:NO] setNeedsDisplay:YES];
    }
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    
    NVApp *app = [[[NVDataSource sharedDataSource] apps] objectAtIndex:row];
    
    NVTableCellView *cellView = (NVTableCellView *)[tableView makeViewWithIdentifier:kAppListTableCellIdentifier owner:self];
    [cellView.siteLabel setText:app.name];
    [cellView.siteLabel setTextColor:[NSColor colorWithDeviceRed:68.0/255.0 green:68.0/255.0 blue:68.0/255.0 alpha:1.0]];
    [cellView.siteLabel setEnabled:NO];
    [cellView.siteLabel sizeToFit];
    cellView.siteLabel.delegate = self;
    [cellView.siteLabel setWidth];
    
    [cellView hideControls];
    [cellView.siteLabel setWidth];
    
    [cellView resizeSubviewsWithOldSize:cellView.frame.size];
    
    cellView.showRestartButton = [app isARackApp];
    
    if (app.faviconURL) {
    
        cellView.faviconImageView.backgroundImage = [NSImage imageNamed:@"SiteIcon"];
        NSImage *faviconImage = [[NSImage alloc] initWithContentsOfURL:app.faviconURL];
        cellView.faviconImageView.foregroundImage = [self imageRepresentationOfImage:faviconImage
                                                                            withSize:NSMakeSize(16, 16)];
    } else {
        
        cellView.faviconImageView.backgroundImage = [NSImage imageNamed:@"SiteIconDefault"];
        cellView.faviconImageView.foregroundImage = nil;
    }

    return cellView;
}

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row {
    
    NVTableRowView *rowView = (NVTableRowView *)[tableView makeViewWithIdentifier:kAppListTableRowIdentifier owner:self];
    if (rowView == nil) {
        
        rowView = [[NVTableRowView alloc] init];
        rowView.identifier = kAppListTableRowIdentifier;
    }
    
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

- (void)mouseMoved:(NSEvent *)theEvent {
    
    NSPoint point = [self.appListTableView convertPoint:[theEvent locationInWindow] fromView:self.backgroundView];
    NSInteger row = [self.appListTableView rowAtPoint:point];
    
    if (!self.isEditing && row != [self.appListTableView selectedRow]) {
        
        [self.appListTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    }
}

- (void)mouseExited:(NSEvent *)theEvent {
    
    NSString *trackingAreaName = [theEvent.trackingArea.userInfo objectForKey:@"identifier"];
    
    if (trackingAreaName == kPanelTrackingAreaIdentifier) {
        [self.appListTableView deselectRow:self.selectedRow];
        
        if (!self.isEditing && [self.appListTableView selectedRow] > -1) {
            [[self.appListTableView rowViewAtRow:[self.appListTableView selectedRow] makeIfNecessary:NO] setBackgroundColor:[NSColor clearColor]];
            [[self.appListTableView viewAtColumn:0 row:[self.appListTableView selectedRow] makeIfNecessary:NO] hideControls];
        }
    }
}

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

- (void)controlTextDidChange:(NSNotification *)obj  {
    
    NVTableCellView *tableCellView = [self.appListTableView viewAtColumn:0 row:self.selectedRow makeIfNecessary:NO];
    tableCellView.localLabel.hidden =  YES;
    
    [self resizeTextField: [obj object]];
}

- (void)controlTextDidEndEditing:(NSNotification *)obj {
    
    self.isEditing = NO;

    NSTextField *textField = (NSTextField *)obj.object;
    NSInteger selectedIndex = self.selectedRow;
    
    NVTableCellView *tableCellView = [self.appListTableView viewAtColumn:0 row:self.selectedRow makeIfNecessary:NO];
    tableCellView.localLabel.hidden =  NO;
    
    NVApp *app = (NVApp *)[[NVDataSource sharedDataSource].apps objectAtIndex:selectedIndex];
    [app renameTo:textField.stringValue];
    
    [[NVDataSource sharedDataSource] readInSavedAppDataFromDisk];
    [self.appListTableView reloadData];
}

#pragma mark - Menus

- (NSMenu *)menuForTableView {
    
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Site Menu"];
    
    NSMenuItem *openInFinderMenuItem = [[NSMenuItem alloc] initWithTitle:@"Open in Finder" action:@selector(didClickOpenInFinder:) keyEquivalent:@""];
    [menu addItem:openInFinderMenuItem];
    NSMenuItem *openInTerminalMenuItem = [[NSMenuItem alloc] initWithTitle:@"Open in Terminal" action:@selector(didClickOpenInTerminal:) keyEquivalent:@""];
    [menu addItem:openInTerminalMenuItem];

    [menu addItem:[NSMenuItem separatorItem]];
    
    NSMenuItem *renameMenuItem = [[NSMenuItem alloc] initWithTitle:@"Rename" action:@selector(didClickRename:) keyEquivalent:@""];
    [menu addItem:renameMenuItem];
    
    [menu setAutoenablesItems:NO];
    
    return menu;
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
        
        NVDataSource *dataSource = [NVDataSource sharedDataSource];
        NVApp *app = [dataSource.apps objectAtIndex:self.appListTableView.clickedRow];
        
        [[NSWorkspace sharedWorkspace] openURL:app.browserURL];
        
        self.hasActivePanel = NO;
    }
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
    
    NSString *installPowPath = [[NSBundle mainBundle] pathForResource:@"InstallPow" ofType:@"sh"];
    NSString *command = [NSString stringWithFormat:
                   @"tell application \"Terminal\" to do script \"/bin/sh \\\"%@\\\"; exit\"", installPowPath];
    
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
    [task setArguments:[NSArray arrayWithObjects:@"-I", @"--silent", @"-H", @"host:pow", @"localhost:80/status.json", nil]];
    
    NSPipe *outputPipe = [NSPipe pipe];
    [task setStandardInput:[NSPipe pipe]];
    [task setStandardError:[NSPipe pipe]];
    [task setStandardOutput:outputPipe];
    [task launch];
    [task waitUntilExit];
    
    /* Get the first line, check its status code. */
    NSData *pipeData        = [[outputPipe fileHandleForReading] readDataToEndOfFile];
    NSString *pipeString    = [[NSString alloc] initWithData:pipeData encoding:NSUTF8StringEncoding];
    NSArray *lines          = [pipeString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSString *responseCode  = [lines objectAtIndex:0];
    return ([responseCode isEqualToString:@"HTTP/1.1 200 OK"]);
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

- (IBAction)didClickRestart:(id)sender {
    
    NVDataSource *dataSource = [NVDataSource sharedDataSource];
    NVApp *app = [dataSource.apps objectAtIndex:self.appListTableView.clickedRow];
    
    [app restart];
}

- (IBAction)didClickReallyDeleteButton:(id)sender {
    
    if (self.isEditing) {
        
        return;
    }
    
    NSInteger clickedRow = self.appListTableView.selectedRow;
    NVDataSource *dataSource = [NVDataSource sharedDataSource];
    NVApp *app = [dataSource.apps objectAtIndex:clickedRow];
    
    [dataSource removeApp:app];
    
    self.selectedRow = -1;
    NSIndexSet *thisIndexSet = [NSIndexSet indexSetWithIndex:clickedRow];
    [self.appListTableView removeRowsAtIndexes:thisIndexSet withAnimation:NSTableViewAnimationEffectFade];
    
    [self updatePanelHeightAndAnimate:YES];
}

- (IBAction)didClickRestartButton:(id)sender {
    NVDataSource *dataSource = [NVDataSource sharedDataSource];
    NVApp *app = [dataSource.apps objectAtIndex:self.appListTableView.selectedRow];
    
    [app restart];
    
    NVSpinnerButton *restartButton = sender;
    [restartButton showSpinnerFor:0.4];
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
    self.isEditing = YES;
    [cell.textField setEnabled:YES];
    [cell.textField becomeFirstResponder];
}

- (void)didClickOpenInTerminal:(id)sender {
    
    NVDataSource *dataSource = [NVDataSource sharedDataSource];
    NVApp *app = [dataSource.apps objectAtIndex:self.appListTableView.clickedRow];
    
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/usr/bin/open"];
    [task setArguments:[NSArray arrayWithObjects:@"-a", @"Terminal", app.url.path, nil]];
    [task launch];
}

- (void)didClickOpenInFinder:(id)sender {
    
    NVDataSource *dataSource = [NVDataSource sharedDataSource];
    NVApp *app = [dataSource.apps objectAtIndex:self.appListTableView.clickedRow];
    
    [[NSWorkspace sharedWorkspace] openURL:app.url];
}

- (void)didClickOpenWithBrowser:(id)sender {
    
    NVDataSource *dataSource = [NVDataSource sharedDataSource];
    NVApp *app = [dataSource.apps objectAtIndex:self.appListTableView.clickedRow];
    
    [[NSWorkspace sharedWorkspace] openURL:app.browserURL];
}

#pragma mark - Deallocation

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSControlTextDidChangeNotification object:self.searchField];
}


@end
