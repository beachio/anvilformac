//
//  NVStyledButton.h
//  Anvil
//
//  Created by Elliott Kember on 27/09/2012.
//  Copyright (c) 2012 Riot. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NVStyledButton : NSButton

@property (atomic) double textSize;
@property (atomic) double textOffset;
@property (atomic) BOOL isBold;
@property (nonatomic, retain) NSImage *image;
@property (nonatomic, retain) NSImage *hoverImage;

- (void)setInsetsWithTop:(CGFloat)top right:(CGFloat)right bottom:(CGFloat)bottom left:(CGFloat)left;

@end
