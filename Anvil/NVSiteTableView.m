//
//  NVSiteTableView.m
//  Anvil
//
//  Created by Elliott Kember on 31/07/2012.
//  Copyright (c) 2012 Riot. All rights reserved.
//

#import "NVSiteTableView.h"


@interface NVSiteTableView ()

@property (strong, nonatomic) IBOutlet NVStyledView *welcomeView;
@property (strong, nonatomic) IBOutlet NVStyledView *noSitesView;

@end

@implementation NVSiteTableView

- (void)awakeFromNib {
    
    [self setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleNone];
    [self setRowHeight:48.0];
}

- (BOOL)isOpaque {
    
    return NO;
}

- (void)rightMouseDown:(NSEvent *)theEvent {
    
    if (self.clickDelegate && [self.clickDelegate respondsToSelector:@selector(tableView:wasRightClickedAndNeedsAMenu:)]) {
        
        [self.clickDelegate tableView:self wasRightClickedAndNeedsAMenu:theEvent];
    }
    
    [super rightMouseDown:theEvent];
}

@end
