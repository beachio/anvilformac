//
//  NVSwitchView.h
//  Anvil
//
//  Created by Elliott Kember on 18/09/2012.
//  Copyright (c) 2012 Riot. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NVStyledView.h"

@protocol NVSwitchDelegate;

@interface NVSwitchView : NVStyledView

@property (assign, nonatomic) id <NVSwitchDelegate> delegate;

@property (strong, atomic) IBOutlet NVStyledView *backgroundView;
@property (strong, atomic) IBOutlet NVStyledView *switcherView;

- (void)turnOn;
- (void)turnOff;
- (void)switchTo:(BOOL)position withAnimation:(BOOL)useAnimation;

@end


@protocol NVSwitchDelegate <NSWindowDelegate>

@optional
//- (void)tableView:(NSTableView *)tableView didClickAddProjectButton:(NSButton *)button;
//- (NSMenu *)tableView:(HMAppListTableView *)tableView menuForTableColumn:(NSInteger)column row:(NSInteger)row;
- (void)switchView:(NVSwitchView *)switchView didSwitchTo:(BOOL)state;
@end
