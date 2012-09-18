//
//  HMCoding.h
//  Hammer
//
//  Created by Joe Ricioppo on 2/28/12.
//  Copyright (c) 2012 Riot. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (JUCoding)

- (id)initWithDictionary:(NSDictionary *)dictionary;

// Assertive KVC
- (NSArray *)arrayForKey:(NSString *)key;
- (NSArray *)arrayOfClass:(Class)objectClass forKey:(NSString *)key;
- (NSArray *)arrayOfDictionariesForKey:(NSString *)key;
- (NSArray *)arrayOfStringsForKey:(NSString *)key;
- (BOOL)boolForKey:(NSString *)key;
- (NSData *)dataForKey:(NSString *)key;
- (NSDate *)dateForKey:(NSString *)key;
- (NSDictionary *)dictionaryForKey:(NSString *)key;
- (double)doubleForKey:(NSString *)key;
- (CGFloat)floatForKey:(NSString *)key;
- (NSInteger)integerForKey:(NSString *)key;
- (NSNumber *)numberForKey:(NSString *)key;
- (NSString *)stringForKey:(NSString *)key;
- (NSUInteger)unsignedIntegerForKey:(NSString *)key;
- (NSURL *)URLForKey:(NSString *)key;
- (id)valueForKey:(NSString *)key assertingClass:(Class)class;
- (id)valueForKey:(NSString *)key assertingRespondsToSelector:(SEL)theSelector;
- (BOOL)contentsOfCollection:(id <NSFastEnumeration>)theCollection areKindOfClass:(Class)theClass;
@end

@interface NSString (JUCoding)
- (NSUInteger)unsignedIntegerValue;
@end

@interface NSNumber (JUCoding)
+ (NSNumber *)numberWithString:(NSString *)string;
@end
