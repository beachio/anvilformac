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

- (BOOL)isOpaque {
    
    return NO;
}

- (void)drawRect:(NSRect)dirtyRect {
    
    // This is the top line on the group bar.
    // This is how we get the border above the Hammer sites bar!
    [[NSColor colorWithDeviceRed:225.0/255.0 green:225.0/255.0 blue:225.0/255.0 alpha:1.0] set];
    NSRectFill(dirtyRect);
}

@end
