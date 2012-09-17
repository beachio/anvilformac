//
//  HMLabel.h
//  HMnction
//
//  Created by Joe Ricioppo on 3/9/12.
//  Copyright (c) 2012 Riot. All rights reserved.
//

#import <Cocoa/Cocoa.h>

//@interface HMLabel : NSTextField

@interface NVLabel : NSTextField {
    IBOutlet NSTextField* textField;
}
- (void)setup;
- (void)setWidth;
- (void)setBold:(BOOL)bold;


@property (strong, nonatomic) NSString *text;
@property (strong, nonatomic) NSColor *textColor;
@property (strong, nonatomic) NSShadow *textShadow;

@end
