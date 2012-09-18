//
//  NVTableRowView.m
//  Anvil
//
//  Created by Elliott Kember on 16/09/2012.
//  Copyright (c) 2012 Riot. All rights reserved.
//

#import "NVTableRowView.h"

@implementation NVTableRowView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
}

- (void)drawSelectionInRect:(NSRect)dirtyRect {
    
    [[NSColor blueColor] set];
    NSRectFill([self bounds]);
    
//    backgroundImage = [NSImage imageNamed:@"SourceSelectionInactive"];
//    [backgroundImage drawInRect:[self bounds] fromRect:NSMakeRect(0.0, 0.0, backgroundImage.size.width, backgroundImage.size.height) operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:nil];
}


@end
