//
//  HMLabel.m
//  HMnction
//
//  Created by Joe Ricioppo on 3/9/12.
//  Copyright (c) 2012 Riot. All rights reserved.
//

#import "NVLabel.h"

@implementation NVLabel

- (id)initWithFrame:(NSRect)frameRect {
    
    self = [super initWithFrame:frameRect];
    if (self == nil) {
        return nil;
    }
    
    [self setup];
    
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    
    self = [super initWithCoder:decoder];
    if (self == nil) {
        return nil;
    }
    
    [self setup];
    
    return self;
}


#pragma mark API

- (void)setup {

    [self setBackgroundColor:[NSColor clearColor]];
    [self setEditable:NO];
    [self setBordered:NO];
    [self setBezeled:NO];
    
}

- (void)setWidth {
    
    textField = self;
    NSRect frame = textField.frame;
    NSSize size = [self attributedStringValue].size;
    NSInteger width = (int)size.width + 6;

    [self setFrame:CGRectMake(frame.origin.x, frame.origin.y, width, frame.size.height)];
    [self setNeedsDisplay:YES];
}


- (void)setText:(NSString *)newText {
    
    NSDictionary *existingAttributes = nil;
    if ([self attributedStringValue].length > 0) {
        existingAttributes = [[self attributedStringValue] fontAttributesInRange:NSMakeRange(0, [[self attributedStringValue] length])];
    }
    
    if (newText != nil) {
        [self setStringValue:[newText copy]];
    }
    
    if (existingAttributes != nil) {
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithAttributedString:[self attributedStringValue]];
        [attributedString setAttributes:existingAttributes range:NSMakeRange(0, [[self attributedStringValue] length])];
        [self setAttributedStringValue:attributedString];
    }
    [self setWidth];
}

- (NSString *)text {
    
    return [self stringValue];
}

- (NSColor *)textColor {
	
	NSAttributedString *attributedString = [self attributedStringValue];
	NSRange range = NSMakeRange(0, MIN([attributedString length], 1UL));
    NSDictionary *attributes = [attributedString fontAttributesInRange:range];
	if (attributes == nil) {
        return nil;
    }
    
    return [attributes objectForKey:NSForegroundColorAttributeName];
}

- (void)setAlignment:(NSTextAlignment)mode {
    
	NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithAttributedString:[self attributedStringValue]];
	NSUInteger length = [attributedTitle length];
	NSRange range = NSMakeRange(0, length);
    
    NSMutableParagraphStyle *paragStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [paragStyle setAlignment:mode];
    [attributedTitle addAttribute:NSParagraphStyleAttributeName value:paragStyle range:range];
    
	[attributedTitle fixAttributesInRange:range];
	[self setAttributedStringValue:attributedTitle];
}

- (void)setTextColor:(NSColor *)newTextColor {
	
	NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithAttributedString:[self attributedStringValue]];
	NSUInteger length = [attributedTitle length];
	NSRange range = NSMakeRange(0, length);
	[attributedTitle addAttribute:NSForegroundColorAttributeName value:newTextColor range:range];
    
	[attributedTitle fixAttributesInRange:range];
	[self setAttributedStringValue:attributedTitle];
}

- (NSShadow *)textShadow {
	
    NSAttributedString *attributeString = [self attributedStringValue];
    NSRange range = NSMakeRange(0, MIN([attributeString length], 1UL));
    NSDictionary *attributes = [attributeString fontAttributesInRange:range];
    if (attributes == nil) {
        return nil;
    }
    
    return [attributes objectForKey:NSShadowAttributeName];
}

- (void)setTextShadow:(NSShadow *)newShadow {
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithAttributedString:[self attributedStringValue]];
    NSRange range = NSMakeRange(0, [attributedString length]);
    [attributedString addAttribute:NSShadowAttributeName value:newShadow range:range];
    [attributedString fixAttributesInRange:range];
    
    [self setAttributedStringValue:attributedString];
}

- (void)setBold:(BOOL)bold {
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithAttributedString:[self attributedStringValue]];
    NSRange range = NSMakeRange(0, [attributedString length]);
    NSFontManager *fontManager = [NSFontManager sharedFontManager];
    
    NSFont *font = nil;
    
    if (bold) {
        font = [fontManager convertFont:self.font toHaveTrait:NSBoldFontMask];
    } else {
        font = [fontManager convertFont:self.font toNotHaveTrait:NSBoldFontMask];
    }
    
    [attributedString addAttribute:NSFontAttributeName value:font range:range];
    [attributedString fixAttributesInRange:range];
    [self setAttributedStringValue:attributedString];
}

- (void)setAttributedStringValue:(NSAttributedString *)obj {
    
    [super setAttributedStringValue:obj];
    [self setWidth];
}

@end
