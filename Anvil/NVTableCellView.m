//
//  NVTableCellView.m
//  Anvil
//
//  Created by Elliott Kember on 16/09/2012.
//  Copyright (c) 2012 Riot. All rights reserved.
//

#import "NVTableCellView.h"
#import "BFImage.h"
#import "NSButton+NSButton_Extensions.h"

@implementation NVTableCellView

- (void)awakeFromNib {
    
    // Initialization code here.
    self.backgroundStyle = NSBackgroundStyleLowered;
    
    if (self.isHammer) {
        
        [self.localLabel setText:@".dev.hammer"];
    }
        
    self.deleteButton.stringValue = @"";
    self.restartButton.stringValue = @"";
    
    self.restartButton.image = [NSImage imageNamed:@"Restart"];
    self.deleteButton.image = [NSImage imageNamed:@"Delete"];
    self.deleteButton.hoverImage = [NSImage imageNamed:@"DeleteHover"];
    self.deleteButton.alternateImage = [NSImage imageNamed:@"DeletePushed"];
    
    // TODO: Hover button. OMG.
    self.restartButton.alternateImage = [NSImage imageNamed:@"RestartPushed"];
    self.restartButton.hoverImage = [NSImage imageNamed:@"RestartHover"];
    self.restartButton.alternateImage = [NSImage imageNamed:@"RestartPushed"];
    
    [self.restartButton setHidden:YES];
    [self.deleteButton setHidden:YES];
        
    [self.siteLabel setWidth];
    self.localLabel.frame = CGRectMake(self.siteLabel.frame.origin.x + self.siteLabel.frame.size.width -5,
                                       self.siteLabel.frame.origin.y,
                                       self.siteLabel.frame.size.width,
                                       self.siteLabel.frame.size.height);
    
    [self.localLabel sizeToFit];
    [self.siteLabel setEditable:YES];
  
    [self setupReallyDeleteButton];
}

- (void)setIsHammer:(BOOL)isHammer {
    
    _isHammer = isHammer;
    if (isHammer) {
        [self.localLabel setText:@".hammer.dev"];
    }
}

- (void)setupReallyDeleteButton {
    
    NSImage *reallyDeleteButtonImage = [BFImage imageFrom:[NSImage imageNamed:@"DeleteButton"] withDimensions:self.reallyDeleteButton.frame.size andInsets:BFEdgeInsetsMake(1.0, 10.0, 1.0, 10.0)];
    NSImage *reallyDeleteButtonAlternateImage = [BFImage imageFrom:[NSImage imageNamed:@"DeleteButtonPushed"] withDimensions:self.reallyDeleteButton.frame.size andInsets:BFEdgeInsetsMake(1.0, 10.0, 1.0, 10.0)];
    
    [self.reallyDeleteButton.cell setImageScaling:NSImageScaleAxesIndependently];
    
    self.reallyDeleteButton.image = reallyDeleteButtonImage;
    self.reallyDeleteButton.alternateImage = reallyDeleteButtonAlternateImage;

    [self.reallyDeleteButton setTitle:@"Delete"];
    [self.reallyDeleteButton setAlternateTitle:@"Delete"];
    
    self.reallyDeleteButton.textOffset = 1.0;
}

- (IBAction)didClickDeleteButton:(id)sender {
    
    NSInteger count = [[NSApp currentEvent] clickCount];
    
    // Double clicks. Pass the message through.
    if (count == 1) {
        [self showReallyDeleteButton];
    } else if (count == 2) {
        [self.reallyDeleteButton performClick:sender];
    }
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
    self.localLabel.frame = CGRectMake(self.siteLabel.frame.origin.x + self.siteLabel.frame.size.width - 5,
                                       self.siteLabel.frame.origin.y,
                                       self.siteLabel.frame.size.width,
                                       self.siteLabel.frame.size.height);
    
    [self.localLabel sizeToFit];
    [self.siteLabel setEditable:YES];
    
    CGRect dirtyRect = self.frame;
    
    NSRect deleteButtonFrame = self.deleteButton.frame;
    
    int spaceBetweenDeleteButtonAndRight = 12;
    int spaceBetweenButtons = 5;
    
    self.deleteButton.frame = CGRectMake(dirtyRect.size.width - spaceBetweenDeleteButtonAndRight - deleteButtonFrame.size.width,
                                         deleteButtonFrame.origin.y,
                                         deleteButtonFrame.size.width,
                                         deleteButtonFrame.size.height);
    
    NSRect restartButtonFrame = self.restartButton.frame;
    self.restartButton.frame = CGRectMake(self.deleteButton.frame.origin.x - spaceBetweenButtons - restartButtonFrame.size.width,
                                          restartButtonFrame.origin.y,
                                          restartButtonFrame.size.width,
                                          restartButtonFrame.size.height);
    
    NSRect reallyDeleteButtonFrame = self.reallyDeleteButton.frame;
    self.reallyDeleteButton.frame = CGRectMake(dirtyRect.size.width - spaceBetweenDeleteButtonAndRight - reallyDeleteButtonFrame.size.width,
                                         reallyDeleteButtonFrame.origin.y,
                                         reallyDeleteButtonFrame.size.width,
                                         reallyDeleteButtonFrame.size.height);

}

- (void)showControls {
    
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0.1];
    if (self.showRestartButton && ![self.restartButton isSpinning]) {
        [[self.restartButton animator] setHidden:NO];
    }
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
