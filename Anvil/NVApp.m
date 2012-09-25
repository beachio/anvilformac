//
//  NVApp.m
//  Anvil
//
//  Created by Elliott Kember on 16/09/2012.
//  Copyright (c) 2012 Riot. All rights reserved.
//

#import "NVApp.h"

@implementation NVApp

- (id)initWithURL:(NSURL *)url {
   
    self = [super  init];
    if(self) {
        
        NSString *stringWithSymlinks = [NSString stringWithFormat:@"file://%@", [url.absoluteString stringByExpandingTildeInPath]];
        NSURL *realURL = [[NSURL URLWithString:stringWithSymlinks] URLByResolvingSymlinksInPath];
        
        self.url = realURL;
        self.name = [url lastPathComponent];
    }
    return self;
}

#pragma mark - URLs

- (NSURL *)realURL {
    
    NSString *stringWithSymlinks = [NSString stringWithFormat:@"file://%@", [self.url.absoluteString stringByExpandingTildeInPath]];
    NSURL *realURL = [[NSURL URLWithString:stringWithSymlinks] URLByResolvingSymlinksInPath];
    
    return realURL;
}

- (NSURL *)faviconURL {
    
    NSURL *faviconURL = [self.url URLByAppendingPathComponent:@"public/favicon.ico"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDictionary *attrs = [fileManager attributesOfItemAtPath:faviconURL.path error:NULL];
    
    if( [fileManager fileExistsAtPath:faviconURL.path] && [attrs fileSize] > 0){
        
        return faviconURL;
    } else {
        
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

- (void)createSymlink {
    
    BOOL isRailsApp = [[NSFileManager defaultManager] fileExistsAtPath:[self.url URLByAppendingPathComponent:@"config.ru"].path isDirectory:nil];
    BOOL hasBuildFolder = [[NSFileManager defaultManager] fileExistsAtPath:[self.url URLByAppendingPathComponent:@"Build"].path isDirectory:nil];
    
    NSURL *normalizedSymlinkURL = [self symlinkURL];
    
    if (isRailsApp) {
        
            [[NSFileManager defaultManager] createSymbolicLinkAtURL:normalizedSymlinkURL withDestinationURL:self.url error:nil];
    } else {
        if (hasBuildFolder) {
            
            [[NSFileManager defaultManager] createDirectoryAtPath:normalizedSymlinkURL.path withIntermediateDirectories:YES attributes:nil error:nil];
            NSURL *publicFolderURL = [normalizedSymlinkURL URLByAppendingPathComponent:@"Public"];
            NSURL *realBuildURL = [self.url URLByAppendingPathComponent:@"Build"];
            [[NSFileManager defaultManager] createSymbolicLinkAtURL:publicFolderURL withDestinationURL:realBuildURL error:nil];
        } else {
            
            [[NSFileManager defaultManager] createDirectoryAtPath:normalizedSymlinkURL.path withIntermediateDirectories:YES attributes:nil error:nil];
            NSURL *publicFolderURL = [normalizedSymlinkURL URLByAppendingPathComponent:@"Public"];
            
            
            [[NSFileManager defaultManager] createSymbolicLinkAtURL:publicFolderURL withDestinationURL:self.url error:nil];
        }
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

// Is it a Rails app?
- (BOOL)canBeRestarted {
    
    return [[NSFileManager defaultManager] fileExistsAtPath:[self.url URLByAppendingPathComponent:@"config/environment.rb"].path isDirectory:nil];
}

@end
