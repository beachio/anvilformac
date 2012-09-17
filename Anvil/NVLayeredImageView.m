//
//  NVLayeredImageView.m
//  Anvil
//
//  Created by Elliott Kember on 31/07/2012.
//  Copyright (c) 2012 Riot. All rights reserved.
//

#import "NVLayeredImageView.h"

@implementation NVLayeredImageView

- (void)awakeFromNib {
    
    [super awakeFromNib];
    
    self.foregroundImageSize = NSMakeSize(16, 16);
}

#pragma mark - Drawing

- (void)drawRect:(NSRect)dirtyRect {
    
    NSRect rect = [self bounds];
    
    if (self.backgroundImage) {
        
        [self.backgroundImage drawInRect:rect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    }
    
    if (self.foregroundImage) {
        
        NSSize imageSize = self.foregroundImageSize;
        CGFloat originX = ceilf((rect.size.width - imageSize.width) / 2.0);
        CGFloat originY = ceilf((rect.size.height - imageSize.height) / 2.0);
        
        NSRect imageRect = NSIntegralRect(NSMakeRect(originX, originY, imageSize.width, imageSize.height));
        [self.foregroundImage drawInRect:imageRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    }
}

@end
