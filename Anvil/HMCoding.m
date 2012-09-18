//
//  JUCoding.m
//  Junction
//
//  Created by Joe Ricioppo on 2/28/12.
//  Copyright (c) 2012 Riot. All rights reserved.
//

#import "HMCoding.h"

@implementation NSObject (JUCoding)

- (id)initWithDictionary:(NSDictionary *)dictionary;
{
    if (!(self = [self init])) return nil;
    
    [self setValuesForKeysWithDictionary:dictionary];
    
    return self;
}

#pragma mark Assertive Key-Value Coding
/* Typed accessors for all property list types, and a few convenience accessors. These methods make deserializing a property list type-safe, without requiring more code than standard KVC. Regressions in code and data can be caught without necessitating unit tests.
 The primitive method -valueForKey:assertingClass: calls -valueForKey:, then calls isKindOfClass: on the result. In debug configuration, this will raise an assertion. Otherwise, the method will return nil.
 The primitive method -valueForKey:assertingRespondsToSelector: works the same way, but with selectors. This is necessary because some plist formats are ambiguous and can return an NSString instead of an NSNumber. Since they have nearly the same interface (any impedence mismatch quickly rememdied with a category) that route works better.
 The helper method -contentsOfCollection:areKindOfClass: simplifies type checking the contents of collections. This is both a convenient shortcut and an increase in type-safety.
 */

- (NSArray *)arrayForKey:(NSString *)key;
{
    return [self valueForKey:key assertingClass:[NSArray class]];
}

- (NSArray *)arrayOfClass:(Class)objectClass forKey:(NSString *)key;
{
    NSAssert1([objectClass respondsToSelector:@selector(initWithDictionary:)], @"%@ does not respond to initWithDictionary:", NSStringFromClass(objectClass));
    
    NSArray *keyedObjects = [self arrayOfDictionariesForKey:key];
    if (!keyedObjects || ![keyedObjects isKindOfClass:[NSArray class]] || !keyedObjects.count)
        return nil;
    
    id newObject = nil;
    NSMutableArray *newObjects = [NSMutableArray array];
    for (NSDictionary *keyedObject in keyedObjects)
        if ((newObject = [[objectClass alloc] initWithDictionary:keyedObject]))
            [newObjects addObject:newObject];
    
    if (!newObjects.count) 
        return nil;
    
    return newObjects;
}

- (NSArray *)arrayOfDictionariesForKey:(NSString *)key;
{
    NSArray *allegedDictionaries = [self valueForKey:key assertingClass:[NSArray class]];
    if ([self contentsOfCollection:allegedDictionaries areKindOfClass:[NSDictionary class]]) 
        return allegedDictionaries;
    
    NSAssert(NO, @"Collection does not contain only dictionaries");
    return nil;
}

- (NSArray *)arrayOfStringsForKey:(NSString *)key;
{
    NSArray *allegedStrings = [self valueForKey:key assertingClass:[NSArray class]];
    if ([self contentsOfCollection:allegedStrings areKindOfClass:[NSString class]]) 
        return allegedStrings;
    
    NSAssert(NO, @"Collection does not contain only strings");
    return nil;
}

- (BOOL)boolForKey:(NSString *)key;
{
    return [[self valueForKey:key assertingRespondsToSelector:@selector(boolValue)] boolValue];
}

- (NSData *)dataForKey:(NSString *)key;
{
    return [self valueForKey:key assertingClass:[NSData class]];
}

- (NSDate *)dateForKey:(NSString *)key;
{
    id value = [self valueForKey:key];
    if (!value || value == (id)[NSNull null]) return nil;
    if ([value isKindOfClass:[NSDate class]]) return value;
    
    if ([value isKindOfClass:[NSString class]])
        return [[[NSDateFormatter alloc] init] dateFromString:value];
    
    NSAssert1(NO, @"AJCoding cannot make an NSDate from %@", NSStringFromClass([value class]));
    
    return nil;
}

- (NSDictionary *)dictionaryForKey:(NSString *)key;
{
    return [self valueForKey:key assertingClass:[NSDictionary class]];
}

