//
//  AppFrostController.h
//  AppFrost
//
//  Created by Jeremy Roman on 06/06/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AppFrostController : NSObject {
	int coreMenuCount;
	IBOutlet NSMenu *menu;
	NSStatusItem *statusItem;
	NSMutableArray *frozenApps;
	NSDictionary *focusedApp; // used for "freeze others"
}

- (void)setTitleColor:(NSColor *)color;
- (void)toggleApplication:(id)sender;
- (void)toggleOthers:(NSDictionary *)app;
- (IBAction)defrostAll:(id)sender;

@end
