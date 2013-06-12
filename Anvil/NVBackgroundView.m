#import "NVBackgroundView.h"
#import "NSImage+Additions.h"
#import "BFImage.h"

#define FILL_OPACITY 1.0f
#define STROKE_OPACITY 1.0f

#define LINE_THICKNESS 1.0f
#define CORNER_RADIUS 10.0f

#define SEARCH_INSET 10.0f

#pragma mark -

@implementation NVBackgroundView

@synthesize arrowX = _arrowX;

#pragma mark -

- (id)init {
    
    self = [super init];
    if (self) {
        
//        [self addSubview:self.titlebarPointImageView];
        
//        NSImage *img = [NSImage imageNamed:@"TitlebarPoint"];
//        CGRect imageRect = CGRectMake(0, 0, 10, 10);
//        [img drawInRect:imageRect fromRect:dirtyRect operation:NSCompositeDestinationAtop fraction:1.0];
        
        [self.layer setMasksToBounds:YES];
        
        [self setWantsLayer:YES];
        [self.layer setOpaque:YES];
        [self.layer setCornerRadius:4];
        

    }
    
    return self;
    
}

- (void)awakeFromNib {
    
    self.titlebarPointImageView.backgroundImage = [NSImage imageNamed:@"TitlebarPoint"];
}

- (void)resizeSubviewsWithOldSize:(NSSize)oldSize {
    
    [super resizeSubviewsWithOldSize:oldSize];
//    [self.titlebarPointImageView setFrame:CGRectMake(0, 0, 10, 10)];
}

- (void)drawRect:(NSRect)dirtyRect
{
    
    NSRect footerRect = NSMakeRect(0, 0, dirtyRect.size.width, 34);
    BFImage *image = [NSImage imageNamed:@"Footer.png"];
    [image drawInRect:footerRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    
    NSRect contentRect = dirtyRect;
    contentRect.origin.y = footerRect.size.height;
    contentRect.size.height -= footerRect.size.height;
    contentRect.size.height -= ARROW_HEIGHT;
    contentRect.size.height -= 10;
    [[NSColor colorWithDeviceRed:244.0/255.0 green:244.0/255.0 blue:244.0/255.0 alpha:1.0] set];
    NSRectFill(contentRect);
    
//    dirtyRect.size.height -= ARROW_HEIGHT;
//    [self.backgroundColor set];
//    NSRectFill(dirtyRect);
    
//    NSRect contentRect = NSInsetRect([self bounds], LINE_THICKNESS, LINE_THICKNESS);
//    NSBezierPath *path = [NSBezierPath bezierPath];
//    
//    [path moveToPoint:NSMakePoint(_arrowX, NSMaxY(contentRect) - ARROW_HEIGHT)];
//    // Removed by Elliott - the arrow is an image now.
////    [path lineToPoint:NSMakePoint(_arrowX + ARROW_WIDTH / 2, NSMaxY(contentRect) - ARROW_HEIGHT)];
//    [path lineToPoint:NSMakePoint(NSMaxX(contentRect) - CORNER_RADIUS, NSMaxY(contentRect) - ARROW_HEIGHT)];
//    
//    NSPoint topRightCorner = NSMakePoint(NSMaxX(contentRect), NSMaxY(contentRect) - ARROW_HEIGHT);
//    [path curveToPoint:NSMakePoint(NSMaxX(contentRect), NSMaxY(contentRect) - ARROW_HEIGHT - CORNER_RADIUS)
//         controlPoint1:topRightCorner controlPoint2:topRightCorner];
//    
//    [path lineToPoint:NSMakePoint(NSMaxX(contentRect), NSMinY(contentRect) + CORNER_RADIUS)];
//    
//    NSPoint bottomRightCorner = NSMakePoint(NSMaxX(contentRect), NSMinY(contentRect));
//    [path curveToPoint:NSMakePoint(NSMaxX(contentRect) - CORNER_RADIUS, NSMinY(contentRect))
//         controlPoint1:bottomRightCorner controlPoint2:bottomRightCorner];
//    
//    [path lineToPoint:NSMakePoint(NSMinX(contentRect) + CORNER_RADIUS, NSMinY(contentRect))];
//    
//    [path curveToPoint:NSMakePoint(NSMinX(contentRect), NSMinY(contentRect) + CORNER_RADIUS)
//         controlPoint1:contentRect.origin controlPoint2:contentRect.origin];
//    
//    [path lineToPoint:NSMakePoint(NSMinX(contentRect), NSMaxY(contentRect) - ARROW_HEIGHT - CORNER_RADIUS)];
//    
//    NSPoint topLeftCorner = NSMakePoint(NSMinX(contentRect), NSMaxY(contentRect) - ARROW_HEIGHT);
//    [path curveToPoint:NSMakePoint(NSMinX(contentRect) + CORNER_RADIUS, NSMaxY(contentRect) - ARROW_HEIGHT)
//         controlPoint1:topLeftCorner controlPoint2:topLeftCorner];
//    
//    // Removed by Elliott - the arrow is an image now.
////    [path lineToPoint:NSMakePoint(_arrowX - ARROW_WIDTH / 2, NSMaxY(contentRect) - ARROW_HEIGHT)];
//    [path closePath];
//    
//    [[self backgroundColor] setFill];
//    [path fill];
//    
//    [NSGraphicsContext saveGraphicsState];
//    
//    NSBezierPath *clip = [NSBezierPath bezierPathWithRect:[self bounds]];
//    [clip appendBezierPath:path];
//    [clip addClip];
//    
//    [path setLineWidth:LINE_THICKNESS * 2];
//    [[self backgroundColor] setStroke];
//    [path stroke];
//    
//    [NSGraphicsContext restoreGraphicsState];
    
    
}

- (BOOL)mouseDownCanMoveWindow {
    return NO;
}

#pragma mark -
#pragma mark Public accessors

- (void)setArrowX:(NSInteger)value
{
    _arrowX = value;
    [self setNeedsDisplay:YES];
}

@end
