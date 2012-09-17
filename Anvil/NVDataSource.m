//
//  NVDataSource.m
//  Anvil
//
//  Created by Elliott Kember on 31/07/2012.
//  Copyright (c) 2012 Riot. All rights reserved.
//

#import "NVDataSource.h"

@interface NVDataSource ()

@property (strong, readwrite, nonatomic) NSArray *apps;

@end


@implementation NVDataSource

@synthesize apps;

- (id)init {
    
    self = [super init];
    if (self) {
        
        self.apps = [[NSArray alloc] init];
        
//        [self addObserver:self forKeyPath:kAppsKey options:0 context:nil];
    }
    
    return self;
}

+ (NVDataSource *)sharedDataSource {
    
    static NVDataSource *sharedDataSource = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedDataSource = [[NVDataSource alloc] init];
    });
    
    return sharedDataSource;
}


- (void)readInSavedAppDataFromDisk {
    
    NSLog(@"reading in");
    NSMutableArray *appsArray = [[NSMutableArray alloc] init];
    
    NSString *path = [@"~/.pow/" stringByExpandingTildeInPath];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSArray *dirContents = [fm contentsOfDirectoryAtPath:path error:nil];
    
    for (NSString* name in dirContents) {
        
        if([name isNotEqualTo:@".DS_Store"]) {
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"~/.pow/%@", name]];
            NVApp *thisApp = [[NVApp alloc] initWithURL:url];
            [appsArray addObject:thisApp];
        }
    }
    
    self.apps = [NSArray arrayWithArray:appsArray];
}

- (void)addSiteURL:(NSURL *)url {
    
    NVApp *newApp = [[NVApp alloc] init];
    newApp.name = [url lastPathComponent];
    newApp.url = [NSURL URLWithString:url.path];
    [newApp createSymlink];
}


@end
