#import "NVDataSource.h"
#import "NVMenubarController.h"
#import "NVPanelController.h"

@interface NVAppDelegate : NSObject <NSApplicationDelegate, NVPanelControllerDelegate, NVStatusItemViewDelegate>

@property (nonatomic, strong) NVMenubarController *menubarController;
@property (nonatomic, strong) NVPanelController *panelController;

- (IBAction)togglePanel:(id)sender;

@end
