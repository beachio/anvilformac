//
//  NVStyledButton.m
//  Anvil
//
//  Created by Elliott Kember on 27/09/2012.
//  Copyright (c) 2012 Riot. All rights reserved.
//

#import "NVStyledButton.h"
#import "BFImage.h"
#import "AppKit+Additions.h"
#import "CustomLoadingSpinner.h"

@interface NVStyledButton ()
@property (atomic) BFEdgeInsets insets;
@property BOOL hovered;
@end

@implementation NVStyledButton

- (id)init
{
    self = [super init];
    if (self) {
        
        self.hovered = NO;
    }
    return self;
}

- (void)awakeFromNib
{
    self.hovered = NO;
    self.textSize = 11.0;
    self.insets = BFEdgeInsetsMake(1.0, 5.0, 1.0, 5.0);
    self.isBold = YES;
    self.hovered = NO;
    int opts = (NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways);
    NSTrackingArea *trackingArea = [ [NSTrackingArea alloc] initWithRect:[self bounds]
                                                                 options:opts
                                                                   owner:self
                                                                userInfo:nil];
    [self addTrackingArea:trackingArea];
}

- (void)setInsetsWithTop:(CGFloat)top right:(CGFloat)right bottom:(CGFloat)bottom left:(CGFloat)left
{
    self.insets = BFEdgeInsetsMake(top, left, bottom, right);
}

- (BFEdgeInsets)insetsOrDefaults
{
    BFEdgeInsets myInsets;
    if (self.insets.top == 0.0 && self.insets.right == 0.0 && self.insets.bottom == 0.0 && self.insets.left == 0.0) {
        myInsets = BFEdgeInsetsMake(1.0, 5.0, 1.0, 5.0);
    } else {
        myInsets = self.insets;
    }
    return myInsets;
}

- (void)drawRect:(NSRect)dirtyRect
{
    NSImage *image = nil;
    if ([self state]) {
        image = [self.alternateImage stretchableImageWithEdgeInsets:self.insetsOrDefaults];
    } else {
        if (self.hovered && self.hoverImage) {

            image = [self.hoverImage stretchableImageWithEdgeInsets:self.insetsOrDefaults];
        } else {
            image = [self.image stretchableImageWithEdgeInsets:self.insetsOrDefaults];
        }
    }
    [image setFlipped:YES];
    
    [image drawInRect:dirtyRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:nil];
    
    NSDictionary *att = nil;
    
    NSMutableParagraphStyle *style =
    [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [style setLineBreakMode:NSLineBreakByWordWrapping];
    [style setAlignment:NSCenterTextAlignment];
    
    NSShadow *textShadow = [NSShadow shadowWithColor:[NSColor colorWithDeviceWhite:0 alpha:0.4] offset:NSMakeSize(0.0, 1.0) blurRadius:0.0];
    
    NSFont *fontToUse = self.isBold ? [NSFont boldSystemFontOfSize:self.textSize] : [NSFont systemFontOfSize:self.textSize];
    att = [[NSDictionary alloc] initWithObjectsAndKeys:
           style, NSParagraphStyleAttributeName,
           [NSColor whiteColor],
           NSForegroundColorAttributeName,
           textShadow,
           NSShadowAttributeName,
           fontToUse,
           NSFontAttributeName,
           nil];
    
    NSInteger textHeight = floor([self.title sizeWithAttributes:att].height);
    
    CGRect bounds = self.bounds;
    bounds.origin.y = (bounds.size.height - textHeight) / 2;
    if (fmod(self.textSize, 2) != 0) {
        // Odd. Move it to even.
        bounds.origin.y -= 1;
    } else {
        bounds.origin.y -= 2;
    }
    
    if (self.textOffset != 0) {
        bounds.origin.y += self.textOffset;
    }
    
    bounds.size.height = textHeight;
        
    [self.title drawInRect:bounds withAttributes:att];
}

- (void)mouseEntered:(NSEvent *)theEvent
{
    self.hovered = YES;
    [self setNeedsDisplay:YES];
}

- (void)mouseDown:(NSEvent *)theEvent
{
    if (!self.isEnabled) {
        return;
    }
    
    self.state = NSOnState;
    [super mouseDown:theEvent];
}

- (void)mouseUp:(NSEvent *)theEvent
{
    self.state = NSOffState;
    [super mouseUp:theEvent];
}

- (void)draggingExited:(id<NSDraggingInfo>)sender
{
    self.state = NSOffState;
    [super draggingExited:sender];
}

- (void)mouseExited:(NSEvent *)theEvent
{
    self.hovered = NO;
    [self setNeedsDisplay:YES];    
    self.state = NSOffState;
    [super mouseExited:theEvent];
}

@end
