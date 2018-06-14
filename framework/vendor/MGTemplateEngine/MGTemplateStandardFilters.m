//
//  MGTemplateStandardFilters.m
//
//  Created by Matt Gemmell on 13/05/2008.
//  Copyright 2008 Instinctive Code. All rights reserved.
//
#import <Cocoa/Cocoa.h>

#import "MGTemplateStandardFilters.h"


#define UPPERCASE		@"uppercase"
#define LOWERCASE		@"lowercase"
#define CAPITALIZED		@"capitalized"
#define DATE_FORMAT		@"date_format"
#define COLOR_FORMAT	@"color_format"
#define SUBSTRING    @"substring"
#define REPLACE    @"replace"
//#define caselikethis        @"caselikethis"
//#define CaseLikeThis        @"CaseLikeThis"
//#define caseLikeThis        @"caseLikeThis"
//#define CASELIKETHIS        @"CASELIKETHIS"
//#define case_like_this        @"case_like_this"
//#define Case_Like_This        @"Case_Like_This"
//#define case_Like_This        @"case_Like_This"
//#define CASE_LIKE_THIS        @"CASE_LIKE_THIS"
//"CLAMPS" value x so that min_value <= X <= max_value
#define CLAMP(x, min_value, max_value) MIN(MAX(x, min_value), max_value)

@implementation MGTemplateStandardFilters


- (NSArray *)filters
{
	return [NSArray arrayWithObjects:
			UPPERCASE, LOWERCASE, CAPITALIZED, 
			DATE_FORMAT, COLOR_FORMAT, SUBSTRING, REPLACE,
			nil];
}


- (id)filterInvoked:(NSString *)filter withArguments:(NSArray *)args onValue:(id)value
{
    
    if ([filter isEqualToString:REPLACE]) {
        if([args count] == 2) {
            return [value stringByReplacingOccurrencesOfString:[args objectAtIndex:1] withString:[args objectAtIndex:2] ];
        }
    } else if ([filter isEqualToString:SUBSTRING]) {
        if([args count] == 2) {
            NSInteger begin = [[args objectAtIndex:0] integerValue];
            NSInteger end = [[args objectAtIndex:1] integerValue];
            NSInteger stringLength =[value length];
            if(begin < 0) { //Realitive to end of string? -> convert to absolute position
                begin = CLAMP(begin + stringLength+1, 0, stringLength);
            } else {
                begin = CLAMP(begin, 0, stringLength);
            }
            if(end < 0) { //Realitive to end of string? -> convert to absolute position
                end = CLAMP(end + stringLength +1, 0, stringLength); //Note: the +1 is so that -1 will indicate the end of the string
            } else {
                end = CLAMP(end, 0, stringLength);
            }
            
            if (begin >= end) { //Bad Range -> return empty string
                return @"";
            }
            NSString* result = [value substringWithRange:NSMakeRange(begin, end-begin)];
            return result;
        }
    } else if ([filter isEqualToString:UPPERCASE]) {
		return [[NSString stringWithFormat:@"%@", value] uppercaseString];
		
	} else if ([filter isEqualToString:LOWERCASE]) {
		return [[NSString stringWithFormat:@"%@", value] lowercaseString];
		
	} else if ([filter isEqualToString:CAPITALIZED]) {
		return [[NSString stringWithFormat:@"%@", value] capitalizedString];
		
	} else if ([filter isEqualToString:DATE_FORMAT]) {
		// Formats NSDates according to Unicode syntax: 
		// http://unicode.org/reports/tr35/tr35-4.html#Date_Format_Patterns 
		// e.g. "dd MM yyyy" etc.
		if ([value isKindOfClass:[NSDate class]] && [args count] == 1) {
			NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
			[dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
			NSString *format = [args objectAtIndex:0];
			[dateFormatter setDateFormat:format];
			return [dateFormatter stringFromDate:(NSDate *)value];
		}
		
	} else if ([filter isEqualToString:COLOR_FORMAT]) {
#if TARGET_OS_IPHONE
        if ([value isKindOfClass:[UIColor class]] && [args count] == 1) {
#else
		if ([value isKindOfClass:[NSColor class]] && [args count] == 1) {
#endif
			NSString *format = [[args objectAtIndex:0] lowercaseString];
			if ([format isEqualToString:@"hex"]) {
				// Output color in hex format RRGGBB (without leading # character).
#if TARGET_OS_IPHONE
                CGColorRef color = [(UIColor *)value CGColor];
                CGColorSpaceRef colorSpace = CGColorGetColorSpace(color);
                CGColorSpaceModel colorSpaceModel = CGColorSpaceGetModel(colorSpace);
                
                if (colorSpaceModel != kCGColorSpaceModelRGB)
                    return @"000000";
                
                const CGFloat *components = CGColorGetComponents(color);
                NSString *colorHex = [NSString stringWithFormat:@"%02x%02x%02x",
                                      (unsigned int)(components[0] * 255),
                                      (unsigned int)(components[1] * 255),
                                      (unsigned int)(components[2] * 255)];
                return colorHex;
#else
				NSColor *color = [(NSColor *)value colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
				if (!color) { // happens if the colorspace couldn't be converted
					return @"000000"; // black
				} else {
					NSString *colorHex = [NSString stringWithFormat:@"%02x%02x%02x", 
										  (unsigned int)([color redComponent] * 255),
										  (unsigned int)([color greenComponent] * 255),
										  (unsigned int)([color blueComponent] * 255)];
					return colorHex;
				}
#endif
			}
		}
		
	}
	
	return value;
}


@end
