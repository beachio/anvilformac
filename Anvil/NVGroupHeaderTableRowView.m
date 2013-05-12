//
//  NVGroupHeaderTableRowView.m
//  Anvil
//
//  Created by Elliott Kember on 12/05/2013.
//  Copyright (c) 2013 Riot. All rights reserved.
//

#import "NVGroupHeaderTableRowView.h"
#import "NVLabel.h"

@implementation NVGroupHeaderTableRowView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        
        NVLabel *label = [[NVLabel alloc] initWithFrame:NSMakeRect(3, 2, 120, 16)];
        [label setFont:[NSFont systemFontOfSize:11.0]];
        [label setStringValue:@"Hammer sites"];
        [self addSubview:label];
    }
    
    return self;
}

- (void)awakeFromNib {

}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    NSImage *titleBarImage = [NSImage imageNamed:@"Titlebar"];
    
    NSRect adjustedDirtyRect = dirtyRect;
    adjustedDirtyRect.origin.y = -10;
    [titleBarImage drawInRect:dirtyRect fromRect:NSZeroRect operation:NSCompositeDestinationOver fraction:1.0];
    
}

@end
