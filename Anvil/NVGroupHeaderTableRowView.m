//
//  NVGroupHeaderTableRowView.m
//  Anvil
//
//  Created by Elliott Kember on 12/05/2013.
//  Copyright (c) 2013 Riot. All rights reserved.
//

#import "NVGroupHeaderTableRowView.h"
#import "BFImage.h"
#import "NSImage+Additions.h"

@implementation NVGroupHeaderTableRowView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {

    }
    
    return self;
}

- (void)awakeFromNib {

}

- (BOOL)isOpaque {
    
    return NO;
}

- (void)drawRect:(NSRect)dirtyRect
{
    
    [[NSColor colorWithDeviceRed:235.0/255.0 green:235.0/255.0 blue:235.0/255.0 alpha:1.0] set];
    NSRectFill(dirtyRect);
//    [super drawRect:dirtyRect];
    
//    // TODO: Check retina
//    NSImage *titleBarImage = [NSImage imageNamed:@"HammerHeader"];
//    
//    NSRect adjustedDirtyRect = dirtyRect;
//    adjustedDirtyRect.origin.y = -10;
//    [titleBarImage drawInRect:dirtyRect fromRect:NSZeroRect operation:NSCompositeDestinationOver fraction:1.0];
//
//    [[NSColor darkGrayColor] set];
//    NSRectFill(dirtyRect);
//
//    NSImage *titleBarImage = [[NSImage imageNamed:@"HammerHeader.png"] image];
//    
//    [titleBarImage drawInRect:dirtyRect withLeftCapWidth:1.0 topCapHeight:1.0];
//    [titleBarImage drawInRect:[self bounds] fromRect:NSZeroRect operation:NSCompositeDestinationOver fraction:1.0];
////    [titleBarImage drawInRect:[self bounds] fromRect:NSZeroRect operation:NSCompositeDestinationOver fraction:1.0 respectFlipped:YES hints:nil];
//    [[NSColor whiteColor] set];
//    NSRectFill(dirtyRect);
////    NSImage *titleBarImage = [NSImage imageNamed:@"HammerHeader.png"];
//    [titleBarImage drawInRect:dirtyRect withLeftCapWidth:1.0 topCapHeight:1.0];

}

@end
