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
}

#pragma mark - NSApplicationDelegate activation, launching and terminating

- (void)applicationDidBecomeActive:(NSNotification *)notification {

    [[NVDataSource sharedDataSource] readInSavedAppDataFromDisk];
    [self.panelController.appListTableView reloadData];
    [self.panelController setHasActivePanel:YES];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    
    // Install icon into the menu bar
    self.menubarController = [[NVMenubarController alloc] init];
    
    self.panelController = [[NVPanelController alloc] initWithDelegate:self];
    [self.panelController addObserver:self forKeyPath:@"hasActivePanel" options:0 context:kContextActivePanel];
    
    self.menubarController.delegate = self;

    [[NVDataSource sharedDataSource] readInSavedAppDataFromDisk];
    [self.panelController.appListTableView reloadData];
    [self.panelController setHasActivePanel:YES];

    [self.dataSource readInSavedAppDataFromDisk];
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
            [[NVDataSource sharedDataSource] readInSavedAppDataFromDisk];
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

#pragma mark - Adding apps

//- (void)addAppWithURL:(NSURL *)url andName:(NSString *)name {
//    
//    NVApp *addedApp = [[NVDataSource sharedDataSource] addAppWithURL:url andName:name];
//    [[NVDataSource sharedDataSource] readInSavedAppDataFromDisk];
//    
//    [self.panelController.appListTableView reloadData];
//    self.panelController.hasActivePanel = YES;
//    
//    NSNumber *indexOfNewlyAddedRow = [NSNumber numberWithInteger:[[NVDataSource sharedDataSource] indexOfAppWithURL:url]];
//    [self.panelController performSelector:@selector(beginEditingRowAtIndex:) withObject:indexOfNewlyAddedRow afterDelay:0.4];
//
//    
//    NSAlert *indexPrompt = [[NSAlert alloc] init];
//    [indexPrompt setInformativeText:@"Testing"];
//    
////    [indexPrompt beginSheetModalForWindow:[NSApp mainWindow] modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
//    
//    if([indexPrompt runModal]) {
//        NSLog(@"A");
//    }
//    
//    if (![addedApp isARackApp]) {
//        
//        NSAlert *indexPrompt = [[NSAlert alloc] init];
//        [indexPrompt setInformativeText:@"Testing"];
//        
//        [addedApp createIndexFileIfNonExistentAndNotARackApp];
//    }
//}

- (void)addAppWithURL:(NSURL *)dropURL {
    
    NVApp *addedApp = [[NVDataSource sharedDataSource] addAppWithURL:dropURL];
    [[NVDataSource sharedDataSource] readInSavedAppDataFromDisk];
    
    self.panelController.hasActivePanel = YES;
    
    if ([addedApp needsAnIndexFile]) {
    
        NSAlert *indexPrompt = [[NSAlert alloc] init];
        [indexPrompt setInformativeText:@"It looks like you don't have an index.html file in this directory. Would you like one?"];
        [indexPrompt addButtonWithTitle:@"Add an index.html file"];
        [indexPrompt addButtonWithTitle:@"Don't add anything."];

        BOOL doesWantAnIndexFile = [indexPrompt runModal];
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
