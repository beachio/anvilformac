#import "NVBackgroundView.h"
#import "NVStatusItemView.h"
#import "NVDataSource.h"
#import "NVStyledView.h"

@class NVPanelController;

@protocol NVPanelControllerDelegate <NSObject>

@optional

- (NVStatusItemView *)statusItemViewForPanelController:(NVPanelController *)controller;

@end

#pragma mark -

@interface NVPanelController : NSWindowController <NSWindowDelegate, NSTableViewDelegate, NSTableViewDelegate, NSTextFieldDelegate> {
    BOOL _hasActivePanel;
    __unsafe_unretained NVBackgroundView *_backgroundView;
    __unsafe_unretained id<NVPanelControllerDelegate> _delegate;
    __unsafe_unretained NSSearchField *_searchField;
    __unsafe_unretained NSTextField *_textField;
}

@property (weak, nonatomic) IBOutlet NSTableView *appListTableView;
@property (nonatomic, unsafe_unretained) IBOutlet NVBackgroundView *backgroundView;
@property (nonatomic, unsafe_unretained) IBOutlet NSSearchField *searchField;
@property (nonatomic, unsafe_unretained) IBOutlet NSTextField *textField;
@property (nonatomic, unsafe_unretained) IBOutlet NSScrollView *appListTableScrollView;
@property (nonatomic, unsafe_unretained) IBOutlet NVStyledView *headerView;
@property (nonatomic, unsafe_unretained) IBOutlet NVStyledView *headerIconView;

@property (nonatomic) BOOL hasActivePanel;
@property (nonatomic, unsafe_unretained, readonly) id<NVPanelControllerDelegate> delegate;

- (id)initWithDelegate:(id<NVPanelControllerDelegate>)delegate;

- (void)openPanel;
- (void)closePanel;
- (NSRect)statusRectForWindow:(NSWindow *)window;

@end
