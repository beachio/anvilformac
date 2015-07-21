//
//  NVSiteTableController.m
//  Anvil
//
//  Created by Elliott Kember on 31/07/2012.
//  Copyright (c) 2012 Riot. All rights reserved.
//

#import "NVSiteTableController.h"

@implementation NVSiteTableController

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
    
    return [[[NVDataSource sharedDataSource] apps] count];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {

    return [[NSView alloc] init];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    
    return [[[NVDataSource sharedDataSource] apps] objectAtIndex:rowIndex];
}

// This is not actually used yet.
// TODO: Move the panelcontroller table logic into here.
- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row {
    
    return [[NSTableRowView alloc] init];
}


@end
