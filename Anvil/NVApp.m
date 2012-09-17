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
        self.url = url;
    }
    return self;
}

- (NSString *)directoryName {
    
    return [self.url lastPathComponent];
}

- (NSURL *)realURL {
    
    NSString *stringWithSymlinks = [NSString stringWithFormat:@"file://%@", [self.url.absoluteString stringByExpandingTildeInPath]];
    NSURL *realURL = [[NSURL URLWithString:stringWithSymlinks] URLByResolvingSymlinksInPath];
    
    return realURL;
}

- (NSURL *)faviconURL {
    
    NSURL *faviconURL = [[self realURL] URLByAppendingPathComponent:@"public/favicon.ico"];
    
    NSBundle* myBundle = [NSBundle mainBundle];
    NSString* myImage = [myBundle pathForResource:@"ContextualReveal" ofType:@"png"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if( [fileManager fileExistsAtPath:faviconURL.path] ){
        
        return faviconURL;
    } else {
        
        return [NSURL fileURLWithPath:myImage];
    }
}

- (NSURL *)symlinkURL {
    
    NSString *powPath = [@"~/.pow/" stringByExpandingTildeInPath];
    return [NSURL URLWithString:[NSString stringWithFormat:@"file://%@/%@", powPath, self.name]];
}

- (void)createSymlink {
    
    NSError *error = nil;
    
    NSLog(@"%@ -> %@", [self symlinkURL], [self realURL].absoluteString);
    
    [[NSFileManager defaultManager] createSymbolicLinkAtURL:[self symlinkURL] withDestinationURL:[self realURL] error:&error];
}


@end
