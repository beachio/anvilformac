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
@property NSInteger _numberOfHammerSites;

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

- (NSArray *)hammerSiteFileURLs {
    
    NSString *hammerPath = @"/Users/elliott/Library/Containers/com.riot.hammer/Data/Library/Application Support/Riot/Hammer/AppData/Apps.plist";
    
    NSURL *hammerPathURL = [NSURL fileURLWithPath:hammerPath];
    NSData *plistData = [NSData dataWithContentsOfURL:hammerPathURL];
    
    if (plistData == nil) {
        return [[NSArray alloc] init];
    }
    
    NSError *plistReadError = nil;
    NSDictionary *appsPlistDictionary = [NSPropertyListSerialization propertyListWithData:plistData options:0 format:NULL error:&plistReadError];
    if (appsPlistDictionary == nil && plistReadError != nil) {
        
        NSLog(@"[%@ %@], Loading Apps.plist encountered error: %@", [self class], NSStringFromSelector(_cmd), plistReadError);
    }
    
    
    NSString *path = [@"~/.pow/" stringByExpandingTildeInPath];
    NSError *error = nil;
    NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:&error];
    
    if(error) {
        
        NSLog(@"There was an error accessing ~/.pow! Please ensure your Pow setup is correct.");
    } else {
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        for (NSString* symlinkName in dirContents) {
            
            if ([symlinkName hasSuffix:@".hammer"]) {
                
                NSString *symlinkPath = [path stringByAppendingPathComponent:symlinkName];
                
                [fileManager removeItemAtPath:symlinkPath error:nil];
            }
        }
    }

    
    
    NSDictionary *appsDictionary = [appsPlistDictionary valueForKey:@"apps"];
    
    NSArray *urlArray = [appsDictionary valueForKey:@"rootDirectoryURL"];
    
    for (NSDictionary *siteDictionary in appsDictionary) {
        
        NSString *name = [[siteDictionary valueForKey:@"name"] stringByAppendingString:@".hammer"];
        NSString *localFileURL = [[siteDictionary valueForKey:@"rootDirectoryURL"] stringByAppendingPathComponent:@"Build"];
        
        NVApp *newApp = [[NVApp alloc] initWithURL:[NSURL URLWithString:localFileURL]];
        assert(newApp);
        newApp.name = name;
        [newApp createSymlink];
    }
    
    return urlArray;
}

- (NSInteger *)numberOfHammerSites {
    
    // TODO: Un-magick
    return self._numberOfHammerSites;
}

- (NSInteger)hammerGroupHeaderRowNumber {
    
    return ([self numberOfHammerSites] - 1);
}

- (void)readInSavedAppDataFromDisk {
    
    [self hammerSiteFileURLs];
    
    NSMutableArray *appsArray = [[NSMutableArray alloc] init];
    NSMutableArray *hammerAppsArray = [[NSMutableArray alloc] init];
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
                
                if ([thisApp.name hasSuffix:@".hammer"]) {
                    [hammerAppsArray addObject:thisApp];
                } else {
                    [appsArray addObject:thisApp];
                }
            }
        }
    }
    
    self._numberOfHammerSites = [hammerAppsArray count];
    self.apps = [NSArray arrayWithArray:[appsArray arrayByAddingObjectsFromArray:hammerAppsArray]];
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
