//
//  AppFrostController.m
//  AppFrost
//
//  Created by Jeremy Roman on 06/06/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "AppFrostController.h"
#import "CUtils.h"
#import <signal.h>

@implementation AppFrostController

- (void)awakeFromNib {
	frozenApps = [[NSMutableArray alloc] init];
	coreMenuCount = [menu numberOfItems];
	statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
	[self setTitleColor:nil];
	[statusItem setMenu:menu];
	[statusItem setHighlightMode:YES];
	[statusItem setEnabled:YES];
}

- (void)dealloc {
	[frozenApps release];
	[statusItem release];
	[focusedApp release];
	[super dealloc];
}

- (void)setTitleColor:(NSColor *)color {
	// Define the title as the snowflake from the system font
	NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
								[NSFont systemFontOfSize:20], NSFontAttributeName,
								color, NSForegroundColorAttributeName, nil];
	NSMutableAttributedString *title = [[NSMutableAttributedString alloc]
										initWithString:[NSString stringWithFormat:@"%C",0x2744]
										attributes: attributes];
	
	[statusItem setAttributedTitle:title];
}

// Triggered when an application is chosen
- (void)toggleApplication:(id)sender {
	// If Option is pressed, trigger "Toggle Others" instead
	if([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) {
		[self toggleOthers:[sender representedObject]];
		return;
	}
	
	int pid = [[[sender representedObject] objectForKey:@"NSApplicationProcessIdentifier"] intValue];
	
	// If not frozen, freeze
	if(![frozenApps containsObject:[sender representedObject]]) {
		NSString *command = [NSString stringWithFormat:@"osascript -e 'tell application \"System Events\" to set visible of"
								" first application process whose unix id is %d to false'", pid];
		//system([command UTF8String]);
		[frozenApps addObject:[sender representedObject]];
		kill(pid, SIGSTOP);
	} else {
		kill(pid, SIGCONT);
		[frozenApps removeObject:[sender representedObject]];
		NSString *command = [NSString stringWithFormat:@"osascript -e 'tell application \"System Events\" to set visible of"
							 "first application process whose unix id is %d to true'", pid];
		//system([command UTF8String]);
	}
}

- (void)toggleOthers:(NSDictionary *)app {
	// If we're already "focusing" on this app, defrost all
	if([app isEqual:focusedApp]) {
		[self defrostAll:nil];
	
	// If we aren't already focusing, do so now.
	} else {
		focusedApp = [app retain];
		NSArray *apps = [[NSWorkspace sharedWorkspace] launchedApplications];
		for (NSDictionary *app in apps) {
			// Don't freeze AppFrost, Finder, or the focused application
			if([[app objectForKey:@"NSApplicationProcessIdentifier"] intValue] == [[NSProcessInfo processInfo] processIdentifier]) continue;
			if([[app objectForKey:@"NSApplicationPath"] isEqual:@"/System/Library/CoreServices/Finder.app"]) continue;
			if([app isEqual:focusedApp]) {
				// Ensure that the focused app is not frozen
				int pid = [[focusedApp objectForKey:@"NSApplicationProcessIdentifier"] intValue];
				NSString *command = [NSString stringWithFormat:@"osascript -e 'tell application \"System Events\" to set visible of"
									 " first application process whose unix id is %d to true'", pid];
				//system([command UTF8String]);
				kill(pid, SIGCONT);
				[frozenApps removeObject:app];
				continue;
			}
			
			int pid = [[app objectForKey:@"NSApplicationProcessIdentifier"] intValue];
			NSString *command = [NSString stringWithFormat:@"osascript -e 'tell application \"System Events\" to set visible of"
								 " first application process whose unix id is %d to false'", pid];
			//system([command UTF8String]);
			[frozenApps addObject:app];
			kill(pid, SIGSTOP);
		}
	}
}

- (IBAction)defrostAll:(id)sender {
	// Send SIGCONT to all foreground applications except Finder and AppFrost
	// also: clear the frozenApps list
	NSArray *apps = [[NSWorkspace sharedWorkspace] launchedApplications];
	for (NSDictionary *app in apps) {
		if([[app objectForKey:@"NSApplicationProcessIdentifier"] intValue] == [[NSProcessInfo processInfo] processIdentifier]) continue;
		if([[app objectForKey:@"NSApplicationPath"] isEqual:@"/System/Library/CoreServices/Finder.app"]) continue;
		
		int pid = [[app objectForKey:@"NSApplicationProcessIdentifier"] intValue];
		kill(pid, SIGCONT);
		NSString *command = [NSString stringWithFormat:@"osascript -e 'tell application \"System Events\" to set visible of"
							 " first application process whose unix id is %d to true'", pid];
		//system([command UTF8String]);
	}
	
	[frozenApps removeAllObjects];
	[focusedApp release];
	focusedApp = nil;
}

// NSMenu delegate methods
- (void)menuWillOpen:(NSMenu *)_menu {
	[self setTitleColor:[NSColor whiteColor]];
}

- (void)menuDidClose:(NSMenu *)_menu {
	[self setTitleColor:nil];
}

- (void)menuNeedsUpdate:(NSMenu *)_menu {
	// Remove application list
	NSMenuItem *item;
	while ([menu numberOfItems] > coreMenuCount) {
		[menu removeItemAtIndex:0];
	}
	
	// Add new application list
	NSArray *apps = [[[NSWorkspace sharedWorkspace] launchedApplications] sortedArrayUsingFunction:compareNSApplicationName context:NULL];
	int index = 0;
	for (NSDictionary *app in apps) {
		// Don't allow freezing Finder or AppFrost
		if([[app objectForKey:@"NSApplicationProcessIdentifier"] intValue] == [[NSProcessInfo processInfo] processIdentifier]) continue;
		
		item = [menu insertItemWithTitle:[app objectForKey:@"NSApplicationName"]
								  action:@selector(toggleApplication:) keyEquivalent:@"" atIndex:index++];
		NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:[app objectForKey:@"NSApplicationPath"]];
		int iconSize = [[NSUserDefaults standardUserDefaults] integerForKey:@"iconSize"];;
		[icon setSize:NSMakeSize(iconSize, iconSize)];
		[item setImage:icon];
		[item setRepresentedObject:app];
		[item setTarget:self];
		[item setState:([frozenApps containsObject:app] ? NSOnState : NSOffState)];
		
		if([[app objectForKey:@"NSApplicationPath"] isEqual:@"/System/Library/CoreServices/Finder.app"]) [item setTarget:@""];
	}
}

// NSApplication delegate methods

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
	// Register default preferences
	[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:24] forKey:@"iconSize"]];
	
	// Send SIGSTOP and SIGCONT to all foreground applications except Finder and AppFrost
	NSArray *apps = [[NSWorkspace sharedWorkspace] launchedApplications];
	for (NSDictionary *app in apps) {
		if([[app objectForKey:@"NSApplicationProcessIdentifier"] intValue] == [[NSProcessInfo processInfo] processIdentifier]) continue;
		if([[app objectForKey:@"NSApplicationPath"] isEqual:@"/System/Library/CoreServices/Finder.app"]) continue;
		
		pid_t pid = [[app objectForKey:@"NSApplicationProcessIdentifier"] intValue];
		//kill(pid, SIGSTOP);
		kill(pid, SIGCONT);
	}
}

- (void)applicationWillTerminate:(NSNotification *)notification {
	[self defrostAll:nil];
}

@end
