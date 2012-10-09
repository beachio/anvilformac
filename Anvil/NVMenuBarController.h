#define STATUS_ITEM_VIEW_WIDTH 28.0

#pragma mark -

@class NVStatusItemView;
@protocol NVStatusItemViewDelegate;

@interface NVMenubarController : NSObject {
@private
    NVStatusItemView *_statusItemView;
}

@property (readwrite, nonatomic) BOOL showHighlightIcon; //Added this as to not mess with hasActiveIcon
@property (assign, nonatomic) BOOL hasActiveIcon;
@property (nonatomic, strong, readonly) NSStatusItem *statusItem;
@property (nonatomic, strong, readonly) NVStatusItemView *statusItemView;
@property (assign, nonatomic) id <NVStatusItemViewDelegate> delegate;

- (void)statusItemView:(NVStatusItemView *)statusItem didReceiveDropURL:(NSURL *)dropURL;

@end