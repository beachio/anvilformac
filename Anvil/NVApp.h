//
//  NVApp.h
//  Anvil
//
//  Created by Elliott Kember on 16/09/2012.
//  Copyright (c) 2012 Riot. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NVApp : NSObject

@property (copy, nonatomic) NSString *name;
@property (strong, nonatomic) NSURL *url;

- (id)initWithURL:(NSURL *)url;

@end
