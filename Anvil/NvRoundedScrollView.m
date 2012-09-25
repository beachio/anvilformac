//
//  NVRoundedScrollView.m
//  Anvil
//
//  Created by Elliott Kember on 25/09/2012.
//  Copyright (c) 2012 Riot. All rights reserved.
//

#import "NVRoundedScrollView.h"

@implementation NVRoundedScrollView

- (void)awakeFromNib {
    
    [self.layer setMasksToBounds:YES];
    [self setWantsLayer:YES];
    [self.layer setOpaque:NO];
    [self.layer setCornerRadius:4];
    [self.contentView setWantsLayer:YES];
    [self setBackgroundColor:[NSColor clearColor]];
}

- (BOOL)isOpaque {
    
    return NO;
}

@end
