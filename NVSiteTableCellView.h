//
//  NVSiteTableCellView.h
//  Anvil
//
//  Created by Elliott Kember on 31/07/2012.
//  Copyright (c) 2012 Riot. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NVLabel.h"
#import "NVLayeredImageView.h"

@interface NVSiteTableCellView : NSTableCellView

@property (weak, nonatomic) IBOutlet NVLabel *titleLabel;
@property (weak, nonatomic) IBOutlet NVLayeredImageView *faviconImageView;

@end
