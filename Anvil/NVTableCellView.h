//
//  NVTableCellView.h
//  Anvil
//
//  Created by Elliott Kember on 16/09/2012.
//  Copyright (c) 2012 Riot. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NVLayeredImageView.h"
#import "NVLabel.h"

@interface NVTableCellView : NSTableCellView

@property (weak, atomic) IBOutlet NVLabel *siteLabel;
@property (weak, nonatomic) IBOutlet NVLabel *localLabel;
@property (weak, nonatomic) IBOutlet NVLayeredImageView *faviconImageView;
@property (weak, nonatomic) IBOutlet NSButton *restartButton;
@property (weak, nonatomic) IBOutlet NSButton *deleteButton;

- (void)showControls;
- (void)hideControls;

@end