- (double)doubleForKey:(NSString *)key;
{
    return [[self valueForKey:key assertingRespondsToSelector:@selector(doubleValue)] doubleValue];
}

- (CGFloat)floatForKey:(NSString *)key;
{
    return [[self valueForKey:key assertingRespondsToSelector:@selector(floatValue)] floatValue];
}

- (NSInteger)integerForKey:(NSString *)key;
{
    return [[self valueForKey:key assertingRespondsToSelector:@selector(integerValue)] integerValue];
}

- (NSNumber *)numberForKey:(NSString *)key;
{
    id value = [self valueForKey:key];
    if (!value || value == (id)[NSNull null]) return nil;
    if ([value isKindOfClass:[NSNumber class]]) return value;
    if ([value isKindOfClass:[NSString class]])
        return [NSNumber numberWithString:value];
    
    NSAssert1(NO, @"AJCoding cannot make an NSNumber from %@", NSStringFromClass([value class]));
    return nil;
}

- (NSString *)stringForKey:(NSString *)key;
{
    return [self valueForKey:key assertingClass:[NSString class]];
}

- (NSUInteger)unsignedIntegerForKey:(NSString *)key;
{
    return [[self valueForKey:key assertingRespondsToSelector:@selector(unsignedIntegerValue)] unsignedIntegerValue];
}

- (NSURL *)URLForKey:(NSString *)key;
{
    return [NSURL URLWithString:[self stringForKey:key]];
}

- (id)valueForKey:(NSString *)key assertingClass:(Class)theClass;
{
    id value = [self valueForKey:key];
    if (!value || value == [NSNull null]) return nil;
    NSAssert2([value isKindOfClass:theClass], @"AJCoding expects an object of class %@, but class of return value is %@", NSStringFromClass(theClass), NSStringFromClass([value class]));
    return [value isKindOfClass:theClass] ? value : nil;    
}

- (id)valueForKey:(NSString *)key assertingRespondsToSelector:(SEL)theSelector;
{
    id value = [self valueForKey:key];
    if (!value || value == [NSNull null]) return nil;
    NSAssert2([value respondsToSelector:theSelector], @"Object of class %@ does not respond to selector %@", NSStringFromClass([value class]), NSStringFromSelector(theSelector));
    return [value respondsToSelector:theSelector] ? value : nil;    
}

- (BOOL)contentsOfCollection:(id <NSFastEnumeration>)theCollection areKindOfClass:(Class)theClass;
{
    for (id theObject in theCollection) if (![theObject isKindOfClass:theClass]) return NO;
    return YES;    
}

@end


@implementation NSString (JUCoding)

- (NSUInteger)unsignedIntegerValue;
{
    return (NSUInteger)self.integerValue;
}

@end

@implementation NSNumber (JUCoding)

+ (NSNumber *)numberWithString:(NSString *)string
{
	
    NSScanner *scanner;
    NSInteger scanLocation = 0;
	
	
    scanner = [NSScanner scannerWithString:string];
    if ([string hasPrefix:@"$"]) scanLocation = 1;    
    // just in case we're given a dollar value
    NSInteger intResult;
    [scanner setScanLocation:scanLocation];
    if ([scanner scanInteger:&intResult] 
        && ([scanner scanLocation] == [string length] )) {
        return [NSNumber numberWithInteger:intResult];
    }
	
    float floatResult;
    [scanner setScanLocation:scanLocation];
    if ([scanner scanFloat:&floatResult] 
        && ([scanner scanLocation] == [string length] )) {
        return [NSNumber numberWithFloat:floatResult];
    }
	
    
    long long longLongResult;
	
    [scanner setScanLocation:scanLocation];
    if ([scanner scanLongLong:&longLongResult] 
        && ([scanner scanLocation] == [string length] )) {
        return [NSNumber numberWithLongLong:floatResult];
    }
	
    NSLog(@"Couldn't convert %@ to nsnumber", string);    
    return [NSNumber numberWithInt:0];
}

@end
