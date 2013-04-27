//
//  NVSpinnerButton.h
//  Anvil
//
//  Created by Elliott Kember on 28/09/2012.
//  Copyright (c) 2012 Riot. All rights reserved.
//

#import "NVStyledButton.h"

@interface NVSpinnerButton : NVStyledButton

- (BOOL)isSpinning;
- (void)showSpinnerFor:(double)time;

@end
