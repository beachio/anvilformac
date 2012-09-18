//
//  NVTableCellView.m
//  Anvil
//
//  Created by Elliott Kember on 16/09/2012.
//  Copyright (c) 2012 Riot. All rights reserved.
//

#import "NVTableCellView.h"

@implementation NVTableCellView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    
    [self.textField setWidth];
    self.localLabel.frame = CGRectMake(self.textField.frame.origin.x + self.textField.frame.size.width - 2,
                                       self.textField.frame.origin.y,
                                       self.textField.frame.size.width,
                                       self.textField.frame.size.height);
    [self.localLabel sizeToFit];
    [self.textField setEditable:YES];
}

@end
