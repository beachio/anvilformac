//
//  NVSwitchView.m
//  Anvil
//
//  Created by Elliott Kember on 18/09/2012.
//  Copyright (c) 2012 Riot. All rights reserved.
//

#import "NVSwitchView.h"

@interface NVSwitchView ()

@property (nonatomic, assign) BOOL on;

@end


@implementation NVSwitchView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        
    }
    
    return self;
}

- (void)awakeFromNib {
    
    [super awakeFromNib];
    
    NSImage *switcherImage = [NSImage imageNamed:@"Switch"];
    NSImage *backgroundImage = [NSImage imageNamed:@"SwitchInactive"];
    
    CGRect rect = CGRectMake(0, 0, switcherImage.size.width, switcherImage.size.height);
    
    NSInteger x = self.frame.origin.x;
    NSInteger y = self.frame.origin.y - floor((switcherImage.size.height - self.frame.size.height) / 2);
    NSInteger width = self.frame.size.width + floor(switcherImage.size.width / 2.0); // width of background = half of width of switcher
    NSInteger height = self.frame.size.height + floor(switcherImage.size.height / 2.0);
    CGRect fullFrame = CGRectMake(x, y, width, height);
    self.frame = fullFrame;
    
    NSInteger backgroundX = 0 + floor((self.frame.size.width - backgroundImage.size.width) / 2);
    NSInteger backgroundY = 0 + floor((self.frame.size.height - backgroundImage.size.height) / 2);
    NSInteger backgroundWidth = backgroundImage.size.width;
    NSInteger backgroundHeight = backgroundImage.size.height;
    CGRect backgroundViewRect = CGRectMake(backgroundX, backgroundY, backgroundWidth, backgroundHeight);
    
    self.backgroundView = [[NVStyledView alloc] initWithFrame:backgroundViewRect];
    self.backgroundView.backgroundImage = backgroundImage;
    
    [self addSubview:self.backgroundView];

    
    self.switcherView = [[NVStyledView alloc] initWithFrame:rect];
    self.switcherView.backgroundImage = switcherImage;
    [self addSubview:self.switcherView];
    
    [self turnOn];
}

- (void)turnOn {
    
    self.on = YES;
    self.backgroundView.backgroundImage = [NSImage imageNamed:@"SwitchActive"];
    [self switchTo:YES];
}

- (void)mouseMoved:(NSEvent *)theEvent {
    
//    return NO;
}

- (BOOL)mouseDownCanMoveWindow {
    return NO;
}

- (void)mouseDown:(NSEvent *)theEvent {
    [self toggle];
}

- (void)toggle {
    
    self.on ? [self turnOff] : [self turnOn];
}

- (void)turnOff {
    
    self.on = NO;
    self.backgroundView.backgroundImage = [NSImage imageNamed:@"SwitchInactive"];
    [self switchTo:NO];
}

- (void)switchTo:(BOOL)position {
    
    NSRect firstViewFrame = self.switcherView.frame;
    NSMutableDictionary *newAnimations = [NSMutableDictionary dictionary];
    [newAnimations setObject:self.switcherView forKey:NSViewAnimationTargetKey];
    [newAnimations setObject:[NSValue valueWithRect:firstViewFrame]
                      forKey:NSViewAnimationStartFrameKey];
    
    NSRect lastViewFrame = firstViewFrame;

    if (position) {
        lastViewFrame.origin.x = self.frame.size.width - lastViewFrame.size.width;
    } else {
        lastViewFrame.origin.x = 0;
    }
    
    [newAnimations setObject:[NSValue valueWithRect:lastViewFrame]
                      forKey:NSViewAnimationEndFrameKey];
    
    NSViewAnimation *theAnim = nil;
    // Create the view animation object.
    theAnim = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObjects:newAnimations, nil]];
    [theAnim setDuration:0.1];    // One and a half seconds.
    [theAnim startAnimation];
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    // Drawing code here.
}

@end
