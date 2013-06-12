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
#import "NVStyledButton.h"
#import "NVSpinnerButton.h"

@interface NVTableCellView : NSTableCellView

@property (weak, atomic) IBOutlet NVLabel *siteLabel;
@property (weak, nonatomic) IBOutlet NVLabel *localLabel;
@property (weak, nonatomic) IBOutlet NVLayeredImageView *faviconImageView;
@property (weak, nonatomic) IBOutlet NVSpinnerButton *restartButton;
@property (weak, nonatomic) IBOutlet NVStyledButton *deleteButton;
@property (weak, nonatomic) IBOutlet NVStyledButton *reallyDeleteButton;
@property BOOL isHammer;
@property BOOL darkTopBorder;
@property BOOL isHovered;

@property BOOL hideTopBorder;
@property BOOL hideBottomBorder;

@property (atomic) BOOL showRestartButton;

- (void)showControls;
- (void)hideControls;
- (void)showReallyDeleteButton;
- (void)hideReallyDeleteButton;

- (void)spinRestartButton;

@end
