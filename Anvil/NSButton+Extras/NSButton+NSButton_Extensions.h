//
//  NSButton+NSButton_Extensions.h
//  Hammer
//
//  Created by Elliott Kember on 09/01/2013.
//
//

#import <Cocoa/Cocoa.h>

@interface NSButton (NSButton_Extensions)

//- (NSColor *)textColor;
- (void)setTextColor:(NSColor *)textColor;
- (void)setTextShadow:(NSShadow *)textShadow;
- (void)setAlternateTextColor:(NSColor *)textColor;
- (void)setLineHeight:(float)lineHeight;

- (void)setTitleAttributeIncludingAlternate:(NSString *)attributeName toValue:(id)value;

- (void)setAlternateTextShadow:(NSShadow *)textShadow;

@end
