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

- (void)awakeFromNib {
    
    [super awakeFromNib];
    
    BOOL retinaScreen = [NSScreen mainScreen].backingScaleFactor == 2.0;
    
    NSImage *switcherImage = nil;
    NSImage *backgroundImage = nil;
    
    if (retinaScreen) {
        
        switcherImage = [NSImage imageNamed:@"SwitchFlat@2x.png"];
        backgroundImage = [NSImage imageNamed:@"SwitchInactiveFlat@2x.png"];
    } else {
        
        switcherImage = [NSImage imageNamed:@"SwitchFlat.png"];
        backgroundImage = [NSImage imageNamed:@"SwitchInactiveFlat.png"];
    }
    
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

    rect.origin.y += 1;
    self.switcherView = [[NVStyledView alloc] initWithFrame:rect];
    self.switcherView.backgroundImage = switcherImage;
    [self addSubview:self.switcherView];
}

# pragma mark - Switching

- (void)turnOn {
    
    [self switchTo:YES withAnimation:YES];
}

- (void)toggle {
    
    self.on ? [self turnOff] : [self turnOn];
}

- (void)turnOff {
    
    [self switchTo:NO withAnimation:YES];
}

- (void)switchToWithoutCallbacks:(BOOL)position withAnimation:(BOOL)useAnimation {
    
//    NSLog(@"Switch to %@ %@ animation", position ? @"on" : @"off", useAnimation ? @"with" : @"without");
    
    self.on = position;
    
    NSRect firstViewFrame = self.switcherView.frame;
    NSMutableDictionary *newAnimations = [NSMutableDictionary dictionary];
    [newAnimations setObject:self.switcherView forKey:NSViewAnimationTargetKey];
    [newAnimations setObject:[NSValue valueWithRect:firstViewFrame] forKey:NSViewAnimationStartFrameKey];
    
    NSRect lastViewFrame = firstViewFrame;
    
    BOOL retinaScreen = [NSScreen mainScreen].backingScaleFactor == 2.0;
    
    if (position) {
        
        lastViewFrame.origin.x = self.frame.size.width - lastViewFrame.size.width;
        
        if (retinaScreen) {
            self.backgroundView.backgroundImage = [NSImage imageNamed:@"SwitchActiveFlat@2x.png"];
        } else {
            self.backgroundView.backgroundImage = [NSImage imageNamed:@"SwitchActiveFlat.png"];
        }
    } else {
        
        lastViewFrame.origin.x = 0;
        if (retinaScreen) {
            self.backgroundView.backgroundImage = [NSImage imageNamed:@"SwitchInactiveFlat@2x.png"];
        } else {
            self.backgroundView.backgroundImage = [NSImage imageNamed:@"SwitchInactiveFlat.png"];
        }
    }
    
    [newAnimations setObject:[NSValue valueWithRect:lastViewFrame] forKey:NSViewAnimationEndFrameKey];
    
    if (useAnimation) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // do work here
            NSViewAnimation *theAnim = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObjects:newAnimations, nil]];
            [theAnim setDuration:0.1];
            [theAnim startAnimation];
        });
        
    } else {
        
        self.switcherView.frame = lastViewFrame;
    }

}

- (void)switchTo:(BOOL)position withAnimation:(BOOL)useAnimation {
    
    self.on = position;
    
    BOOL shouldChange = YES;
    if (self.delegate && [self.delegate respondsToSelector:@selector(switchView:shouldSwitchTo:)]) {
        shouldChange = [self.delegate switchView:self shouldSwitchTo:position];
    }
    
    if (!shouldChange) {
        return;
    }
    
    [self switchToWithoutCallbacks:position withAnimation:useAnimation];
}

#pragma mark - Mouse

- (BOOL)mouseDownCanMoveWindow {
    
    return NO;
}

- (void)mouseDown:(NSEvent *)theEvent {
    
    [self toggle];
}

@end
