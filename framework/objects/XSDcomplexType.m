/*
 XSDcomplexType.h
 The implementation of properties and methods for the XSDcomplexType object.
 Generated by SudzC.com
 */
#import "XSDcomplexType.h"
#import "XSDexplicitGroup.h"
#import "XSDattribute.h"
#import "XSDelement.h"
#import "XSSimpleType.h"
#import "MGTemplateEngine.h"
#import "ICUTemplateMatcher.h"
#import "XSDschema.h"
#import "XMLUtils.h"

@interface XSDschema (templating)

@property (readonly, nonatomic) NSString* complexTypeArrayType;
@property (readonly, nonatomic) NSString* readComplexTypeElementTemplate;

@end

@interface XSDcomplexType ()

@property (strong, nonatomic) NSString* name;
@property (strong, nonatomic) NSNumber* mixed;
@property (strong, nonatomic) NSString* baseType;
@property (strong, nonatomic) XSDexplicitGroup* sequenceOrChoice;
@property (strong, nonatomic) NSArray* attributes;
@property (strong, nonatomic) NSArray* globalElements;

@end

@implementation XSDcomplexType {
    MGTemplateEngine *engine;
    MGTemplateEngine *engine2; //we need this because else we would recurse and recursion within a single engine is bad
}

- (id) init{
    self = [super init];
    if(self)
    {
        self.name = nil; 
        self.mixed = nil; 
        self.sequenceOrChoice = nil;
        self.baseType = nil;
        self.attributes = nil;
        self.globalElements = [NSMutableArray array];
    }
    
    return self;
}

/**
 * Name:        initWithNode (NSXMLElement*)(XSDschema*)
 * Parameters:  (NSXMLElement*) - the current node found that is a complex type
 *              (XSDschema*) -  the current schema object (the containing parent)
 * Returns:     the generated obect id
 * Description: This will take the complex type (node) for the given containing parent (schema)
 *              and generate the complexType object. This will become the Object-C header/class
 *              file.
 */
- (id) initWithNode:(NSXMLElement*)node schema:(XSDschema*)schema {
    /* Ensure that we have a node defined */
    if(node == nil || schema == nil) {
        return nil;
    }
    /* Generate the node */
    self = [super initWithNode:node schema: schema];
    if(self) {
        engine = [MGTemplateEngine templateEngine];
        [engine setMatcher:[ICUTemplateMatcher matcherWithTemplateEngine:engine]];
        engine2 = [MGTemplateEngine templateEngine];
        [engine2 setMatcher:[ICUTemplateMatcher matcherWithTemplateEngine:engine2]];
        
        self.name = [XMLUtils node: node stringAttribute: @"name"];
        self.mixed = [XMLUtils node: node boolAttribute: @"mixed"];
        
        /* Grab all children from this complexType with attribute */
        NSMutableArray* newAttributes = [NSMutableArray array];
        NSArray* attributeTags = [XMLUtils node:node childrenWithName:@"attribute"];
        
        /* For each element that is an attribute, create it as an attribute node and assign all to the current complex type */
        for(NSXMLElement* anElement in attributeTags) {
            [newAttributes addObject: [[XSDattribute alloc] initWithNode:anElement schema:schema]];
        }
        self.attributes = newAttributes;
        
        /* Grab all elements that appear within the sequence or choice tags */
        NSXMLElement *child = [XMLUtils node:node childWithName:@"sequence"];
        if(!child) {
            child = [XMLUtils node:node childWithName:@"choice"];
        }
        /* 
         * Create an explicit group, meaning they all will be clearly defined and required
         * This will contain child elements (<XSDelement>) in the elements list
         */
        if(child) {
            self.sequenceOrChoice = [[XSDexplicitGroup alloc] initWithNode:child schema:schema];
        }
        
        /* Check if there is complexContent */
        NSXMLElement* content = [XMLUtils node:node childWithName:@"complexContent"];
       
        /* If there is no complex content, check if there thereis simple content */
        if(!content) {
            content = [XMLUtils node:node childWithName:@"simpleContent"];
        }
        
        /* Iterate through the child elements of the content element */
        NSArray* elementTags = [XMLUtils node:content childrenWithName:@"extension"];
        
        /* If we do not have any extensions, check if we have any restrictions */
        if([elementTags count] == 0){
            elementTags = [XMLUtils node:content childrenWithName:@"restriction"];
        }
        
        /* For the element tags found that was an extension|restriction */
        for(NSXMLElement* anElement in elementTags) {
            self.baseType = [XMLUtils node: anElement stringAttribute: @"base"];

            /* Check for compositors */
            child = [XMLUtils node:anElement childWithName:@"sequence"];
            if(!child) {
                child = [XMLUtils node:anElement childWithName:@"choice"];
            }            
            /* We have children within the node, define them */
            if(child) {
                self.sequenceOrChoice = [[XSDexplicitGroup alloc] initWithNode:child schema:schema];
            }

            NSMutableArray* newAttributes = [NSMutableArray array];
            NSArray* attributeTags = [XMLUtils node:anElement childrenWithName:@"attribute"];
            for(NSXMLElement* anElement in attributeTags) {
                [newAttributes addObject: [[XSDattribute alloc] initWithNode:anElement schema:schema]];
            }
            self.attributes = newAttributes;
        }
        
    }
    
    return self;
}

