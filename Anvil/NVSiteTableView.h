//
//  NVSiteTableView.h
//  Anvil
//
//  Created by Elliott Kember on 31/07/2012.
//  Copyright (c) 2012 Riot. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NVStyledView.h"

@interface NVSiteTableView : NSTableView
@property (nonatomic, unsafe_unretained) id clickDelegate;
@end

@protocol NVSiteTableViewClickDelegate <NSObject>
@optional
- (void)tableView:(NSTableView *)tableView wasRightClickedAndNeedsAMenu:(NSEvent *)theEvent;
@end
