//
//  XSDenumeration.m
//  XSDConverter
//
//  Created by Alex Smith on 3/25/15.
//
//

#import "XSDenumeration.h"
#import "XSDschema.h"
#import "XSType.h"
#import "XMLUtils.h"

@interface XSDenumeration ()

@property (strong, nonatomic) NSString* value;
@property (strong, nonatomic) NSString* formattedValue;
@property (strong, nonatomic) NSString* type;

@end

@implementation XSDenumeration

- (id) init
{
    if(self = [super init]) {
        self.value = nil;
    }
    return self;
}


- (id) initWithNode: (NSXMLElement*) node schema: (XSDschema*) schema{
    if(self = [super initWithNode:node schema:schema]) {
        self.value = [XMLUtils node:node stringAttribute:@"value"];
        
        self.formattedValue = [self.value uppercaseString];
        self.formattedValue = [self.formattedValue stringByReplacingOccurrencesOfString:@" " withString:@"_"];
        self.formattedValue = [self.formattedValue stringByReplacingOccurrencesOfString:@"-" withString:@"_"];
        self.formattedValue = [self.formattedValue stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
        self.formattedValue = [XSDenumeration toCamelCase:self.formattedValue];
        if ([self.formattedValue isEqualToString:@"default"]) {
            self.formattedValue = @"defaultValue";
        }
    }
    return self;
}

+ (NSString *)toCamelCase:(NSString *)string {
    NSArray *components = [string componentsSeparatedByString:@"_"];
    NSMutableString *output = [NSMutableString string];
    
    for (NSUInteger i = 0; i < components.count; i++) {
        if (i == 0) {
            [output appendString:[components[i] lowercaseString] ];
        } else {
            [output appendString:[components[i] capitalizedString]];
        }
    }
    
    return [NSString stringWithString:output];
}



- (NSString*) objcType {
    return [[self.schema typeForName: self.type] targetClassName];
}
@end
