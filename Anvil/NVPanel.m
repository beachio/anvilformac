//
//  NVPanel.m
//  Anvil
//
//  Created by Elliott Kember on 30/07/2012.
//  Copyright (c) 2012 Riot. All rights reserved.
//

#import "NVPanel.h"

@implementation NVPanel

- (BOOL)canBecomeKeyWindow;
{
    return YES; // Allow Search field to become the first responder
}

@end
