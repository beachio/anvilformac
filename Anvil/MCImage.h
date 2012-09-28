//
//  MCImage.h
//  BackToTheMac
//
//  Created by Drew McCormack on 30/08/10.
//  Copyright (c) 2010 The Mental Faculty. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSImage (MCStretchableImageExtensions)

-(NSImage *)stretchableImageWithLeftCapWidth:(CGFloat)leftCapWidth topCapHeight:(CGFloat)topCapHeight;

-(void)drawInRect:(NSRect)rect;

@end


@interface MCImage : NSImage {
    @private
    NSArray *cachedSliceImages;
    CGFloat leftCapWidth, topCapHeight;
}

@end
