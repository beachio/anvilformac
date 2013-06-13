//
//  NVDataSource.m
//  Anvil
//
//  Created by Elliott Kember on 31/07/2012.
//  Copyright (c) 2012 Riot. All rights reserved.
//

// This dataSource tracks normal "apps" and hammer "apps.
// It uses two separate arrays: apps and hammerApps.

#import "NVDataSource.h"

@interface NVDataSource ()

@property (strong, readwrite, nonatomic) NSMutableArray *apps;
@property (strong, readwrite, nonatomic) NSMutableArray *hammerApps;
@property (strong, nonatomic) NSFileManager *fileManager;

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
        
        if (!self.fileManager)  self.fileManager =  [NSFileManager defaultManager];
        if (!self.apps)         self.apps =         [[NSMutableArray alloc] init];
        if (!self.hammerApps)   self.hammerApps =   [[NSMutableArray alloc] init];
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


#pragma mark - Importing sites

- (NSArray *)contentsOfPowDirectory {
    
    NSString *path = [@"~/.pow/" stringByExpandingTildeInPath];
    
    NSError *error = nil;
    NSArray *dirContents = [self.fileManager contentsOfDirectoryAtPath:path error:&error];
    
    if (error) {
        NSLog(@"Error reading contents of Pow directory: %@", error);
        return @[];
    }
    
    return dirContents;
}

// The wrapper function for the whole shebang.
- (void)readInSavedAppDataFromDisk {
    
    [self clearOldHammerSymlinks];
    [self importFromPowdirectory];
    [self importNewHammerSites];
}

