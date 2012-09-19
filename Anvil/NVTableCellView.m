//
//  NVTableCellView.m
//  Anvil
//
//  Created by Elliott Kember on 16/09/2012.
//  Copyright (c) 2012 Riot. All rights reserved.
//

#import "NVTableCellView.h"
#import "BFImage.h"

@implementation NVTableCellView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.

    }
    
    return self;
}

- (void)awakeFromNib {
    
    // Initialization code here.
    self.backgroundStyle = NSBackgroundStyleLowered;
    
    [self.deleteButton setImage:[NSImage imageNamed:@"Delete"]];
    [self.deleteButton setStringValue:@""];
    [self hideControls];
    
    [self.textField setWidth];
    self.localLabel.frame = CGRectMake(self.textField.frame.origin.x + self.textField.frame.size.width - 2,
                                       self.textField.frame.origin.y,
                                       self.textField.frame.size.width,
                                       self.textField.frame.size.height);
    
    [self.localLabel sizeToFit];
    [self.textField setEditable:YES];
}

- (void)resizeSubviewsWithOldSize:(NSSize)oldSize {
    
    [self.textField setWidth];
    self.localLabel.frame = CGRectMake(self.textField.frame.origin.x + self.textField.frame.size.width - 2,
                                       self.textField.frame.origin.y,
                                       self.textField.frame.size.width,
                                       self.textField.frame.size.height);
    
    [self.localLabel sizeToFit];
    [self.textField setEditable:YES];
    
    CGRect dirtyRect = self.frame;
    
    NSRect deleteButtonFrame = self.deleteButton.frame;
    self.deleteButton.frame = CGRectMake(dirtyRect.size.width - 10 - deleteButtonFrame.size.width,
                                         deleteButtonFrame.origin.y,
                                         deleteButtonFrame.size.width,
                                         deleteButtonFrame.size.height);
    
    NSRect restartButtonFrame = self.restartButton.frame;
    self.restartButton.frame = CGRectMake(self.deleteButton.frame.origin.x - 10 - restartButtonFrame.size.width,
                                          restartButtonFrame.origin.y,
                                          restartButtonFrame.size.width,
                                          restartButtonFrame.size.height);

}

- (void)showControls {
    
    self.restartButton.hidden = NO;
    self.deleteButton.hidden = NO;
}

- (void)hideControls {
    
    self.restartButton.hidden = YES;
    self.deleteButton.hidden = YES;
}

@end
