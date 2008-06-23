//
//  PreferencesController.m
//  AppFrost
//
//  Created by Jeremy Roman on 06/06/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PreferencesController.h"

@implementation PreferencesController

- (IBAction)setIconSize:(id)sender {
	[[NSUserDefaults standardUserDefaults] setInteger:[sender tag] forKey:@"iconSize"];
}

// NSMenu delegate methods
- (void)menuNeedsUpdate:(NSMenu *)menu {
	// If the tag is the icon size, it's active
	for(NSMenuItem *item in [menu itemArray]) {
		if([item tag] == [[NSUserDefaults standardUserDefaults] integerForKey:@"iconSize"]) {
			[item setState:NSOnState];
		} else {
			[item setState:NSOffState];
		}
	}
}

@end
