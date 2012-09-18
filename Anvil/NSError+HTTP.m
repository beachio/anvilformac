//
//  NSError+HTTP.m
//  Junction
//
//  Created by Joe Ricioppo on 3/8/12.
//  Copyright (c) 2012 Riot. All rights reserved.
//

#import "NSError+HTTP.h"

@implementation NSError (HTTP)

- (NSDictionary *)JU_dictionaryRepresentation {
    
    NSMutableDictionary *errorDictionary = [NSMutableDictionary dictionary];
    
    NSString *errorDescription = [self localizedDescription];
    if (errorDescription) {
        [errorDictionary setObject:errorDescription forKey:@"errorDescription"];
    }
    
    NSString *failureReason = [self localizedFailureReason];
    if (failureReason) {
        [errorDictionary setObject:failureReason forKey:@"failureReason"];
    }
    
    NSString *recoverySuggestion = [self localizedRecoverySuggestion];
    if (recoverySuggestion) {
        [errorDictionary setObject:recoverySuggestion forKey:@"recoverySuggestion"];
    }
    
    NSDictionary *userInfo = [self userInfo];
    if (userInfo) {
        [errorDictionary setObject:userInfo forKey:@"userInfo"];
    }
    
    if ([errorDictionary allKeys].count < 1) {
        errorDictionary = nil;
    }
    
    return errorDictionary;
}

@end
