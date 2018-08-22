#include "NBLRootListController.h"
#include "NBLWhitelistController.h"

@implementation NBLRootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"Root" target:self] retain];
	}

	return _specifiers;
}

@end
