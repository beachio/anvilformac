//
//  WhiteIntermProgIndicator.m
//  WhiteIntermProgIndicator
//
//  Created by Dallas Brown on 12/23/08.
//  http://www.CodeGenocide.com
//  Copyright 2008 Code Genocide. All rights reserved.
//
//  Based off of AMIndeterminateProgressIndicatorCell created by Andreas, version date 2007-04-03.
//  http://www.harmless.de
//  Copyright 2007 Andreas Mayer. All rights reserved.
//

#import "CustomLoadingSpinner.h"

#define ConvertAngle(a) (fmod((90.0-(a)), 360.0))

#define DEG2RAD  0.017453292519943295

@implementation CustomLoadingSpinner

@synthesize parentControl;

- (id)initWithFrame:(NSRect)frameRect {
    
    if(self == [super initWithFrame:frameRect]) {
        [self setAnimationDelay:3.0/60.0];
        [self setDisplayedWhenStopped:YES];
        [self setDoubleValue:0.0];
    }
    return self;
}

- (id)init {
    
    if(self = [super init]) {
        [self setAnimationDelay:3.0/60.0];
        [self setDisplayedWhenStopped:YES];
        [self setDoubleValue:0.0];
    }
    return self;
}

- (void)awakeFromNib {
    
    [self setAnimationDelay:3.0/60.0];
    [self setDisplayedWhenStopped:YES];
    [self setDoubleValue:0.0];
}

- (double)doubleValue {
    
	return doubleValue;
}

- (void)setDoubleValue:(double)value {
    
	if (doubleValue != value) {
		doubleValue = value;
		if (doubleValue > 1.0) {
			doubleValue = 1.0;
		} else if (doubleValue < 0.0) {
			doubleValue = 0.0;
		}
	}
}

- (NSTimeInterval)animationDelay {
    
	return animationDelay;
}

- (void)setAnimationDelay:(NSTimeInterval)value {
    
	if (animationDelay != value) {
		animationDelay = value;
	}
}

- (BOOL)isDisplayedWhenStopped {
    
	return displayedWhenStopped;
}

- (void)setDisplayedWhenStopped:(BOOL)value {
    
	if (displayedWhenStopped != value) {
		displayedWhenStopped = value;
	}
}

- (BOOL)isSpinning {
    
	return spinning;
}

- (void)setSpinning:(BOOL)value {
    
	if (spinning != value) {
		spinning = value;

		if (value)
		{
			if (theTimer == nil)
			{
				theTimer = [NSTimer scheduledTimerWithTimeInterval:animationDelay target:self selector:@selector(animate:) userInfo:NULL repeats:YES];
			}
			else
			{
				[theTimer fire];
			}
		}
		else
		{
			[theTimer invalidate];
		}
	}
}

- (void)animate:(NSTimer *)aTimer {
    
	double value = fmod(([self doubleValue] + (5.0/60.0)), 1.0);

	[self setDoubleValue:value];
    [self setNeedsDisplay:YES];
}


- (void)drawRect:(NSRect)dirtyRect {
    
    float flipFactor = 1.0; // ([controlView isFlipped] ? 1.0 : -1.0);
    int step = round([self doubleValue]/(5.0/60.0));
    float cellSize = MIN(dirtyRect.size.width, dirtyRect.size.height);
    NSPoint center = dirtyRect.origin;
    center.x += cellSize/2.0;
    center.y += dirtyRect.size.height/2.0;
    float outerRadius;
    float innerRadius;
    float strokeWidth = cellSize*0.08;
    if (cellSize >= 32.0) {
        outerRadius = cellSize*0.38;
        innerRadius = cellSize*0.23;
    } else {
        outerRadius = cellSize*0.48;
        innerRadius = cellSize*0.27;
    }
    float a; // angle
    NSPoint inner;
    NSPoint outer;
    [NSBezierPath setDefaultLineCapStyle:NSRoundLineCapStyle];
    [NSBezierPath setDefaultLineWidth:strokeWidth];
    if ([self isSpinning]) {
        a = (270-(step* 30))*DEG2RAD;
    } else {
        a = 270*DEG2RAD;
    }
    a = flipFactor*a;
    int i;
    
    for (i = 0; i < 12; i++) {
        if(self.selected){
            if (i == 0){
                [[NSColor colorWithCalibratedWhite:1.0 alpha:1.0] set];
            }else{
                [[NSColor colorWithCalibratedWhite:1.0 alpha:1.0-(i * 0.1)] set];
            }
        }else{
            if (i == 0){
                [[NSColor colorWithCalibratedWhite:0.4 alpha:0.8] set];
            }else{
                [[NSColor colorWithCalibratedWhite:0.4 alpha:0.8-(i * 0.1)] set];
            }
        }
        outer = NSMakePoint(center.x+cos(a)*outerRadius, center.y+sin(a)*outerRadius);
        inner = NSMakePoint(center.x+cos(a)*innerRadius, center.y+sin(a)*innerRadius);
        [NSBezierPath strokeLineFromPoint:inner toPoint:outer];
        
        a += flipFactor*30*DEG2RAD;
    }

}

- (void)setObjectValue:(id)value {
    
	if ([value respondsToSelector:@selector(boolValue)]) {
		[self setSpinning:[value boolValue]];
	} else {
		[self setSpinning:NO];
	}
}

@end
