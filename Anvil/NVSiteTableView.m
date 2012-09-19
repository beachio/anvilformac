//
//  NVSiteTableView.m
//  Anvil
//
//  Created by Elliott Kember on 31/07/2012.
//  Copyright (c) 2012 Riot. All rights reserved.
//

#import "NVSiteTableView.h"

@implementation NVSiteTableView

- (id)init {
    
//    NSLog(@"asdf");
    self = [super init];
    return self;
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleSourceList];
    }
    
    return self;
}

- (void)awakeFromNib {
    
    [self setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleNone];
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
    [super drawRect:dirtyRect];
}

@end
