//
//  MCImage.m
//  BackToTheMac
//
//  Created by Drew McCormack on 30/08/10.
//  Copyright (c) 2010 The Mental Faculty. All rights reserved.
//

#import "MCImage.h"


@interface MCImage ()

@property CGFloat leftCapWidth, topCapHeight;

-(NSArray *)imageSlices;

@end


@implementation NSImage (MCStretchableImageExtensions)

-(NSImage *)stretchableImageWithLeftCapWidth:(CGFloat)leftCapWidth topCapHeight:(CGFloat)topCapHeight
{
    MCImage *newImage = [[MCImage alloc] initWithData:[self TIFFRepresentation]];
    newImage.topCapHeight = topCapHeight;
    newImage.leftCapWidth = leftCapWidth;
    return newImage;
}

-(void)drawInRect:(NSRect)rect 
{
	NSRect fromRect = NSZeroRect;
    fromRect.size = self.size;
    [self drawInRect:rect fromRect:fromRect operation:NSCompositeCopy fraction:1.0f];
}

@end


@implementation MCImage

@synthesize leftCapWidth, topCapHeight;

-(NSImage *)sliceFromRect:(NSRect)rect 
{
    NSImage *newImage = [[NSImage alloc] initWithSize:rect.size];
    if ( newImage.isValid && rect.size.width > 0.0f && rect.size.height > 0.0f ) {
        NSRect toRect = rect;
        toRect.origin = NSZeroPoint;
        [newImage lockFocus];
        [self drawInRect:toRect fromRect:rect operation:NSCompositeCopy fraction:1.0f];
        [newImage unlockFocus];        
    }
    return newImage;
}

-(NSArray *)imageSlices {
    if ( cachedSliceImages ) return cachedSliceImages;
    [self performSelectorOnMainThread:@selector(createImageSlices) withObject:nil waitUntilDone:YES];
    return cachedSliceImages;
}
    
-(void)createImageSlices {
    CGFloat rightCapWidth = MAX(1.0f, self.size.width - leftCapWidth - 1.0f);
    CGFloat bottomCapHeight = MAX(1.0f, self.size.height - topCapHeight - 1.0f);
    
    NSImage *topLeft = [self sliceFromRect:NSMakeRect(0.0f, bottomCapHeight+1.0f, leftCapWidth, topCapHeight)];
    NSImage *topEdge = [self sliceFromRect:NSMakeRect(leftCapWidth, bottomCapHeight+1.0f, 1.0f, topCapHeight)];
    NSImage *topRight = [self sliceFromRect:NSMakeRect(leftCapWidth+1.0f, bottomCapHeight+1.0f, rightCapWidth, topCapHeight)];
    NSImage *leftEdge = [self sliceFromRect:NSMakeRect(0.0f, bottomCapHeight, leftCapWidth, 1.0f)];
    NSImage *center = [self sliceFromRect:NSMakeRect(leftCapWidth, bottomCapHeight, 1.0f, 1.0f)];
    NSImage *rightEdge = [self sliceFromRect:NSMakeRect(leftCapWidth+1.0f, bottomCapHeight, rightCapWidth, 1.0f)];
    NSImage *bottomLeft = [self sliceFromRect:NSMakeRect(0.0f, 0.0f, leftCapWidth, bottomCapHeight)];
    NSImage *bottomEdge = [self sliceFromRect:NSMakeRect(leftCapWidth, 0.0f, 1.0f, bottomCapHeight)];
    NSImage *bottomRight = [self sliceFromRect:NSMakeRect(leftCapWidth+1.0f, 0.0f, rightCapWidth, bottomCapHeight)];
    	
	NSArray *slices = [NSArray arrayWithObjects:topLeft, topEdge, topRight, leftEdge, center, rightEdge, bottomLeft, bottomEdge, bottomRight, nil];
	
	cachedSliceImages = slices;
}

-(void)drawInRect:(NSRect)rect 
{
    NSArray *slices = [self imageSlices];
    #define S(i) [slices objectAtIndex:i]
    NSDrawNinePartImage(rect, S(0), S(1), S(2), S(3), S(4), S(5), S(6), S(7), S(8),
                        NSCompositeCopy, 1.0f, NO);
}

@end
