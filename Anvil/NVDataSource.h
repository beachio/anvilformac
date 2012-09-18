//
//  NVDataSource.h
//  Anvil
//
//  Created by Elliott Kember on 31/07/2012.
//  Copyright (c) 2012 Riot. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NVApp.h"

@interface NVDataSource : NSObject

@property (strong, readonly, nonatomic) NSArray *apps;

- (void)readInSavedAppDataFromDisk;
+ (NVDataSource *)sharedDataSource;
- (void)addAppWithURL:(NSURL *)url;
- (void)removeApp:(NVApp *)appToRemove;

@end
