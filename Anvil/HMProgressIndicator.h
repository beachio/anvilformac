//
//  HMProgressIndicator.h
//  Hammer
//
//  Created by Red Davis on 03/07/2012.
//  Copyright (c) 2012 Riot. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "HMStyledView.h"


@interface HMProgressIndicator : HMStyledView

@property (strong, nonatomic) NSColor *outerColour;
@property (strong, nonatomic) NSColor *innerColour;
@property (readwrite, nonatomic) CGFloat progress;

@end
