//
//  NVApp.m
//  Anvil
//
//  Created by Elliott Kember on 16/09/2012.
//  Copyright (c) 2012 Riot. All rights reserved.
//

#import "NVApp.h"

@interface NVApp ()

@property (readwrite, nonatomic) NSURL *_faviconURL;
@property (readwrite, nonatomic) BOOL hasNoFavicon;

@end

@implementation NVApp

static NSString *const kFaviconFileName = @"favicon.ico";
static NSString *const kAppleTouchIconFileName = @"apple-touch-icon.png";
static NSString *const kPrecomposedAppleTouchIconFileName = @"apple-touch-icon-precomposed.png";

- (id)initWithURL:(NSURL *)url {
   
    self = [super  init];
    if(self) {
        
        self.name = [url lastPathComponent];
    
        // file:// Users/Elliott/a/b/c
        NSString *stringWithSymlinks = [NSString stringWithFormat:@"file://%@", [url.path stringByExpandingTildeInPath]];
        NSURL *expandedURL = [[NSURL URLWithString:stringWithSymlinks] URLByResolvingSymlinksInPath];
        
        // TODO: Add , @"Build" to this array when Hammer is available.
        NSArray *folderTypesArray = [[NSArray alloc] initWithObjects:@"Public", nil];
        
        for (NSString *folderName in folderTypesArray) {
            
            // Check whether this app has a public URL symlink inside it.
            NSString *publicURLPath = [stringWithSymlinks  stringByAppendingPathComponent:folderName];
            NSURL *publicURL = [[NSURL URLWithString:publicURLPath] URLByResolvingSymlinksInPath];
            BOOL publicURLExists = [[NSFileManager defaultManager] fileExistsAtPath:publicURL.path];
            if (publicURLExists && ![[publicURL.path stringByDeletingLastPathComponent] isEqualTo:expandedURL.path]) {
                
                expandedURL = publicURL;
            }
        }
        self.url = expandedURL;
        
        // Check for index.html file
        [self createIndexFileIfNonExistentAndNotARackApp];
    }
    return self;
}

#pragma mark - URLs

- (NSURL *)faviconURL {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];

    // If we've cached this already, use the cache.
    if (self._faviconURL && [fileManager fileExistsAtPath:self._faviconURL.path]) {
        
        return self._faviconURL;
    } else if(self.hasNoFavicon) {
        
        return nil;
    }

    NSURL *faviconURL = nil; //[self.url URLByAppendingPathComponent:@"public/favicon.ico"];
    NSArray *enumeratorKeys = [NSArray arrayWithObject:NSURLIsDirectoryKey];
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtURL:self.url includingPropertiesForKeys:enumeratorKeys options:0 errorHandler:NULL];
    
    // Go through every file and find the right icons
    for (NSURL *subFileURL in enumerator) {
        
        NSString *subFileName = subFileURL.pathComponents.lastObject;
        
        if ([subFileName isEqualToString:kFaviconFileName]) {
            
            if (!faviconURL) {
                
                faviconURL = subFileURL;
            }
        }
    }
    
    NSDictionary *attrs = [fileManager attributesOfItemAtPath:faviconURL.path error:NULL];
    
    if( [fileManager fileExistsAtPath:faviconURL.path] && [attrs fileSize] > 0){
        
        self._faviconURL = faviconURL;
        return faviconURL;
    } else {
        
        self.hasNoFavicon = YES;
        self._faviconURL = nil;
        return nil;
    }
}

- (NSURL *)symlinkURL {
    
    NSString *powPath = [@"~/.pow/" stringByExpandingTildeInPath];
    NSString *urlString = [NSString stringWithFormat:@"file://%@/%@", powPath, [[self.name stringByReplacingOccurrencesOfString:@" " withString:@"_"] lowercaseString]];
    
    urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return [NSURL URLWithString:urlString];
}

- (NSURL *)browserURL {
    
    return [NSURL URLWithString:[NSString stringWithFormat:@"http://%@.dev", self.name]];
}

#pragma mark - Actions

// TODO: Push a change to Pow.
- (void)createIndexFileIfNonExistentAndNotARackApp {
    
    if (![self isARackApp]) {
        
        NSString *indexString = [self.url.path stringByAppendingPathComponent:@"index.html"];
        BOOL indexHTMLExists = [[NSFileManager defaultManager] fileExistsAtPath:indexString];
        
        if( !indexHTMLExists ){
            
            NSURL *indexURL = [NSURL fileURLWithPath:indexString];
            NSString *dummyPagePath = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html"];
            [[NSFileManager defaultManager] copyItemAtPath:dummyPagePath toPath:indexURL.path error:nil];
        }
    }
}

- (void)createSymlink {
    
//    BOOL hasBuildFolder = [[NSFileManager defaultManager] fileExistsAtPath:[self.url URLByAppendingPathComponent:@"Build"].path isDirectory:nil];
    
    if ([self isARackApp]) {
        
            [[NSFileManager defaultManager] createSymbolicLinkAtURL:[self symlinkURL] withDestinationURL:self.url error:nil];
    } else {
        
        // TODO: Bring this back in when Hammer is available.
//        if (hasBuildFolder) {
//            
//            [[NSFileManager defaultManager] createDirectoryAtPath:normalizedSymlinkURL.path withIntermediateDirectories:YES attributes:nil error:nil];
//            NSURL *publicFolderURL = [normalizedSymlinkURL URLByAppendingPathComponent:@"Public"];
//            NSURL *realBuildURL = [self.url URLByAppendingPathComponent:@"Build"];
//            [[NSFileManager defaultManager] createSymbolicLinkAtURL:publicFolderURL withDestinationURL:realBuildURL error:nil];
//        } else {
        
            [[NSFileManager defaultManager] createDirectoryAtPath:[self symlinkURL].path withIntermediateDirectories:YES attributes:nil error:nil];
            NSURL *publicFolderURL = [[self symlinkURL] URLByAppendingPathComponent:@"Public"];
            [[NSFileManager defaultManager] createSymbolicLinkAtURL:publicFolderURL withDestinationURL:self.url error:nil];
//        }
    }
}

- (void)destroySymlink {
    
    NSError *error = nil;    
    [[NSFileManager defaultManager] removeItemAtURL:[self symlinkURL] error:&error];
}

- (void)restart {
    
    NSURL *url = [self.url URLByAppendingPathComponent:@"tmp/restart.txt"];
    
    NSError *error = nil;
    NSDictionary *revisionDict = [NSDictionary dictionaryWithObject:[NSDate date] forKey:NSFileModificationDate];
    
    [[NSFileManager defaultManager] setAttributes:revisionDict ofItemAtPath:url.path error:&error];
}

- (void)renameTo:(NSString *)newName {
    
    NSURL *oldSymlinkURL = [self symlinkURL];
    self.name = newName;
    NSURL *newSymlinkURL = [self symlinkURL];
    
    [[NSFileManager defaultManager] moveItemAtURL:oldSymlinkURL toURL:newSymlinkURL error:nil];
}

#pragma mark - What can it be?

- (BOOL)isARackApp {
    
    return [[NSFileManager defaultManager] fileExistsAtPath:[self.url URLByAppendingPathComponent:@"config.ru"].path isDirectory:nil];
}

@end
