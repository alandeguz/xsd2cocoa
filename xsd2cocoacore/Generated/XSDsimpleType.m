/*
	XSDsimpleType.h
	The implementation of properties and methods for the XSDsimpleType object.
	Generated by SudzC.com
*/
#import "XSDsimpleType.h"
#import "XSDNCName.h"
#import "XSDsimpleDerivationSet.h"

@implementation XSDsimpleType
	@synthesize final = _final;
	@synthesize name = _name;

	- (id) init
	{
		if(self = [super init])
		{
			self.final = nil; // [[XSDanySimpleType alloc] init];
			self.name = nil; // [[XSDanySimpleType alloc] init];

		}
		return self;
	}

	- (id) initWithNode: (NSXMLNode*) node {
		if(self = [super initWithNode: node])
		{
#pragma mark ?
			self.final = [[(id)[XSDsimpleDerivationSet alloc] initWithNode: [XMLUtils getNode: node withName: @"final"]] object];
			self.name = [[(id)[XSDNCName alloc] initWithNode: [XMLUtils getNode: node withName: @"name"]] object];
		}
		return self;
	}


@end