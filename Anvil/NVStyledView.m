//
//  MyStyledView.m
//  MyStyledView
//
//  Created by Joe Ricioppo on 1/9/11.
//  BSD License
//

#import "NVStyledView.h"
#import "NSBezierPath+Additions.h"
#import "NSImage+Additions.h"

@interface NVStyledView ()
@property (nonatomic, strong) NSImage *cacheImage;
- (void)renderStyle;
@end


@implementation NVStyledView

@synthesize gradient;
@synthesize gradientAngle;
@synthesize inactiveGradient;
@synthesize backgroundColor;
@synthesize inactiveBackgroundColor;
@synthesize backgroundImage;
@synthesize inactiveBackgroundImage;
@synthesize leftCapWidth;
@synthesize topCapHeight;
@synthesize topEdgeColor;
@synthesize topHighlightColor;
@synthesize bottomHighlightColor;
@synthesize bottomEdgeColor;
@synthesize leftEdgeGradient;
@synthesize rightEdgeGradient;
@synthesize innerShadow;
@synthesize innerGlow;
@synthesize cacheImage;
@synthesize styleBlock;
@synthesize shouldRasterize;
@synthesize shouldTile;

- (id)initWithFrame:(NSRect)frameRect {
    
    self = [super initWithFrame:frameRect];
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(windowDidBecomeActive:) name:NSApplicationDidBecomeActiveNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(windowDidBecomeInactive:) name:NSApplicationDidResignActiveNotification object:nil];
    
    return self;
}

- (void)dealloc {
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self name:NSApplicationDidBecomeActiveNotification object:nil];
    [notificationCenter removeObserver:self name:NSApplicationDidResignActiveNotification object:nil];
}

- (void)windowDidBecomeActive:(id)sender {
    
    [self renderStyle];
    self.needsDisplay = YES;
}

- (void)windowDidBecomeInactive:(id)sender {
    
    [self renderStyle];
    self.needsDisplay = YES;
}

- (void)drawRect:(NSRect)dirtyRect {
	
	if ([self isHiddenOrHasHiddenAncestor]) {
		return;
	}
	
	BOOL isCaching = self.shouldRasterize && self.cacheImage == nil;
	if (isCaching) {
		self.cacheImage = [[NSImage alloc] initWithSize:self.bounds.size];
		[self.cacheImage lockFocus];
	}
	
	// only render if we're re-drawing for the cache or if we're not caching
	if (self.shouldRasterize == NO || isCaching) {
		[self renderStyle];
	}
	
	if (isCaching) {
		[self.cacheImage unlockFocus];
	}
	
	if (self.shouldRasterize) {
		[self.cacheImage drawInRect:dirtyRect fromRect:dirtyRect operation:NSCompositeSourceOver fraction:1.0];
	}
}

