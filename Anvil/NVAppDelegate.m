#import "NVAppDelegate.h"

@interface NVAppDelegate ()

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

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    // Install icon into the menu bar
    self.menubarController = [[NVMenubarController alloc] init];
    [self panelController];
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
    
    self.menubarController.hasActiveIcon = !self.menubarController.hasActiveIcon;
    self.panelController.hasActivePanel = self.menubarController.hasActiveIcon;
}

#pragma mark - Public accessors

- (NVPanelController *)panelController {
    
    if (_panelController == nil) {
        _panelController = [[NVPanelController alloc] initWithDelegate:self];
        [_panelController addObserver:self forKeyPath:@"hasActivePanel" options:0 context:kContextActivePanel];
    }
    return _panelController;
}

#pragma mark - PanelControllerDelegate

- (NVStatusItemView *)statusItemViewForPanelController:(NVPanelController *)controller {
    
    return self.menubarController.statusItemView;
}

- (void)addAppWithURL:(NSURL *)dropURL {
    
    [[NVDataSource sharedDataSource] addAppWithURL:dropURL];
    [[NVDataSource sharedDataSource] readInSavedAppDataFromDisk];
    
    [self.panelController.appListTableView reloadData];
    [self.panelController openPanel];
}

@end
