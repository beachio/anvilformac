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

@synthesize statusItemView;

#pragma mark -

- (id)init {
    self = [super init];
    if (self != nil) {
        
        NSStatusItem *statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:STATUS_ITEM_VIEW_WIDTH];
        statusItemView = [[NVStatusItemView alloc] initWithStatusItem:statusItem];
        statusItemView.image = [NSImage imageNamed:@"MenubarIcon"];
        statusItemView.alternateImage = [NSImage imageNamed:@"MenubarIconAlt"];
        statusItemView.delegate = self;
    }
    return self;
}

- (void)dealloc {
    
    [[NSStatusBar systemStatusBar] removeStatusItem:self.statusItem];
}

#pragma mark Public accessors

- (NSStatusItem *)statusItem {
    
    return self.statusItemView.statusItem;
}

#pragma mark - Icon

- (void)statusItemView:(NVStatusItemView *)statusItem wasRightClicked:(id)sender {
    
    [self.delegate performSelector:@selector(menuItemRightClicked:) withObject:self];
}

- (void)statusItemView:(NVStatusItemView *)statusItem wasClicked:(id)sender {
    
    [self.delegate performSelector:@selector(togglePanel:) withObject:self];
}

- (BOOL)hasActiveIcon {
    
    return self.statusItemView.isHighlighted;
}

- (void)setHasActiveIcon:(BOOL)flag {
    
    self.statusItemView.isHighlighted = flag;
    self.statusItemView.showHighlightIcon = flag;
}

- (BOOL)showHighlightIcon {
    
    return self.statusItemView.showHighlightIcon;
}

- (void)setShowHighlightIcon:(BOOL)showHighlightIcon {
    
    self.statusItemView.showHighlightIcon = showHighlightIcon;
}

#pragma mark - Dropping

- (BOOL)statusItemView:(NVStatusItemView *)statusItem canReceiveDropURL:(NSURL *)dropURL {
    
    return YES;
}

- (void)statusItemView:(NVStatusItemView *)statusItem didReceiveDropURL:(NSURL *)dropURL {
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(addAppWithURL:)]) {
    
        [self.delegate addAppWithURL:dropURL];
    }
}

@end
