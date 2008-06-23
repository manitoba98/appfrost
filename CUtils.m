/*
 *  CUtils.c
 *  AppFrost
 *
 *  Created by Jeremy Roman on 06/06/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#include "CUtils.h"

// For use later: compare's NSApplicationName keys
NSUInteger compareNSApplicationName(id app1, id app2, void *context) {
	return [[app1 objectForKey:@"NSApplicationName"] caseInsensitiveCompare:[app2 objectForKey:@"NSApplicationName"]];
}