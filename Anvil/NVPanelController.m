#import "NVPanelController.h"
#import "NVBackgroundView.h"
#import "NVStatusItemView.h"
#import "NVMenubarController.h"
#import "NVTableRowView.h"
#import "NVTableCellView.h"

#define SEARCH_INSET 15

#define OPEN_DURATION .15
#define CLOSE_DURATION .1

#define POPUP_HEIGHT 122
#define PANEL_WIDTH 280
#define MENU_ANIMATION_DURATION .1

#pragma mark -

@interface NVPanelController ()
    @property (nonatomic) NSInteger selectedRow;
    @property (nonatomic) BOOL isEditing;
@end

@implementation NVPanelController

static NSString *const kAppListTableCellIdentifier = @"appListTableCellIdentifier";

#pragma mark -

- (id)initWithDelegate:(id<NVPanelControllerDelegate>)delegate {
    
    self = [super initWithWindowNibName:@"Panel"];
    if (self != nil)
    {
        _delegate = delegate;
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSControlTextDidChangeNotification object:self.searchField];
}

#pragma mark -

- (void)awakeFromNib {
    [super awakeFromNib];
    
    // Make a fully skinned panel
    NSPanel *panel = (id)[self window];
    
    [panel setAcceptsMouseMovedEvents:YES];
    [panel setLevel:NSPopUpMenuWindowLevel];
    [panel setOpaque:NO];
    [panel setBackgroundColor:[NSColor clearColor]];
    
    self.headerView.backgroundImage = [NSImage imageNamed:@"Titlebar"];
    self.headerIconView.backgroundImage = [NSImage imageNamed:@"TitlebarTitle"];

    NSInteger height = self.headerIconView.backgroundImage.size.height;
    NSInteger width = self.headerIconView.backgroundImage.size.width;
    NSInteger x = (self.window.frame.size.width / 2.0 - width / 2.0);
    NSInteger y = (self.headerView.frame.size.height / 2.0 - height / 2.0);
    
    self.headerIconView.frame = CGRectMake(x, y, width, height);

    self.appListTableView.menu = [self menuForTableView];
    [self.appListTableView setDoubleAction:@selector(appListTableViewDoubleClicked:)];
    
    [self.backgroundView setBackgroundColor:[NSColor colorWithDeviceRed:244.0/255.0 green:244.0/255.0 blue:244.0/255.0 alpha:1]];
    [self.appListTableView setBackgroundColor:[NSColor colorWithDeviceRed:244.0/255.0 green:244.0/255.0 blue:244.0/255.0 alpha:1]];
    
    int opts = (NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways);
    NSTrackingArea *trackingArea = [ [NSTrackingArea alloc] initWithRect:[[self appListTableView] bounds]
                                                 options:opts
                                                   owner:self
                                                userInfo:nil];
    [[self appListTableView] addTrackingArea:trackingArea];

    self.isEditing = NO;
}

#pragma mark - Public accessors

- (BOOL)hasActivePanel {
    return _hasActivePanel;
}

- (void)setHasActivePanel:(BOOL)flag {
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
    self.hasActivePanel = NO;
}

- (void)windowDidResignKey:(NSNotification *)notification; {
    if ([[self window] isVisible]) {
        self.hasActivePanel = NO;
    }
}

- (void)windowDidResize:(NSNotification *)notification {
    
    NSWindow *panel = [self window];
    NSRect statusRect = [self statusRectForWindow:panel];
    NSRect panelRect = [panel frame];

    CGFloat statusX = roundf(NSMidX(statusRect));
    CGFloat panelX = statusX - NSMinX(panelRect);

    self.backgroundView.arrowX = panelX;
}

#pragma mark - Keyboard

- (void)cancelOperation:(id)sender {
    self.hasActivePanel = NO;
}

#pragma mark - Public methods

- (NSRect)statusRectForWindow:(NSWindow *)window {
    
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

- (void)openPanel {
    
    [[self appListTableView] reloadData];
        
    NSWindow *panel = [self window];
    
    NSRect screenRect = [[[NSScreen screens] objectAtIndex:0] frame];
    NSRect statusRect = [self statusRectForWindow:panel];
    
    NSRect panelRect = [panel frame];
    panelRect.size.width = PANEL_WIDTH;
    
    panelRect.origin.x = roundf(NSMidX(statusRect) - NSWidth(panelRect) / 2);
    panelRect.origin.y = NSMaxY(statusRect) - NSHeight(panelRect);
    
    if (NSMaxX(panelRect) > (NSMaxX(screenRect) - ARROW_HEIGHT))
        panelRect.origin.x -= NSMaxX(panelRect) - (NSMaxX(screenRect) - ARROW_HEIGHT);
    
    [NSApp activateIgnoringOtherApps:NO];
    [panel setAlphaValue:0];
    [panel setFrame:statusRect display:YES];
    [panel makeKeyAndOrderFront:nil];
    
    [NSAnimationContext beginGrouping];
    [panel setFrame:panelRect display:YES];
    [panel setAlphaValue:1];
    [NSAnimationContext endGrouping];
    
    [panel performSelector:@selector(makeFirstResponder:) withObject:self.appListTableView afterDelay:0];
    
    [self updatePanelHeight];
}

- (void)closePanel {
    
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:CLOSE_DURATION];
    [[[self window] animator] setAlphaValue:0];
    [NSAnimationContext endGrouping];
    
    dispatch_after(dispatch_walltime(NULL, NSEC_PER_SEC * CLOSE_DURATION * 2), dispatch_get_main_queue(), ^{
        
        [self.window orderOut:nil];
    });
}

