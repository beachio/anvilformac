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

@implementation NVPanelController

@synthesize backgroundView = _backgroundView;
@synthesize delegate = _delegate;
@synthesize searchField = _searchField;
@synthesize textField = _textField;
@synthesize appListTableView;

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
    
    self.appListTableView.menu = [self menuForTableView];
    [self.appListTableView setDoubleAction:@selector(appListTableViewDoubleClicked:)];
}

#pragma mark - Public accessors

- (BOOL)hasActivePanel {
    return _hasActivePanel;
}

- (void)setHasActivePanel:(BOOL)flag {
    if (_hasActivePanel != flag)
    {
        _hasActivePanel = flag;
        
        if (_hasActivePanel)
        {
            [self openPanel];
        }
        else
        {
            [self closePanel];
        }
    }
}

#pragma mark - NSWindowDelegate

- (void)windowWillClose:(NSNotification *)notification {
    self.hasActivePanel = NO;
}

- (void)windowDidResignKey:(NSNotification *)notification; {
    if ([[self window] isVisible])
    {
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
    if ([self.delegate respondsToSelector:@selector(statusItemViewForPanelController:)])
    {
        statusItemView = [self.delegate statusItemViewForPanelController:self];
    }
    
    if (statusItemView)
    {
        statusRect = statusItemView.globalRect;
        statusRect.origin.y = NSMinY(statusRect) - NSHeight(statusRect);
    }
    else
    {
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
    
//    panelRect.size.height = (self.appListTableView.rowHeight + self.appListTableView.intercellSpacing.height) * [appListTableView numberOfRows] + 8;
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

- (void)closePanel
{
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:CLOSE_DURATION];
    [[[self window] animator] setAlphaValue:0];
    [NSAnimationContext endGrouping];
    
    dispatch_after(dispatch_walltime(NULL, NSEC_PER_SEC * CLOSE_DURATION * 2), dispatch_get_main_queue(), ^{
        
        [self.window orderOut:nil];
    });
}

#pragma mark - Table View Delegate

-(NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
    
    return [[[NVDataSource sharedDataSource] apps] count];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    
    NVApp *app = [[[NVDataSource sharedDataSource] apps] objectAtIndex:row];
    
    NVTableCellView *cellView = (NVTableCellView *)[tableView makeViewWithIdentifier:kAppListTableCellIdentifier owner:self];
    cellView.textField.stringValue = app.name;
    [cellView.textField sizeToFit];
    cellView.textField.delegate = self;
    [cellView.textField setWidth];
    
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

- (NSMenu *)menuForTableView {
    
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Site Menu"];
    
    NSMenuItem *openInBrowserMenuItem = [[NSMenuItem alloc] initWithTitle:@"Open in Browser" action:@selector(didClickOpenWithBrowser:) keyEquivalent:@""];
    [menu addItem:openInBrowserMenuItem];
    NSMenuItem *openInFinderMenuItem = [[NSMenuItem alloc] initWithTitle:@"Open in Finder" action:@selector(didClickOpenInFinder:) keyEquivalent:@""];
    [menu addItem:openInFinderMenuItem];
    
    [menu addItem:[NSMenuItem separatorItem]];
    
    NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"Restart" action:@selector(didClickRestart:) keyEquivalent:@""];
    [menu addItem:menuItem];
    NSMenuItem *renameMenuItem = [[NSMenuItem alloc] initWithTitle:@"Rename" action:NULL keyEquivalent:@""];
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
    
    NVTableCellView *cell = (NVTableCellView *)[self.appListTableView viewAtColumn:0 row:selectedIndex makeIfNecessary:YES];
    [cell.textField becomeFirstResponder];
}

- (void)controlTextDidEndEditing:(NSNotification *)obj {
    
    NSTextField *textField = (NSTextField *)obj.object;
    NSInteger selectedIndex = [self.appListTableView selectedRow];
    
    
    NVApp *app = (NVApp *)[[NVDataSource sharedDataSource].apps objectAtIndex:selectedIndex];
    [app renameTo:textField.stringValue];
    
    [[NVDataSource sharedDataSource] readInSavedAppDataFromDisk];
    [self.appListTableView reloadData];
}


- (void)removeClickedRow:(id)sender {
    
    NVDataSource *dataSource = [NVDataSource sharedDataSource];
    NVApp *app = [dataSource.apps objectAtIndex:self.appListTableView.clickedRow];
    
    [dataSource removeApp:app];
    
    NSIndexSet *thisIndexSet = [NSIndexSet indexSetWithIndex:self.appListTableView.clickedRow];
    [self.appListTableView removeRowsAtIndexes:thisIndexSet withAnimation:NSTableViewAnimationSlideUp];
    [self updatePanelHeight];
}

- (void)didClickOpenInFinder:(id)sender {
    
    NVDataSource *dataSource = [NVDataSource sharedDataSource];
    NVApp *app = [dataSource.apps objectAtIndex:self.appListTableView.clickedRow];

    [[NSWorkspace sharedWorkspace] openURL: [app realURL]];
}

- (void)didClickOpenWithBrowser:(id)sender {
    
    NVDataSource *dataSource = [NVDataSource sharedDataSource];
    NVApp *app = [dataSource.apps objectAtIndex:self.appListTableView.clickedRow];
    
    [[NSWorkspace sharedWorkspace] openURL:app.browserURL];
}

- (void)didClickRestart:(id)sender {
    
    NVDataSource *dataSource = [NVDataSource sharedDataSource];
    NVApp *app = [dataSource.apps objectAtIndex:self.appListTableView.clickedRow];
    
    [app restart];
}

#pragma mark - 

- (void)updatePanelHeight {
    NSRect panelRect = [[self window] frame];
    
    NSInteger newHeight = (self.appListTableView.rowHeight + self.appListTableView.intercellSpacing.height) * [appListTableView numberOfRows] + 8;
    NSInteger heightdifference = panelRect.size.height - newHeight;
    panelRect.size.height = (self.appListTableView.rowHeight + self.appListTableView.intercellSpacing.height) * [appListTableView numberOfRows] + 8;
    panelRect.origin.y += heightdifference;
    [[[self window] animator] setFrame:panelRect display:YES];
}

-(void)setSelectionFromClick{
    
    NSInteger theClickedRow = [self.appListTableView clickedRow];
    
    NSIndexSet *thisIndexSet = [NSIndexSet indexSetWithIndex:theClickedRow];
    [self.appListTableView selectRowIndexes:thisIndexSet byExtendingSelection:NO];
}


@end
