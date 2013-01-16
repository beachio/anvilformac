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
        
        if (!self.apps) {
            self.apps = [[NSArray alloc] init];
        }
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
    NSError *error = nil;
    NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:&error];
    
    if(error) {
        
        NSLog(@"There was an error accessing ~/.pow! Please ensure your Pow setup is correct.");
        return;
    }
    
    for (NSString* symlinkName in dirContents) {
        
        if ([symlinkName isNotEqualTo:@".DS_Store"]) {
            
            NSString *encodedName = [[NSString stringWithFormat:@"~/.pow/%@", symlinkName] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            NSURL *url = [NSURL URLWithString:encodedName];
            NVApp *thisApp = nil;
            
            if (!url) {
                continue;
            }

            // See whether it exists already first. 
            for (NVApp *app in self.apps) {
                if([app.name isEqualToString:symlinkName]) {
                    thisApp = app;
                }
            }
            
            // If not, let's add it!
            if (!thisApp) {
                thisApp = [[NVApp alloc] initWithURL:url];
            }
            
            // thisApp can be false, or nil. initWithURL can return nil if it doesn't actually initialize properly. Bit of a gotcha.
            if (thisApp) {
                [appsArray addObject:thisApp];
            }
        }
    }
    
    self.apps = [NSArray arrayWithArray:appsArray];
}

# pragma mark Adding and removing apps

- (NVApp *)addAppWithURL:(NSURL *)url {
    
    NVApp *newApp = [[NVApp alloc] init];
    newApp.name = [url lastPathComponent];
    newApp.url = url;
    [newApp createSymlink];
    
    [[self mutableArrayValueForKey:kAppsKey] addObject:newApp];
    
    return newApp;
}

- (void)removeApp:(NVApp *)appToRemove {
    
    [appToRemove destroySymlink];
    [[self mutableArrayValueForKey:kAppsKey] removeObject:appToRemove];
}

@end
