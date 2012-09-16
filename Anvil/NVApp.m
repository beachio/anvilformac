//
//  NVApp.m
//  Anvil
//
//  Created by Elliott Kember on 16/09/2012.
//  Copyright (c) 2012 Riot. All rights reserved.
//

#import "NVApp.h"

@implementation NVApp

- (id)initWithURL:(NSURL *)url {
   
    self = [super  init];
    if(self) {
        self.url = url;
    }
    return self;
}

- (NSString *)directoryName {
    
    return [self.url lastPathComponent];
}


@end
