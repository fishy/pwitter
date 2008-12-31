//
//  PTPreferenceWindow.m
//  Pwitter
//
//  Created by Akihiro Noguchi on 26/12/08.
//  Copyright 2008 Aki. All rights reserved.
//

#import "PTPreferenceWindow.h"
#import "PTPreferenceManager.h"
#import "PTMain.h"

@implementation PTPreferenceWindow

- (void)loadPreferences {
	NSString *tempUserName = [[PTPreferenceManager getInstance] getUserName];
	if (tempUserName == nil) tempUserName = [[NSString alloc] init];
	[userName setStringValue:tempUserName];
	if ([[PTPreferenceManager getInstance] alwaysOnTop]) {
		[alwaysOnTop setState:NSOnState];
	} else {
		[alwaysOnTop setState:NSOffState];
	}
	[timeInterval selectItemAtIndex:[[PTPreferenceManager getInstance] timeInterval] - 1];
	[password setStringValue:[[NSString alloc] init]];
	[mainWindow setFloatingPanel:[[PTPreferenceManager getInstance] alwaysOnTop]];
}

- (IBAction)pressOK:(id)sender {
	if ([alwaysOnTop state] == NSOnState) {
		[[PTPreferenceManager getInstance] setAlwaysOnTop:YES];
	} else {
		[[PTPreferenceManager getInstance] setAlwaysOnTop:NO];
	}
	if ([[PTPreferenceManager getInstance] timeInterval] != [timeInterval indexOfSelectedItem] + 1) {
		[[PTPreferenceManager getInstance] setTimeInterval:[timeInterval indexOfSelectedItem] + 1];
		[mainController setupUpdateTimer];
	}
	if ([[password stringValue] length] != 0) {
		[[PTPreferenceManager getInstance] setUserName:[userName stringValue]];
		[[PTPreferenceManager getInstance] savePassword:[password stringValue]];
		[mainController changeAccount];
	}
	[mainWindow setFloatingPanel:[[PTPreferenceManager getInstance] alwaysOnTop]];
	[NSApp endSheet:self];
}

- (IBAction)pressCancel:(id)sender {
    [self loadPreferences];
	[NSApp endSheet:self];
}

@end