- (NSArray*) elements {
    if(self.sequenceOrChoice != nil) {
        return self.sequenceOrChoice.elements;
    }
    return [NSArray array];
}

- (BOOL) hasElements {
    return self.elements.count > 0;
}

- (NSArray*) simpleTypesInUse {
    NSMutableSet* simpleTypes = [NSMutableSet set];
    
    for (XSDattribute *anAttr in [self attributes]) {
        id type = [self.schema typeForName: anAttr.type];
        [simpleTypes addObject:type];
    }
    
    for (XSDelement* anElement in [self elements]) {
        id<XSType> aType = anElement.schemaType;
        if([aType isKindOfClass: [XSSimpleType class]]) {
            [simpleTypes addObject: aType];
        }
    }
    
    //also add base type if needed
    id baseType = self.baseType;
    if(baseType != nil) {
        id<XSType> t = [self.schema typeForName: baseType];
        if(t != nil && [t isKindOfClass:[XSSimpleType class]]) {
            [simpleTypes addObject:t];
        }
    }
    
    return [simpleTypes allObjects];
}

- (NSArray*) complexTypesInUse {
    NSMutableSet* complexTypes = [NSMutableSet set];
    id<XSType> aType;
    
    for (XSDelement* anElement in [self elements]) {
        //check local first
        aType = anElement.localType;
        if(aType!=self && [aType isKindOfClass: [XSDcomplexType class]]) {
            [complexTypes addObject: anElement.localType];
        } else if(anElement.type) {
            //check inheritence / base type / included types
            aType = [self.schema typeForName: anElement.type];
            assert(aType);
            if(aType!=self && [aType isKindOfClass: [XSDcomplexType class]]) {
                [complexTypes addObject: aType];
            }
        }
    }
    
    return [complexTypes allObjects];
}

- (NSArray*) enumTypesInUse {
    id rtn = [[self simpleTypesInUse] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"hasEnumeration=YES"]];
    return rtn;
}

- (NSString*)retrieveTargetClassNamePrefix {
    NSDictionary *appDefaults = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"appDefaults" ofType:@"plist"]];
    NSString *classPrefix = [appDefaults objectForKey:@"targetClassNamePrefix"];
    return [NSString stringWithFormat:@"%@", classPrefix];
}

- (NSArray*)retrieveTargetClassNamePrefixArray {
    NSDictionary *appDefaults = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"appDefaults" ofType:@"plist"]];
    NSArray *array = [appDefaults objectForKey:@"targetClassNamePrefixArray"];
    NSMutableArray *rtn = [NSMutableArray new];
    for (id item in array) {
        [rtn addObject:(NSString*)item];
    }
    return rtn;
}

static NSString* targetClassNamePrefix = nil;
static NSArray* targetClassNamePrefixArray = nil;

