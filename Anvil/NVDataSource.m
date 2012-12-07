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

- (NSInteger)indexOfAppWithURL:(NSURL *)url {
    
    NSInteger i = 0;
    for (NVApp* app in self.apps) {
        
        if ([app.url.path isEqualToString:url.path]) {
            
            return i;
        }
        i = i + 1;
    }
    return -1;
}

- (NVApp *)findAppWithURL:(NSURL *)url {
    
    for (NVApp* app in self.apps) {
        
        if (app.url == url) {
            
            return app;
        }
    }
    return nil;
}

- (void)readInSavedAppDataFromDisk {
    
    NSMutableArray *appsArray = [[NSMutableArray alloc] init];
    
    NSString *path = [@"~/.pow/" stringByExpandingTildeInPath];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSArray *dirContents = [fm contentsOfDirectoryAtPath:path error:nil];
    
    for (NSString* name in dirContents) {
        
        if([name isNotEqualTo:@".DS_Store"]) {
            NSURL *url = [NSURL URLWithString:[[NSString stringWithFormat:@"~/.pow/%@", name] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
            
            NVApp *thisApp;
            
            if (self.apps.count == 0) {
                thisApp = [[NVApp alloc] initWithURL:url];
            } else {            
                for (NVApp *app in self.apps) {
                    
                    NSString *path = [NSString stringWithFormat:@"file://%@", [url.path stringByExpandingTildeInPath]];
                    NSURL *expandedURL = [[NSURL URLWithString:path] URLByResolvingSymlinksInPath];
                    
                    if([app.url.path isEqualToString:expandedURL.path]) {
                        thisApp = app;
                    }
                }
                
                if (!thisApp) {
                    thisApp = [[NVApp alloc] initWithURL:url];
                }
            }
            [appsArray addObject:thisApp];
        }
    }
    
    self.apps = [NSArray arrayWithArray:appsArray];
}

- (void)addAppWithURL:(NSURL *)url andName:(NSString *)name {
    
    NVApp *newApp = [[NVApp alloc] init];
    newApp.name = name;
    newApp.url = url;
    [newApp createSymlink];
    
    [[self mutableArrayValueForKey:kAppsKey] addObject:newApp];
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
