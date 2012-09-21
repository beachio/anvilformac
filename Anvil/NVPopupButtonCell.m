//
//  NVPopupButtonCell.m
//  Anvil
//
//  Created by Elliott Kember on 21/09/2012.
//  Copyright (c) 2012 Riot. All rights reserved.
//

#import "NVPopupButtonCell.h"

@implementation NVPopupButtonCell

- (void)drawImageWithFrame:(NSRect)cellRect inView:(NSView *)controlView{
    NSImage *image = self.image;
    if([self isHighlighted] && self.alternateImage){
        image = self.alternateImage;
    }
    
    //TODO: respect -(NSCellImagePosition)imagePosition
    NSRect imageRect = NSZeroRect;
    imageRect.origin.y = (CGFloat)round(cellRect.size.height*0.5f-image.size.height*0.5f);
    imageRect.origin.x = (CGFloat)round(cellRect.size.width*0.5f-image.size.width*0.5f);
    imageRect.size = image.size;
    
    [image drawInRect:imageRect
             fromRect:NSZeroRect
            operation:NSCompositeSourceOver
             fraction:1.0f
       respectFlipped:YES
                hints:nil];
}

@end
