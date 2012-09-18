//
//  NVSwitchView.h
//  Anvil
//
//  Created by Elliott Kember on 18/09/2012.
//  Copyright (c) 2012 Riot. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NVStyledView.h"

@interface NVSwitchView : NVStyledView

@property (strong, atomic) IBOutlet NVStyledView *backgroundView;
@property (strong, atomic) IBOutlet NVStyledView *switcherView;

- (void)turnOn;
- (void)turnOff;

@end