#pragma mark - Sizing

- (void)updatePanelHeight {
    
    NSRect panelRect = [[self window] frame];
    NSInteger newHeight = (self.appListTableView.rowHeight + self.appListTableView.intercellSpacing.height) * [self.appListTableView numberOfRows] + 8;
    NSInteger heightdifference = panelRect.size.height - newHeight;
    panelRect.size.height = (self.appListTableView.rowHeight + self.appListTableView.intercellSpacing.height) * [self.appListTableView numberOfRows] + 8 + self.headerView.frame.size.height;
    panelRect.origin.y += heightdifference - self.headerView.frame.size.height;
    [[[self window] animator] setFrame:panelRect display:YES];
}

#pragma mark - Table View Delegate

- (BOOL)selectionShouldChangeInTableView:(NSTableView *)aTableView {
    
    return NO;
}

- (BOOL)tableView:(NSTableView *)tableView shouldTrackCell:(NSCell *)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    
    return YES;
}

-(void)mouseMoved:(NSEvent *)theEvent {
    
    NSPoint point = [self.appListTableView convertPoint:[theEvent locationInWindow] fromView:self.backgroundView];
    NSInteger row = [self.appListTableView rowAtPoint:point];
    
    
    if (!self.isEditing) {
        
        // A bug - we have to reset the selection, I think. Changes aren't fired when it's the same.
        [self.appListTableView selectRowIndexes:[[NSIndexSet alloc] init] byExtendingSelection:NO];
        [self.appListTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    }
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
    
    return [[[NVDataSource sharedDataSource] apps] count];
}

- (void)mouseExited:(NSEvent *)theEvent {
    
    if (!self.isEditing && [self.appListTableView selectedRow] > -1) {

        [[self.appListTableView rowViewAtRow:[self.appListTableView selectedRow] makeIfNecessary:NO] setBackgroundColor:[NSColor clearColor]];
        [[self.appListTableView viewAtColumn:0 row:[self.appListTableView selectedRow] makeIfNecessary:NO] hideControls];
    }
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    
    self.isEditing = NO;
    
    if (self.selectedRow > -1) {
        [[self.appListTableView rowViewAtRow:self.selectedRow makeIfNecessary:NO] setBackgroundColor:[NSColor clearColor]];
        [[self.appListTableView viewAtColumn:0 row:self.selectedRow makeIfNecessary:NO] hideControls];
    }
    
    self.selectedRow = [self.appListTableView selectedRow];
    
    if ([self.appListTableView selectedRow] > -1) {
        
        [[self.appListTableView viewAtColumn:0 row:self.selectedRow makeIfNecessary:NO] showControls];
        [[self.appListTableView rowViewAtRow:[self.appListTableView selectedRow] makeIfNecessary:NO] setBackgroundColor:[NSColor whiteColor]];
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
    
    if (app.faviconURL) {
    
        NSImage *faviconImage = [[NSImage alloc] initWithContentsOfURL:app.faviconURL];
        cellView.faviconImageView.foregroundImage = [self imageRepresentationOfImage:faviconImage
                                                                            withSize:NSMakeSize(16, 16)];
    } else {
        
        cellView.faviconImageView.foregroundImage = [NSImage imageNamed:@"StatusHighlighted"];
    }

    return cellView;
}

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row {
    
    NSString *kAppListTableRowIdentifier = @"appListTableRowIdentifier";
    
    NSTableRowView *rowView = (NSTableRowView *)[tableView makeViewWithIdentifier:kAppListTableRowIdentifier owner:self];
    if (rowView == nil) {
        
        rowView = [[NSTableRowView alloc] init];
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

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector {
    
    if (commandSelector == @selector(cancelOperation:)) {
        
        self.isEditing = NO;
        [self.appListTableView performSelector:@selector(reloadData) withObject:nil afterDelay:0.0];
    }
    return NO;
}

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
    
    NSMenuItem *openInBrowserMenuItem = [[NSMenuItem alloc] initWithTitle:@"Open in Browser" action:@selector(didClickOpenWithBrowser:) keyEquivalent:@""];
    [menu addItem:openInBrowserMenuItem];
    NSMenuItem *openInFinderMenuItem = [[NSMenuItem alloc] initWithTitle:@"Open in Finder" action:@selector(didClickOpenInFinder:) keyEquivalent:@""];
    [menu addItem:openInFinderMenuItem];
    
    [menu addItem:[NSMenuItem separatorItem]];
    
    NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"Restart" action:@selector(didClickRestart:) keyEquivalent:@""];
    [menu addItem:menuItem];
    NSMenuItem *renameMenuItem = [[NSMenuItem alloc] initWithTitle:@"Rename" action:@selector(didClickRename:) keyEquivalent:@""];
    [menu addItem:renameMenuItem];
    NSMenuItem *removeMenuItem = [[NSMenuItem alloc] initWithTitle:@"Remove" action:@selector(removeClickedRow:) keyEquivalent:@""];
    [menu addItem:removeMenuItem];
    
    [menu setAutoenablesItems:NO];
    
    return menu;
}

- (void)appListTableViewDoubleClicked:(id)sender {
    
    NSInteger selectedIndex = [self.appListTableView clickedRow];
    
    if (selectedIndex < 0) {
        return;
    }
    
    self.isEditing = YES;
    
    NVTableCellView *cell = (NVTableCellView *)[self.appListTableView viewAtColumn:0 row:selectedIndex makeIfNecessary:YES];
    [cell.textField setEnabled:YES];
    [cell.textField becomeFirstResponder];
}

- (IBAction)removeClickedRow:(id)sender {
    
    NVDataSource *dataSource = [NVDataSource sharedDataSource];
    NVApp *app = [dataSource.apps objectAtIndex:self.appListTableView.clickedRow];
    
    [dataSource removeApp:app];
    
    NSIndexSet *thisIndexSet = [NSIndexSet indexSetWithIndex:self.appListTableView.clickedRow];
    [self.appListTableView removeRowsAtIndexes:thisIndexSet withAnimation:NSTableViewAnimationSlideUp];
    [self updatePanelHeight];
}

- (void)didClickRename:(id)sender {
    
    NSIndexSet *rowToSelect = [NSIndexSet indexSetWithIndex:self.appListTableView.clickedRow];
    [self.appListTableView selectRowIndexes:rowToSelect byExtendingSelection:NO];
    NVTableCellView *cell = (NVTableCellView *)[self.appListTableView viewAtColumn:0 row:self.appListTableView.clickedRow makeIfNecessary:YES];
    self.isEditing = YES;
    [cell.textField setEnabled:YES];
    [cell.textField becomeFirstResponder];
}

- (void)didClickOpenInFinder:(id)sender {
    
    NVDataSource *dataSource = [NVDataSource sharedDataSource];
    NVApp *app = [dataSource.apps objectAtIndex:self.appListTableView.clickedRow];

    [[NSWorkspace sharedWorkspace] openURL:[app realURL]];
}

- (void)didClickOpenWithBrowser:(id)sender {
    
    NVDataSource *dataSource = [NVDataSource sharedDataSource];
    NVApp *app = [dataSource.apps objectAtIndex:self.appListTableView.clickedRow];
    
    [[NSWorkspace sharedWorkspace] openURL:app.browserURL];
}

- (IBAction)didClickRestart:(id)sender {
    
    NVDataSource *dataSource = [NVDataSource sharedDataSource];
    NVApp *app = [dataSource.apps objectAtIndex:self.appListTableView.clickedRow];
    
    [app restart];
}

-(void)setSelectionFromClick{
    
    NSInteger theClickedRow = [self.appListTableView clickedRow];
    
    NSIndexSet *thisIndexSet = [NSIndexSet indexSetWithIndex:theClickedRow];
    [self.appListTableView selectRowIndexes:thisIndexSet byExtendingSelection:NO];
}

- (IBAction)didClickDeleteButton:(id)sender {

    NSInteger clickedRow = self.appListTableView.selectedRow;
    NVDataSource *dataSource = [NVDataSource sharedDataSource];
    NVApp *app = [dataSource.apps objectAtIndex:clickedRow];
    
    [dataSource removeApp:app];
    
    NSIndexSet *thisIndexSet = [NSIndexSet indexSetWithIndex:clickedRow];
    [self.appListTableView removeRowsAtIndexes:thisIndexSet withAnimation:NSTableViewAnimationSlideUp];
    self.selectedRow = -1;
    [self updatePanelHeight];
}

- (IBAction)didClickRestartButton:(id)sender {
    NVDataSource *dataSource = [NVDataSource sharedDataSource];
    NVApp *app = [dataSource.apps objectAtIndex:self.appListTableView.selectedRow];
    
    [app restart];
}


@end
