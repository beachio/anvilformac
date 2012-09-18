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
@property (strong, nonatomic) NSURL *sourceURL;

- (id)initWithURL:(NSURL *)url;
- (NSURL *)faviconURL;
- (void)createSymlink;
- (void)destroySymlink;
- (NSURL *)realURL;
- (NSURL *)browserURL;
- (void)restart;
- (void)renameTo:(NSString *)newName;

@end
