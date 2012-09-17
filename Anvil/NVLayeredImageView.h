//
//  NVLayeredImageView.h
//  Anvil
//
//  Created by Elliott Kember on 31/07/2012.
//  Copyright (c) 2012 Riot. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NVLayeredImageView : NSView

@property (strong, nonatomic) NSImage *backgroundImage;
@property (strong, nonatomic) NSImage *foregroundImage;
@property (assign, nonatomic) NSSize foregroundImageSize;

@end