// Step 1
// Delete any ~/.pow/*.hammer symlinks
- (void)clearOldHammerSymlinks {
    
    NSArray *dirContents = [self contentsOfPowDirectory];
    NSDictionary *hammerAppsDictionary = [self hammerSitesDictionary];
    
    for (NSString* symlinkName in dirContents) {
        
        // If this is a .hammer.dev site, we'd better check it exists or we'll have to delete it.
        if ([symlinkName hasSuffix:@".hammer"]) {
            
            BOOL found = false;
            
            NSString *encodedName = [[NSString stringWithFormat:@"~/.pow/%@", symlinkName] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            NSURL *url = [NSURL URLWithString:encodedName];
            
            // All .hammer projects have a Public directory in the .pow directory
            // /Users/elliott/.pow/myProject/Public
            NSString *escapedSymlinkUrlPath = [[url.path stringByAppendingPathComponent:@"Public"] stringByResolvingSymlinksInPath];
            
            for (NSDictionary *hammerSiteDictionary in hammerAppsDictionary) {
                
                if (found) continue;
                
                // /Users/elliott/sites/project
                NSString *hammerProjectDirectory = [[[hammerSiteDictionary valueForKey:@"rootDirectoryURL"] stringByAppendingPathComponent:@"Build"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                found = [hammerProjectDirectory isEqualTo:escapedSymlinkUrlPath];
            }
            
            if (!found) {
                
                NSError *error = nil;
                NSString *urlPath = [[[url path] stringByExpandingTildeInPath] stringByResolvingSymlinksInPath];
                [self.fileManager removeItemAtPath:urlPath error:&error];
                if (error) NSLog(@"Error deleting item at %@: %@", urlPath, error);
            }
        }
    }
}

// Step 2
// Read the ~/.pow directory and import all the sites.
- (void)importFromPowdirectory {
    
    NSMutableArray *appsArray = [[NSMutableArray alloc] init];
    NSMutableArray *hammerAppsArray = [[NSMutableArray alloc] init];
    
    NSArray *dirContents = [self contentsOfPowDirectory];
    
    for (NSString* symlinkName in dirContents) {
        
        if ([symlinkName isNotEqualTo:@".DS_Store"]) {
            
            NSString *encodedName = [[NSString stringWithFormat:@"~/.pow/%@", symlinkName] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            NSURL *url = [NSURL URLWithString:encodedName];
            NVApp *thisApp = nil;
            
            if (!url) continue;
            
            thisApp = [self appByName:symlinkName];
            
            // If not, let's add it!
            if (!thisApp) {
                
                thisApp = [[NVApp alloc] initWithURL:url];
            }
            
            // thisApp can be false, or nil. initWithURL can return nil if it doesn't actually initialize properly. Bit of a gotcha.
            if (thisApp) {
                
                if ([thisApp.name hasSuffix:@".hammer"]) {
                    
                    // This shouldn't actually happen here.
                    [hammerAppsArray addObject:thisApp];
                } else {
                    
                    [appsArray addObject:thisApp];
                }
            }
        }
    }
    
    self.hammerApps = hammerAppsArray;
    self.apps = appsArray;
}

// Step 3
// Import Hammer sites from the Hammer dictionary.
// Add them into our hammerApps array.
- (void)importNewHammerSites {
    
    NSMutableArray *appsToAdd = [[NSMutableArray alloc] init];
    
    for (NSDictionary *siteDictionary in [self hammerSitesDictionary]) {
        
        BOOL found = false;
        NSString *localFileURL = [[siteDictionary valueForKey:@"rootDirectoryURL"] stringByAppendingPathComponent:@"Build"];
        
        for (NVApp *app in self.hammerApps) {
            
            if (found) continue;
            if ([[app.url.path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] isEqualTo:localFileURL]) {
                
                found = true;
            }
        }
        
        if (!found) {
                        
            // Create a new Hammer site!
            NVApp *newApp = [[NVApp alloc] initWithURL:[NSURL URLWithString:localFileURL]];
            
            NSString *name = [[siteDictionary valueForKey:@"name"] stringByAppendingString:@".hammer"];
            // Better make sure its name is formatted right, though
            newApp.name = [[name stringByReplacingOccurrencesOfString:@" " withString:@"-"] lowercaseString];;
            [newApp createSymlink];
            [appsToAdd addObject:newApp];
        }
    }
    
    for (NVApp *app in appsToAdd) {
        
        [self.hammerApps addObject:app];
    }
}


#pragma mark - App management

// Fetch an app from either .hammerApps and apps arrays, using its name.
- (NVApp *)appByName:(NSString *)name {
    
    NVApp *thisApp;
    for (NVApp *app in self.apps) {
        
        if([app.name isEqualToString:name]) {
            
            thisApp = app;
        }
    }
    for (NVApp *app in self.hammerApps) {
        
        if([app.name isEqualToString:name]) {
            
            thisApp = app;
        }
    }
    return thisApp;
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


# pragma mark Adding and removing apps

- (NVApp *)addAppWithURL:(NSURL *)url {
    
    NVApp *newApp = [[NVApp alloc] init];
    
    if ([[url lastPathComponent] isEqualToString:@"Build"]) {
        
        NSString *hammerProjectName = [[url.path stringByDeletingLastPathComponent] lastPathComponent];
        newApp.name = hammerProjectName;
    } else {
        
        NSURL *buildFolderURL = [url URLByAppendingPathComponent:@"Build"];
        
        BOOL isDirectory;
        if ([self.fileManager fileExistsAtPath:buildFolderURL.path isDirectory:&isDirectory] && isDirectory) {
            
            newApp.url = buildFolderURL;
        } else {
            
            newApp.url = url;
        }
        newApp.name = [url lastPathComponent];
    }
    

    [newApp createSymlink];
    
    [[self mutableArrayValueForKey:kAppsKey] addObject:newApp];
    
    return newApp;
}

- (void)removeApp:(NVApp *)appToRemove {
    
    [appToRemove destroySymlink];
    [[self mutableArrayValueForKey:kAppsKey] removeObject:appToRemove];
}


#pragma mark - Fetching sites from Hammer

- (NSDictionary *)hammerSitesDictionary {
    
    NSString *hammerPath = [@"~/Library/Containers/com.riot.hammer/Data/Library/Application Support/Riot/Hammer/AppData/Apps.plist" stringByExpandingTildeInPath];
    
    NSURL *hammerPathURL = [NSURL fileURLWithPath:hammerPath];
    NSData *plistData = [NSData dataWithContentsOfURL:hammerPathURL];
    
    if (plistData == nil) {
        return [[NSDictionary alloc] init];
    }
    
    NSError *plistReadError = nil;
    NSDictionary *appsPlistDictionary = [NSPropertyListSerialization propertyListWithData:plistData options:0 format:NULL error:&plistReadError];
    if (appsPlistDictionary == nil && plistReadError != nil) {
        
        NSLog(@"[%@ %@], Loading Apps.plist encountered error: %@", [self class], NSStringFromSelector(_cmd), plistReadError);
    }
    
    
    //    NSString *path = [@"~/.pow/" stringByExpandingTildeInPath];
    //    NSError *error = nil;
    //    NSArray *dirContents = [self.fileManager contentsOfDirectoryAtPath:path error:&error];
    //
    //    if(error) {
    //
    //        NSLog(@"There was an error accessing ~/.pow! Please ensure your Pow setup is correct.");
    //    } else {
    //
    //        //        NSFileManager *fileManager = self.fileManager;
    //        //        for (NSString* symlinkName in dirContents) {
    //        //
    //        //            if ([symlinkName hasSuffix:@".hammer"]) {
    //        //
    //        ////                NSString *symlinkPath = [path stringByAppendingPathComponent:symlinkName];
    //        ////                [fileManager removeItemAtPath:symlinkPath error:nil];
    //        //            }
    //        //        }
    //    }
    
    NSDictionary *appsDictionary = [appsPlistDictionary valueForKey:@"apps"];
    
    return appsDictionary;
}

- (NSInteger *)numberOfHammerSites {
    
    return self.hammerApps.count;
}

@end