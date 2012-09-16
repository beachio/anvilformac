//
//  NVSiteTableController.h
//  Anvil
//
//  Created by Elliott Kember on 31/07/2012.
//  Copyright (c) 2012 Riot. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NVDataSource.h"

@interface NVSiteTableController : NSController <NSTableViewDataSource, NSTableViewDelegate>

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex;
-(NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView;
//- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row;

@end
