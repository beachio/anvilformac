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
        
    [self.deleteButton setStringValue:@""];
    
    [self.restartButton setImage:[NSImage imageNamed:@"Restart"]];
    [self.restartButton setAlternateImage:[NSImage imageNamed:@"RestartAlt"]];
    [self.restartButton setStringValue:@""];
    
    [self.restartButton setHidden:YES];
    [self.deleteButton setHidden:YES];
    
    [self.siteLabel setWidth];
    self.localLabel.frame = CGRectMake(self.siteLabel.frame.origin.x + self.siteLabel.frame.size.width - 2,
                                       self.siteLabel.frame.origin.y,
                                       self.siteLabel.frame.size.width,
                                       self.siteLabel.frame.size.height);
    
    [self.localLabel sizeToFit];
    [self.siteLabel setEditable:YES];
    
    NSImage *reallyDeleteButtonImage = [[NSImage imageNamed:@"DeleteButton"] stretchableImageWithEdgeInsets:BFEdgeInsetsMake(1.0, 5.0, 1.0, 5.0)];

    [self.reallyDeleteButton.cell setImageScaling:NSImageScaleAxesIndependently];
    
    [self.reallyDeleteButton setImage:reallyDeleteButtonImage];
    
    NSImage *deleteButtonAlternateImage = [[NSImage imageNamed:@"DeleteButtonPushed"] stretchableImageWithEdgeInsets:BFEdgeInsetsMake(1.0, 5.0,1.0, 5.0)];
    [self.reallyDeleteButton setAlternateImage:deleteButtonAlternateImage];

}

- (IBAction)didClickDeleteButton:(id)sender {
    
    [self showReallyDeleteButton];
}

- (void)showReallyDeleteButton {
        
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0.1];
    [[self.reallyDeleteButton animator] setHidden:NO];
    [NSAnimationContext endGrouping];
}

- (void)hideReallyDeleteButton {
    
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0.05];
    [self.reallyDeleteButton setHidden:YES];
    [NSAnimationContext endGrouping];
}

- (void)resizeSubviewsWithOldSize:(NSSize)oldSize {
    
    [self hideReallyDeleteButton];
    
    [self.siteLabel setWidth];
    self.localLabel.frame = CGRectMake(self.siteLabel.frame.origin.x + self.siteLabel.frame.size.width - 2,
                                       self.siteLabel.frame.origin.y,
                                       self.siteLabel.frame.size.width,
                                       self.siteLabel.frame.size.height);
    
    [self.localLabel sizeToFit];
    [self.siteLabel setEditable:YES];
    
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
    
    NSRect reallyDeleteButtonFrame = self.reallyDeleteButton.frame;
    self.reallyDeleteButton.frame = CGRectMake(dirtyRect.size.width - 5 - reallyDeleteButtonFrame.size.width,
                                         reallyDeleteButtonFrame.origin.y,
                                         reallyDeleteButtonFrame.size.width,
                                         reallyDeleteButtonFrame.size.height);

}

- (void)showControls {
    
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0.1];
    [[self.restartButton animator] setHidden:NO];
    [[self.deleteButton animator] setHidden:NO];
    [NSAnimationContext endGrouping];
}

- (void)hideControls {
    
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0.05];
    [[self.reallyDeleteButton animator] setHidden:YES];
    [[self.restartButton animator] setHidden:YES];
    [[self.deleteButton animator] setHidden:YES];
    [NSAnimationContext endGrouping];
}

@end
