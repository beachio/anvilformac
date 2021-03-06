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
@property (strong, atomic) NSImage *faviconImage;

- (id)initWithURL:(NSURL *)url;
- (NSURL *)faviconURL;
- (void)createSymlink;
- (void)destroySymlink;

- (NSURL *)browserURL;
- (void)restart;
- (void)renameTo:(NSString *)newName;
- (BOOL)isARackApp;
- (void)createIndexFileIfNonExistentAndNotARackApp;

- (BOOL)needsAnIndexFile;

@end
