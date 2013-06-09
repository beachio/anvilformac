#import "NVAppDelegate.h"

@interface NVAppDelegate () <NSMenuDelegate>

@end


@implementation NVAppDelegate

@synthesize panelController = _panelController;
@synthesize menubarController = _menubarController;

void *kContextActivePanel = &kContextActivePanel;

#pragma mark - Observers

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if (context == kContextActivePanel) {
        self.menubarController.hasActiveIcon = self.panelController.hasActivePanel;
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
    [self.menubarController.statusItemView setNeedsDisplay:YES];
}

#pragma mark - NSApplicationDelegate activation, launching and terminating

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    
    // This fixes the final switch view bug.
    [self.menubarController.statusItemView setNeedsDisplay:YES];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    
    // Install icon into the menu bar
    self.menubarController = [[NVMenubarController alloc] init];    
    self.menubarController.delegate = self;
    self.menubarController.statusItemView.needsDisplay = YES;
    
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self
                                                           selector: @selector(receiveWakeNote:)
                                                               name: NSWorkspaceDidWakeNotification object: NULL];
    
    [[NVDataSource sharedDataSource] performSelectorInBackground:@selector(readInSavedAppDataFromDisk) withObject:nil];
    
    // Initialize it
    [self panelController];
    NSTimer *mainLoopTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(readSites) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:mainLoopTimer forMode:NSEventTrackingRunLoopMode];
}

- (void)readSites {
    
    [[NVDataSource sharedDataSource] performSelectorInBackground:@selector(readInSavedAppDataFromDisk) withObject:nil];
}

- (void)applicationDidChangeScreenParameters:(NSNotification *)notification {
    
    self.menubarController.statusItemView.needsDisplay = YES;
}

- (void)applicationWillUpdate:(NSNotification *)notification {

    self.menubarController.statusItemView.needsDisplay = YES;
}

- (void)receiveWakeNote:(id)sender {
    
    self.menubarController.statusItemView.needsDisplay = YES;
}  

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    // Explicitly remove the icon from the menu bar
    self.menubarController = nil;
    return NSTerminateNow;
}

#pragma mark - dataSource

- (NVDataSource *)dataSource {
    
    return [NVDataSource sharedDataSource];
}

- (NVPanelController *)panelController {
    
    if (!_panelController) {
        
        _panelController = [[NVPanelController alloc] initWithWindowNibName:@"Panel"];
        [_panelController addObserver:self forKeyPath:@"hasActivePanel" options:0 context:kContextActivePanel];
        _panelController.delegate = self;
    }
    return _panelController;
}

#pragma mark - Actions

- (IBAction)togglePanel:(id)sender {
    
    NSEvent *theEvent = [NSApp currentEvent];
    
    if ([theEvent modifierFlags] & NSControlKeyMask) {
        
        [self panelController].hasActivePanel = NO;
        [self menuItemRightClicked:sender];
    } else {
        
        self.menubarController.showHighlightIcon = !self.menubarController.hasActiveIcon;
        self.menubarController.hasActiveIcon = !self.menubarController.hasActiveIcon;
//        if (!self.panelController.hasActivePanel) {
            // Read in apps if we're opening it
//            [[NVDataSource sharedDataSource] readInSavedAppDataFromDisk];
//        }
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

#pragma mark - Adding apps

- (void)addAppWithURL:(NSURL *)dropURL {
    
    NVApp *addedApp = [[NVDataSource sharedDataSource] addAppWithURL:dropURL];
    [[NVDataSource sharedDataSource] readInSavedAppDataFromDisk];
    
    self.panelController.hasActivePanel = YES;
    
    if ([addedApp needsAnIndexFile]) {
        
        NSAlert *indexPrompt = [[NSAlert alloc] init];
        indexPrompt.messageText = @"Caution, 404 ahead!";
        indexPrompt.informativeText = @"It looks like you don't have an index.html file in this directory. Would you like one?";
        
        [indexPrompt addButtonWithTitle:@"Add index.html"];
        [indexPrompt addButtonWithTitle:@"Don't Add Anything"];
        
        NSInteger result = [indexPrompt runModal];
        BOOL doesWantAnIndexFile = result == NSAlertFirstButtonReturn;
        
        if(doesWantAnIndexFile) {
            
            [addedApp createIndexFileIfNonExistentAndNotARackApp];
        }
    }
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

#pragma mark - deallocation

- (void)dealloc {
    
    [_panelController removeObserver:self forKeyPath:@"hasActivePanel"];
}

@end
