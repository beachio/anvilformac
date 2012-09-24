#define STATUS_ITEM_VIEW_WIDTH 24.0

#pragma mark -

@class NVStatusItemView;
@protocol NVStatusItemViewDelegate;

@interface NVMenubarController : NSObject {
@private
    NVStatusItemView *_statusItemView;
}

@property (nonatomic) BOOL hasActiveIcon;
@property (nonatomic, strong, readonly) NSStatusItem *statusItem;
@property (nonatomic, strong, readonly) NVStatusItemView *statusItemView;
@property (assign, nonatomic) id <NVStatusItemViewDelegate> delegate;

- (void)statusItemView:(NVStatusItemView *)statusItem didReceiveDropURL:(NSURL *)dropURL;

@end