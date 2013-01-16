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
//- (NVApp *)addAppWithURL:(NSURL *)url andName:(NSString *)name;
- (NVApp *)addAppWithURL:(NSURL *)url;
- (void)removeApp:(NVApp *)appToRemove;
- (NVApp *)findAppWithURL:(NSURL *)url;
- (NSInteger)indexOfAppWithURL:(NSURL *)url;

@end
