//
//  NVSpinnerButton.m
//  Anvil
//
//  Created by Elliott Kember on 28/09/2012.
//  Copyright (c) 2012 Riot. All rights reserved.
//

#import "NVSpinnerButton.h"
#import "CustomLoadingSpinner.h"

@interface NVSpinnerButton ()

@property BOOL spinning;

@end

@implementation NVSpinnerButton

- (BOOL)isSpinning {
    
    return self.spinning;
}

- (void)showSpinnerFor:(double)time {
    
    self.spinning = YES;
    self.hidden = YES;
    CGFloat inset = 4;
    CGRect frame = CGRectMake(self.frame.origin.x + inset / 2, self.frame.origin.y + inset / 2, self.frame.size.width - inset, self.frame.size.width - inset);
    CustomLoadingSpinner *spinner = [[CustomLoadingSpinner alloc] initWithFrame:frame];
    [spinner setWantsLayer:YES];
    [self.superview addSubview:spinner];
    [spinner setSpinning:YES];
    [self performSelector:@selector(hideSpinner:) withObject:spinner afterDelay:time];
}

- (void)hideSpinner:(id)sender {

    self.spinning = NO;
    CustomLoadingSpinner *spinner = sender;
    [spinner setSpinning:NO];
    spinner.hidden = YES;
    spinner = nil;
    self.hidden = NO;
}

@end
