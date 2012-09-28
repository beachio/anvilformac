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
@property (atomic) BOOL isBold;

- (void)setInsetsWithTop:(CGFloat)top right:(CGFloat)right bottom:(CGFloat)bottom left:(CGFloat)left;

@end
