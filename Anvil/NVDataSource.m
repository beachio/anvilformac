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

// Path components
static NSString *const kAppDataDirectoryURLPathComponent = @"AppData";
static NSString *const kRiotDirectoryURLPathComponent = @"Riot";
static NSString *const kHammerDirectoryURLPathComponent = @"Anvil";
static NSString *const kAppDataFileName = @"Apps.plist";


// Keys
static NSString *const kAppsKey = @"apps";

@implementation NVDataSource

@synthesize apps;

- (id)init {
    
    self = [super init];
    if (self) {
        
        self.apps = [[NSArray alloc] init];
        
        [self addObserver:self forKeyPath:kAppsKey options:0 context:nil];
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
    
    NSMutableArray *appsArray = [[NSMutableArray alloc] init];
    
    NSString *path = [@"~/.pow/" stringByExpandingTildeInPath];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSArray *dirContents = [fm contentsOfDirectoryAtPath:path error:nil];
    
    for (NSString* name in dirContents) {
        
        if([name isNotEqualTo:@".DS_Store"]) {
            NSURL *url = [NSURL URLWithString:[[NSString stringWithFormat:@"~/.pow/%@", name] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
            
            NVApp *thisApp = [[NVApp alloc] initWithURL:url];
            [appsArray addObject:thisApp];
        }
    }
    
    self.apps = [NSArray arrayWithArray:appsArray];
}

- (void)addAppWithURL:(NSURL *)url {
    
    NVApp *newApp = [[NVApp alloc] init];
    newApp.name = [url lastPathComponent];
    newApp.url = url;
    [newApp createSymlink];
    
    [[self mutableArrayValueForKey:kAppsKey] addObject:newApp];
}


- (void)removeApp:(NVApp *)appToRemove {
    
    [appToRemove destroySymlink];
    [[self mutableArrayValueForKey:kAppsKey] removeObject:appToRemove];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
//    if ([keyPath isEqualToString:kAppsKey]) {
//        [self writeOutAppDataToDisk];
//    }
}



@end