- (void)renderStyle {
	
	NSRect rect = self.bounds;
	BOOL isKeyWindow = [[self window] isKeyWindow];
    
	NSColor *backgroundColorToDraw = isKeyWindow ? self.backgroundColor : self.inactiveBackgroundColor ? : self.backgroundColor;
	if (backgroundColorToDraw != nil) {
		[backgroundColorToDraw set];
		NSRectFill(rect);
	}
    
	NSGradient *gradientToDraw = isKeyWindow ? self.gradient : self.inactiveGradient ? : self.gradient;
	if (gradientToDraw) {
		[gradientToDraw drawInRect:rect angle:self.gradientAngle ? : self.isFlipped ? 90 : -90];
	}
	
	NSImage *backgroundImageToDraw = isKeyWindow ? self.backgroundImage : self.inactiveBackgroundImage ? : self.backgroundImage;
	if (backgroundImageToDraw) {
        
        if(self.shouldTile){
            [self.layer setOpaque:NO];
            
            NSColor *color = [NSColor colorWithPatternImage:backgroundImageToDraw];
            NSPoint corner = NSMakePoint(self.frame.origin.x, self.frame.origin.y);
            [[NSGraphicsContext currentContext] setPatternPhase:corner];
            
            [color setFill];
            NSRectFillUsingOperation(rect, NSCompositeSourceOver);
            
        }else{
            
            if (self.leftCapWidth != 0 || self.topCapHeight != 0) {
                
                [backgroundImageToDraw drawInRect:rect withLeftCapWidth:self.leftCapWidth topCapHeight:self.topCapHeight];
            } else {
                
                [backgroundImageToDraw drawInRect:rect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
            }
        }
    }
    
	CGFloat topInset = 0.0;
	CGFloat bottomInset = 0.0;
	CGFloat leftInset = 0.0;
	CGFloat rightInset = 0.0;
	
	if (self.topEdgeColor) {
		topInset += 1.0;
		NSBezierPath *topHighlightPath = [NSBezierPath bezierPath];
		[topHighlightPath setLineWidth:0.0];
		[topHighlightPath moveToPoint:NSPointFromCGPoint(CGPointMake(rect.origin.x, NSMaxY(rect) -0.5))];
		[topHighlightPath lineToPoint:NSPointFromCGPoint(CGPointMake(NSMaxX(rect), NSMaxY(rect) -0.5))];
		[topHighlightPath closePath];
		
		[self.topEdgeColor set];
		[topHighlightPath stroke];
	}
	
	if (self.topHighlightColor) {
		topInset += 1.0;
		NSBezierPath *topHighlightPath = [NSBezierPath bezierPath];
		[topHighlightPath setLineWidth:0.0];
		[topHighlightPath moveToPoint:NSPointFromCGPoint(CGPointMake(rect.origin.x, NSMaxY(rect) -1.5))];
		[topHighlightPath lineToPoint:NSPointFromCGPoint(CGPointMake(NSMaxX(rect), NSMaxY(rect) -1.5))];
		[topHighlightPath closePath];
		
		[self.topHighlightColor set];
		[topHighlightPath stroke];
	}
	
	if (self.bottomHighlightColor) {
		bottomInset += 1.0;
		NSBezierPath *bottomHighlightPath = [NSBezierPath bezierPath];
		[bottomHighlightPath setLineWidth:1.0];
		[bottomHighlightPath moveToPoint:NSPointFromCGPoint(CGPointMake(rect.origin.x, rect.origin.y + 1.5))];
		[bottomHighlightPath lineToPoint:NSPointFromCGPoint(CGPointMake(NSMaxX(rect), rect.origin.y + 1.5))];
		[bottomHighlightPath closePath];
		
		[self.bottomHighlightColor set];
		[bottomHighlightPath stroke];
	}
	
	if (self.bottomEdgeColor) {
		bottomInset += 1.0;
		NSBezierPath *bottomEdgePath = [NSBezierPath bezierPath];
		[bottomEdgePath setLineWidth:1.0];
		[bottomEdgePath moveToPoint:NSPointFromCGPoint(CGPointMake(rect.origin.x, rect.origin.y + 0.5))];
		[bottomEdgePath lineToPoint:NSPointFromCGPoint(CGPointMake(NSMaxX(rect), rect.origin.y + 0.5))];
		[bottomEdgePath closePath];
		
		[self.bottomEdgeColor set];
		[bottomEdgePath stroke];
	}
	
	if (self.leftEdgeGradient) {
		leftInset += 1.0;
		NSRect edgeRect = NSMakeRect(0.0, 0.0, 1.0, NSMaxY(rect));
		edgeRect.origin.y += bottomInset;
		edgeRect.size.height -= (bottomInset + topInset);
		[self.leftEdgeGradient drawInRect:edgeRect angle:self.isFlipped ? 90 : -90];
	}
	
	if (self.rightEdgeGradient) {
		rightInset += 1.0;
		NSRect edgeRect = NSMakeRect((NSMaxX(rect) - 1.0), 0.0, 1.0, NSMaxY(rect));
		edgeRect.origin.y += bottomInset;
		edgeRect.size.height -= (bottomInset + topInset);
		[self.rightEdgeGradient drawInRect:edgeRect angle:self.isFlipped ? 90 : -90];
	}
	
	CGRect shadowRect = rect;
	shadowRect.origin.x += leftInset;
	shadowRect.size.width -= (leftInset + rightInset);
	shadowRect.origin.y += bottomInset;
	shadowRect.size.height -= (bottomInset + topInset);
	
	if (self.innerShadow) {
		NSBezierPath *innerShadowPath = [NSBezierPath bezierPathWithRect:shadowRect];
		[innerShadowPath fillWithInnerShadow:self.innerShadow];
	}
	
	if (self.innerGlow) {
		NSBezierPath *innerGlowPath = [NSBezierPath bezierPathWithRect:shadowRect];
		[innerGlowPath fillWithInnerShadow:self.innerGlow];
	}
	
	if (self.styleBlock) {
		self.styleBlock(rect);
	}
}

- (void)setFrameSize:(NSSize)newSize {
	
	if (newSize.width != self.frame.size.width || newSize.height != self.frame.size.height) {
		[self invalidateRasterization];
	}
	
	[super setFrameSize:newSize];
}

- (void)invalidateRasterization {
	
	self.cacheImage = nil;
	[self setNeedsDisplay:YES];
}

- (void)setShouldRasterize:(BOOL)rasterize {
	
	shouldRasterize = rasterize;
	[self invalidateRasterization];
}

- (void)makeTransparent {
    
    [self.layer setOpaque:NO];
}

@end
