//
//  NVMenuBarController.m
//  Anvil
//
//  Created by Elliott Kember on 30/07/2012.
//  Copyright (c) 2012 Riot. All rights reserved.
//
#import "NVMenubarController.h"
#import "NVStatusItemView.h"
#import "NVDataSource.h"

@implementation NVMenubarController

@synthesize statusItemView = _statusItemView;

#pragma mark -

- (id)init {
    self = [super init];
    if (self != nil) {
        NSStatusItem *statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:STATUS_ITEM_VIEW_WIDTH];
        _statusItemView = [[NVStatusItemView alloc] initWithStatusItem:statusItem];
        _statusItemView.image = [NSImage imageNamed:@"MenubarIcon"];
        _statusItemView.alternateImage = [NSImage imageNamed:@"MenubarIconGlow"];
        _statusItemView.action = @selector(togglePanel:);
        _statusItemView.delegate = self;
    }
    return self;
}

- (void)dealloc {
    [[NSStatusBar systemStatusBar] removeStatusItem:self.statusItem];
}

#pragma mark -
#pragma mark Public accessors

- (NSStatusItem *)statusItem {
    
    return self.statusItemView.statusItem;
}

#pragma mark -

- (BOOL)hasActiveIcon {
    return self.statusItemView.isHighlighted;
}

- (void)setHasActiveIcon:(BOOL)flag {
    self.statusItemView.isHighlighted = flag;
}

- (BOOL)statusItemView:(NVStatusItemView *)statusItem canReceiveDropURL:(NSURL *)dropURL {
    return YES;
}

- (void)statusItemView:(NVStatusItemView *)statusItem didReceiveDropURL:(NSURL *)dropURL {
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(addAppWithURL:)]) {
    
        [self.delegate addAppWithURL:dropURL];
    }
}

@end