- (NSString*) targetClassName {
    
    if (targetClassNamePrefix == nil) {
        targetClassNamePrefix = [self retrieveTargetClassNamePrefix];
        targetClassNamePrefixArray = [self retrieveTargetClassNamePrefixArray];
    }
    
    NSCharacterSet* illegalChars = [NSCharacterSet characterSetWithCharactersInString: @"-"];
    
    NSString* vName = [self.name stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:[[self.name substringToIndex:1] uppercaseString]];
    if (targetClassNamePrefix.length > 0) {
        for (NSString *aName in targetClassNamePrefixArray) {
            if ([vName isEqualToString:aName]) {
                vName = [NSString stringWithFormat:@"%@%@", targetClassNamePrefix, vName];
            }
        }
    }
    NSRange range = [vName rangeOfCharacterFromSet: illegalChars];
    while(range.length > 0) {
        // delete illegal char
        vName = [vName stringByReplacingCharactersInRange: range withString: @""];
        // range is now at next char
        vName = [vName stringByReplacingCharactersInRange: range withString:[[vName substringWithRange: range] uppercaseString]];
        
        range = [vName rangeOfCharacterFromSet: illegalChars];
    }
    
    NSString *prefix = [self.schema classPrefixForType:self];
    NSString *rtn = [NSString stringWithFormat: @"%@%@", prefix, vName];

    return rtn;
}

- (BOOL) hasSimpleBaseClass {
    id baseType = self.baseType;
    if(baseType != nil) {
        id<XSType> t = [self.schema typeForName: baseType];
        return [t isKindOfClass:[XSSimpleType class]];
    }
    return NO;
}

- (BOOL) hasComplexBaseClass {
    id baseType = self.baseType;
    if(baseType != nil) {
        id<XSType> t = [self.schema typeForName: baseType];
        return [t isKindOfClass:[XSDcomplexType class]];
    }
    return NO;
}

- (BOOL) hasComplexChildren {
    return self.complexTypesInUse.count > 0;
}

- (BOOL) hasEnumeration{
    return NO;
}

#pragma mark parsing

- (NSString*) targetClassFileName {
    return self.targetClassName;
}

- (NSString*) arrayType {
    NSDictionary* dict = [NSDictionary dictionaryWithObject: self forKey: @"type"];
    return [engine2 processTemplate: self.schema.complexTypeArrayType withVariables: dict];
}

- (id<XSType>) baseClass {
    id<XSType> rtn;
    id baseType = self.baseType;
    if(baseType != nil) {
        rtn = [self.schema typeForName:baseType];
    }
    
    return rtn;
}


- (NSString*)readSimpleContent {
    id baseType = self.baseType;
    NSMutableString *str = [NSMutableString stringWithString:@""];
    if(baseType != nil) {
        XSSimpleType *stype = [self.schema typeForName: baseType];
        assert(stype);
        if(stype != nil && [stype isKindOfClass:[XSSimpleType class]]) {
            id substr = [stype readPrefixCode];
            if(substr)
                [str appendString:substr];
            
            if(str.length)
                [str appendString:@"\n"];
            
            substr = [stype readValueCode];
            if(substr)
                [str appendString:substr];
        }
        else
            [str appendString:@"/*called by mistake*/"]; //:/ ?
    }

    return str;
}

- (NSDictionary*) substitutionDict {
    return [NSDictionary dictionaryWithObject:self forKey:@"type"];
}

- (NSString*) readCodeForElement:(XSDelement *)element {
    NSDictionary* dict = [NSDictionary dictionaryWithObject: element forKey: @"element"];
    return [engine processTemplate: self.schema.readComplexTypeElementTemplate withVariables: dict];
}

- (NSString*) readCodeForAttribute:(XSDattribute *)attribute {
    return @"/* cant have a complex attribute */";
}

- (NSString*)combinedReadPrefixCode {
    NSMutableOrderedSet *lines = [NSMutableOrderedSet orderedSetWithCapacity:self.simpleTypesInUse.count];
    for (XSSimpleType *t in self.simpleTypesInUse) {
        if(t.readPrefixCode) {
            [lines addObject:t.readPrefixCode];
        }
    }
    return [lines.array componentsJoinedByString:@"\n"];
}

#pragma mark bug

- (NSString*)enumerationName {
    return @"NONE";
}
@end
