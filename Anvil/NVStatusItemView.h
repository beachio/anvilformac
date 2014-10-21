@interface NVStatusItemView : NSView {
@private
    NSImage *_image;
    NSImage *_alternateImage;
    NSStatusItem *_statusItem;
    BOOL _isHighlighted;
    SEL _action;
    __unsafe_unretained id _target;
}

- (id)initWithStatusItem:(NSStatusItem *)statusItem;

@property (strong, readonly) NSStatusItem *statusItem;
@property (nonatomic, strong) NSImage *image;
@property (nonatomic, strong) NSImage *alternateImage;
@property (nonatomic, strong) NSImage *darkImage;
@property (nonatomic, setter = setHighlighted:) BOOL isHighlighted;
@property (nonatomic, readonly) NSRect globalRect;
@property (nonatomic) SEL action;
@property (assign, nonatomic) SEL rightClickAction;
@property (nonatomic, unsafe_unretained) id target;
@property (nonatomic, unsafe_unretained) id delegate;
@property (assign, nonatomic) BOOL showHighlightIcon;

@end

@protocol NVStatusItemViewDelegate <NSObject>
@optional
- (void)statusItemView:(NVStatusItemView *)statusItem wasClicked:(id)sender;
- (void)statusItemView:(NVStatusItemView *)statusItem wasRightClicked:(id)sender;
- (void)statusItemView:(NVStatusItemView *)statusItem didReceiveDropURL:(NSURL *)dropURL;
- (BOOL)statusItemView:(NVStatusItemView *)statusItem canReceiveDropURL:(NSURL *)dropURL;
- (void)addAppWithURL:(NSURL *)url;
@end
