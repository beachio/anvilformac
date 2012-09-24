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

- (void)drawRect:(NSRect)dirtyRect {
    
    [super drawRect:dirtyRect];
    
    // Top and bottom borders for rows
    
    NSTableView *tableView = (NSTableView*)[self superview]; // The table view the row is part of
    NSInteger ownRowNumber = [tableView rowForView:self];
    NSInteger numberOfRows = [tableView numberOfRows];
    
    if (ownRowNumber < numberOfRows) {
        NSRect bottomDrawingRect = [self frame];
        bottomDrawingRect.origin.y = bottomDrawingRect.size.height - 1.0;
        bottomDrawingRect.size.height = 1.0;
        [[NSColor colorWithDeviceRed:219.0/255.0 green:219.0/255.0 blue:219.0/255.0 alpha:1.0] set];
        NSRectFill(bottomDrawingRect);
    }
    
    if (ownRowNumber > 0) {
        NSRect topDrawingRect = [self frame];
        topDrawingRect.origin.y = 0;
        topDrawingRect.size.height = 1;
        [[NSColor whiteColor] set];
        NSRectFill (topDrawingRect);
    }
}

@end
