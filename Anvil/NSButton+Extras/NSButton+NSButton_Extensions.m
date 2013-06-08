//
//  NSButton+NSButton_Extensions.m
//  Hammer
//
//  Created by Elliott Kember on 09/01/2013.
//
//

#import "NSButton+NSButton_Extensions.h"

@implementation NSButton (NSButton_Extensions)
//
//- (NSColor *)textColor {
//    
//    NSAttributedString *attrTitle = [self attributedTitle];
//    int len = (int)[attrTitle length];
//    NSRange range = NSMakeRange(0, MIN(len, 1)); // take color from first char
//    NSDictionary *attrs = [attrTitle fontAttributesInRange:range];
//    NSColor *textColor = [NSColor controlTextColor];
//    if (attrs) {
//        textColor = [attrs objectForKey:NSForegroundColorAttributeName];
//    }
//    return textColor;
//}
//
- (void)setTextColor:(NSColor *)textColor {
    
    [self setTitleAttributeIncludingAlternate:NSForegroundColorAttributeName toValue:textColor];
}

- (void)setTextShadow:(NSShadow *)textShadow {
    
    [self setTitleAttributeName:NSShadowAttributeName toValue:textShadow];
}

- (void)setAlternateTextShadow:(NSShadow *)textShadow {
    
    [self setAlternateTitleAttributeName:NSShadowAttributeName toValue:textShadow];
}

- (void)setAlternateTextColor:(NSColor *)textColor {

    [self setAlternateTitleAttributeName:NSForegroundColorAttributeName toValue:textColor];
}

- (void)setLineHeight:(float)lineHeight {
    
    NSNumber *lineHeightNumber = [[NSNumber alloc] initWithFloat:lineHeight];
    [self setTitleAttributeIncludingAlternate:NSBaselineOffsetAttributeName toValue:lineHeightNumber];
}

- (void)setTitleAttributeIncludingAlternate:(NSString *)attributeName toValue:(id)value {
    
    [self setTitleAttributeName:attributeName toValue:value];
    [self setAlternateTitleAttributeName:attributeName toValue:value];
}

- (void)setTitleAttributeName:(NSString *)attributeName toValue:(id)value {
    
    NSMutableAttributedString *attrTitle = [[NSMutableAttributedString alloc]
                                            initWithAttributedString:[self attributedTitle]];
    int len = (int)[attrTitle length];
    NSRange range = NSMakeRange(0, len);
    [attrTitle addAttribute:attributeName
                      value:value
                      range:range];
    [attrTitle fixAttributesInRange:range];
    [self setAttributedTitle:attrTitle];
}

- (void)setAlternateTitleAttributeName:(NSString *)attributeName toValue:(id)value {
    
    NSMutableAttributedString *attrTitle = [[NSMutableAttributedString alloc]
                                            initWithAttributedString:[self attributedAlternateTitle]];
    int len = (int)[attrTitle length];
    NSRange range = NSMakeRange(0, len);
    [attrTitle addAttribute:attributeName
                      value:value
                      range:range];
    [attrTitle fixAttributesInRange:range];
    [self setAttributedAlternateTitle:attrTitle];
}

@end
