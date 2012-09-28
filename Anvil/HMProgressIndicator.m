//
//  HMProgressIndicator.m
//  Hammer
//
//  Created by Red Davis on 03/07/2012.
//  Copyright (c) 2012 Riot. All rights reserved.
//

#import "HMProgressIndicator.h"
#import <QuartzCore/QuartzCore.h>
#import "MCImage.h"
#import "HMUserPreferences.h"


@interface HMProgressIndicator ()

@property (strong, nonatomic) NSColor *emptyColour;
@property (readonly, nonatomic) NSImage *progressImage;

@end


@implementation HMProgressIndicator

@synthesize progress = _progress;

#pragma mark - Initialization

- (id)initWithFrame:(NSRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        
        [self setWantsLayer:YES];
        
        self.backgroundColor = [NSColor clearColor];
        self.outerColour = [NSColor whiteColor];
        self.innerColour = [NSColor whiteColor];
        self.emptyColour = [NSColor clearColor];
        
        self.progress = 0;
    }
    
    return self;
}

#pragma mark -

- (void)setProgress:(CGFloat)progress {
    
    _progress = progress;    
    if (_progress > 1) {
        
        _progress = 1;
    } else if (_progress < 0) {
        
        _progress = 0;
    }
    
    [self setNeedsDisplay:YES];
}

- (CGFloat)progress {
    
    return _progress;
}

#pragma mark - Helpers

- (NSImage *)progressImage {
    
    NSImage *image = [NSImage imageNamed:@"ProgressBar"];
    if ([HMUserPreferences sharedUserPreferences].usingGraphiteColorScheme) {
        image = [NSImage imageNamed:@"ProgressBarGraphite"];
    }
    
    return image;
}

#pragma mark -

- (void)drawRect:(NSRect)dirtyRect {
    
    [super drawRect:dirtyRect];
                
    NSImage *trackImage = [[NSImage imageNamed:@"ProgressTrack"] stretchableImageWithLeftCapWidth:5.0 topCapHeight:4.0];
    [trackImage drawInRect:dirtyRect];
    
    NSImage *stretchedProgressImage = [self.progressImage stretchableImageWithLeftCapWidth:4.0 topCapHeight:3.0];
    
    NSRect progressRect = CGRectInset(dirtyRect, 1.0, 0.0);
    progressRect.size.height -= 1;
    progressRect.size.width *= self.progress;
    if (progressRect.size.width < stretchedProgressImage.size.width) {
        
        progressRect.size.width = stretchedProgressImage.size.width;
    }
    
    [stretchedProgressImage drawInRect:progressRect];
}

@end
