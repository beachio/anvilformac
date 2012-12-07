#import "NVAppDelegate.h"

@interface NVAppDelegate () <NSMenuDelegate>

@end


@implementation NVAppDelegate

@synthesize panelController = _panelController;
@synthesize menubarController = _menubarController;

#pragma mark -

- (void)dealloc {
    [_panelController removeObserver:self forKeyPath:@"hasActivePanel"];
}

#pragma mark -

void *kContextActivePanel = &kContextActivePanel;

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {

    if (context == kContextActivePanel) {
        self.menubarController.hasActiveIcon = self.panelController.hasActivePanel;
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - NSApplicationDelegate

- (void)applicationDidBecomeActive:(NSNotification *)notification {

    [[NVDataSource sharedDataSource] performSelectorInBackground:@selector(readInSavedAppDataFromDisk) withObject:nil];
    [self.panelController.appListTableView reloadData];
    [self.panelController setHasActivePanel:YES];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    
    // Install icon into the menu bar
    self.menubarController = [[NVMenubarController alloc] init];
    
    self.panelController = [[NVPanelController alloc] initWithDelegate:self];
    [self.panelController addObserver:self forKeyPath:@"hasActivePanel" options:0 context:kContextActivePanel];
    
    self.menubarController.delegate = self;

    [self.dataSource readInSavedAppDataFromDisk];
}

- (NVDataSource *)dataSource {
    
    return [NVDataSource sharedDataSource];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    // Explicitly remove the icon from the menu bar
    self.menubarController = nil;
    return NSTerminateNow;
}

#pragma mark - Actions

- (IBAction)togglePanel:(id)sender {
    
    NSEvent *theEvent = [NSApp currentEvent];
    
    if ([theEvent modifierFlags] & NSControlKeyMask) {
        
        self.panelController.hasActivePanel = NO;
        [self menuItemRightClicked:sender];
    } else {
        
        self.menubarController.showHighlightIcon = NO;
        self.menubarController.hasActiveIcon = !self.menubarController.hasActiveIcon;
        if (!self.panelController.hasActivePanel) {
            // Read in apps if we're opening it
            [[NVDataSource sharedDataSource] performSelectorInBackground:@selector(readInSavedAppDataFromDisk) withObject:nil];
        }
        self.panelController.hasActivePanel = self.menubarController.hasActiveIcon;
    }
}

- (IBAction)menuItemRightClicked:(id)sender {
    
    if (self.panelController.hasActivePanel) {
        [self togglePanel:nil];
    }
    
    self.menubarController.showHighlightIcon = YES;
    
    NSMenu *settingsMenu = [self.panelController buildSettingsMenu];
    settingsMenu.delegate = self;
    
    for (NSMenuItem *item in settingsMenu.itemArray) {
        [item setTarget:self.panelController];
    }

    [settingsMenu removeItemAtIndex:0]; // Remove the blank one from 0
        
    [self.menubarController.statusItem popUpStatusItemMenu:settingsMenu];
}

#pragma mark - PanelControllerDelegate

- (NVStatusItemView *)statusItemViewForPanelController:(NVPanelController *)controller {
    
    return self.menubarController.statusItemView;
}

- (void)addAppWithURL:(NSURL *)url andName:(NSString *)name {
    
    [[NVDataSource sharedDataSource] addAppWithURL:url andName:name];
    [[NVDataSource sharedDataSource] readInSavedAppDataFromDisk];
    
    [self.panelController.appListTableView reloadData];
    self.panelController.hasActivePanel = YES;
    
    NSNumber *indexOfNewlyAddedRow = [NSNumber numberWithInteger:[[NVDataSource sharedDataSource] indexOfAppWithURL:url]];
    [self.panelController performSelector:@selector(beginEditingRowAtIndex:) withObject:indexOfNewlyAddedRow afterDelay:0.4];
}

- (void)addAppWithURL:(NSURL *)dropURL {
    
    [[NVDataSource sharedDataSource] addAppWithURL:dropURL];
    [[NVDataSource sharedDataSource] readInSavedAppDataFromDisk];
    
    [self.panelController.appListTableView reloadData];
    self.panelController.hasActivePanel = YES;
    
    NSNumber *indexOfNewlyAddedRow = [NSNumber numberWithInteger:[[NVDataSource sharedDataSource] indexOfAppWithURL:dropURL]];
    [self.panelController performSelector:@selector(beginEditingRowAtIndex:) withObject:indexOfNewlyAddedRow afterDelay:0.4];
}

#pragma mark - NSMenuDelegate

- (void)menuDidClose:(NSMenu *)menu {
    
    self.menubarController.showHighlightIcon = NO;
}

#pragma mark - Heights and things

// This is used to calculate the height of the app's status item view.
// That's how we position the app's window.
- (CGRect)globalMenubarViewFrame {
    
    return self.menubarController.statusItemView.window.frame;
}

@end
