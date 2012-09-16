//
//  NVSiteTableController.m
//  Anvil
//
//  Created by Elliott Kember on 31/07/2012.
//  Copyright (c) 2012 Riot. All rights reserved.
//

#import "NVSiteTableController.h"

@implementation NVSiteTableController

-(NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
    
    return [[[NVDataSource sharedDataSource] apps] count];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {

    return [[NSView alloc] init];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    
    NVApp *app = [[[NVDataSource sharedDataSource] apps] objectAtIndex:rowIndex];
    
    
    return app;
}

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row {
    
    NSTableRowView *rowView = [[NSTableRowView alloc] init];
    
//    HMTableRowView *rowView = (HMTableRowView *)[tableView makeViewWithIdentifier:kAppListTableRowIdentifier owner:self];
//    if (rowView == nil) {
//        
//        rowView = [[HMTableRowView alloc] init];
//        rowView.identifier = kAppListTableRowIdentifier;
//    }
//    
    return rowView;
}


@end
