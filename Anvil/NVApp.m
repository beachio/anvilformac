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
    
        NSString *stringWithSymlinks = [NSString stringWithFormat:@"file://%@", [url.path stringByExpandingTildeInPath]];

        if (!stringWithSymlinks) {
            
            return false;
        }
        
        NSString *unescapedPath = [url.path stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSURL *expandedURL = [[NSURL URLWithString:unescapedPath] URLByResolvingSymlinksInPath];
        
        if (!expandedURL) {
            
            expandedURL = [NSURL fileURLWithPath:unescapedPath];
        }
        
        // TODO: Add , @"Build" to this array when Hammer is available.
        NSArray *folderTypesArray = [[NSArray alloc] initWithObjects:@"Public", @"Build", nil];
        
        expandedURL = [[NSURL fileURLWithPath:[expandedURL.path stringByExpandingTildeInPath]] URLByResolvingSymlinksInPath];
        self.url = [expandedURL URLByResolvingSymlinksInPath];
        
        if (![self isARackApp]) {
            
            for (NSString *folderName in folderTypesArray) {
                
                // Check whether this app has a public URL symlink inside it.
                NSString *publicURLPath = [stringWithSymlinks  stringByAppendingPathComponent:folderName];
                NSURL *publicURL = [[NSURL URLWithString:publicURLPath] URLByResolvingSymlinksInPath];
                BOOL publicURLExists = [[NSFileManager defaultManager] fileExistsAtPath:publicURL.path];
                if (publicURLExists && ![[publicURL.path stringByDeletingLastPathComponent] isEqualTo:expandedURL.path]) {
                    
                    expandedURL = publicURL;
                }
            }
        }

        self.url = expandedURL;
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
    NSString *urlString = [NSString stringWithFormat:@"file://%@/%@", powPath, [[self.name stringByReplacingOccurrencesOfString:@" " withString:@"-"] lowercaseString]];
    
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
        
        if( !indexHTMLExists && indexString){
            
            NSURL *indexURL = [NSURL fileURLWithPath:indexString];
            NSString *dummyPagePath = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html"];
            [[NSFileManager defaultManager] copyItemAtPath:dummyPagePath toPath:indexURL.path error:nil];
        }
    }
}

- (void)createSymlink {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *powPath = [@"~/.pow" stringByResolvingSymlinksInPath];
    
    if (![fileManager fileExistsAtPath:powPath]) {
        
        NSLog(@" NO POW DIRECTORY");
        NSString *destinationPath = [@"~/Library/Application Support/Pow/Hosts" stringByResolvingSymlinksInPath];
        
        NSLog(@"New pow path symlink to: %@", destinationPath);
        [fileManager createSymbolicLinkAtPath:powPath withDestinationPath:destinationPath error:nil];
        return;
    }
    
    if ([self isARackApp]) {
        
        [[NSFileManager defaultManager] createSymbolicLinkAtURL:[self symlinkURL] withDestinationURL:self.url error:nil];
    } else {
        
        [[NSFileManager defaultManager] createDirectoryAtPath:[self symlinkURL].path withIntermediateDirectories:YES attributes:nil error:nil];
        NSURL *publicFolderURL = [[self symlinkURL] URLByAppendingPathComponent:@"Public"];
        [[NSFileManager defaultManager] createSymbolicLinkAtURL:publicFolderURL withDestinationURL:self.url error:nil];
    }
}

- (void)destroySymlink {
    
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtURL:[self symlinkURL] error:&error];
}

- (void)restart {
    

    NSURL *tmpDirectoryURL = [self.url URLByAppendingPathComponent:@"tmp"];
    NSError *tmpDirectoryError = nil;
    [[NSFileManager defaultManager] createDirectoryAtURL:tmpDirectoryURL withIntermediateDirectories:YES attributes:nil error:&tmpDirectoryError];

    NSURL *url = [self.url URLByAppendingPathComponent:@"tmp/restart.txt"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:url.path]) {
        
        [[NSFileManager defaultManager] createFileAtPath:url.path contents:nil attributes:nil];
    }
    
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

- (BOOL)needsAnIndexFile {
    
    if ([self isARackApp]) {
        return false;
    } else {
        
        NSString *indexString = [self.url.path stringByAppendingPathComponent:@"index.html"];
        BOOL indexHTMLExists = [[NSFileManager defaultManager] fileExistsAtPath:indexString];
        
        assert(indexString);
        
        // If the file doesn't exist, and the URL is valid, yes. We need an index.html file.
        if( !indexHTMLExists && indexString ){
            return true;
        }
    }
    // Probably not. Leave it alone.
    return false;
}

@end
