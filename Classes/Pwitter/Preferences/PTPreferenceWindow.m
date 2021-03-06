//
//  PTPreferenceWindow.m
//  Pwitter
//
//  Created by Akihiro Noguchi on 26/12/08.
//  Copyright 2008 Aki. All rights reserved.
//

#import "PTPreferenceWindow.h"
#import "PTPreferenceManager.h"
#import "PTHotKeyCenter.h"
#import "PTMain.h"
#import "PTMainActionHandler.h"
#import <Growl/GrowlApplicationBridge.h>


@implementation PTPreferenceWindow

- (void)loadPreferences {
	NSString *lTempUserName = [[PTPreferenceManager sharedSingleton] userName];
	if (lTempUserName == nil) lTempUserName = @"";
	[fUserName setStringValue:lTempUserName];
	[fTimeInterval selectItemAtIndex:[[PTPreferenceManager sharedSingleton] timeInterval] - 1];
	[fMessageUpdateInterval selectItemAtIndex:[[PTPreferenceManager sharedSingleton] messageInterval] - 1];
	[fBehaviorAfterUpdate selectItemAtIndex:[[PTPreferenceManager sharedSingleton] statusUpdateBehavior] - 1];
	[fStatusController setSelectsInsertedObjects:[[PTPreferenceManager sharedSingleton] statusUpdateBehavior] == 1];
	[fPassword setStringValue:@""];
	[fMainWindow setFloatingPanel:[[PTPreferenceManager sharedSingleton] alwaysOnTop]];
	[fMainWindow setHasShadow:![[PTPreferenceManager sharedSingleton] disableWindowShadow]];
	[[PTPreferenceManager sharedSingleton] hideDockIcon] ? [fHideDockIcon setState:NSOnState] : [fHideDockIcon setState:NSOffState];
	if ([[PTPreferenceManager sharedSingleton] disableGrowl]) {
		[fDisableMessageNotification setEnabled:NO];
		[fDisableStatusNotification setEnabled:NO];
		[fDisableReplyNotification setEnabled:NO];
		[fDisableErrorNotification setEnabled:NO];
	}
	if (![GrowlApplicationBridge isGrowlRunning]) {
		[fDisableGrowl setEnabled:NO];
		[fDisableMessageNotification setEnabled:NO];
		[fDisableStatusNotification setEnabled:NO];
		[fDisableReplyNotification setEnabled:NO];
		[fDisableErrorNotification setEnabled:NO];
	}
	[[fMainController fMenuItem] setSwapped:[[PTPreferenceManager sharedSingleton] swapMenuItemBehavior]];
	// load key combination
	[self loadKeyCombo];
	[self turnOffHotKey];
	[fShortcutRecorder setEnabled:NO];
	[fQuickReadShortcutRecorder setEnabled:NO];
	[fHideWhenReading setEnabled:NO];
	if ([[PTPreferenceManager sharedSingleton] quickPost]) {
		[fShortcutRecorder setEnabled:YES];
		[self turnOnHotKey];
	}
	if ([[PTPreferenceManager sharedSingleton] quickRead]) {
		[fQuickReadShortcutRecorder setEnabled:YES];
		[fHideWhenReading setEnabled:YES];
		[self turnOnReadHotKey];
	}
	[fMainWindow setHidesOnDeactivate:[[PTPreferenceManager sharedSingleton] hideOnDeactivate]];
}

- (IBAction)pressOK:(id)sender {
	if ([[PTPreferenceManager sharedSingleton] ignoreErrors])
		[fMainActionHandler clearErrors:sender];
	if ([[PTPreferenceManager sharedSingleton] timeInterval] != [fTimeInterval indexOfSelectedItem] + 1) {
		[[PTPreferenceManager sharedSingleton] setTimeInterval:[fTimeInterval indexOfSelectedItem] + 1];
		[fMainController setupUpdateTimer];
	}
	if ([[PTPreferenceManager sharedSingleton] messageInterval] != [fMessageUpdateInterval indexOfSelectedItem] + 1) {
		[[PTPreferenceManager sharedSingleton] setMessageInterval:[fMessageUpdateInterval indexOfSelectedItem] + 1];
		[fMainController setupMessageUpdateTimer];
	}
	if ([[PTPreferenceManager sharedSingleton] statusUpdateBehavior] != [fBehaviorAfterUpdate indexOfSelectedItem] + 1) {
		[[PTPreferenceManager sharedSingleton] setStatusUpdateBehavior:[fBehaviorAfterUpdate indexOfSelectedItem] + 1];
	}
	if ([[fPassword stringValue] length] != 0) {
		[[PTPreferenceManager sharedSingleton] setUserName:[fUserName stringValue] 
											  password:[fPassword stringValue]];
		fShouldReset = YES;
	}
	if ([[PTPreferenceManager sharedSingleton] statusUpdateBehavior] == 1) {
		[fStatusController setSelectsInsertedObjects:YES];
	} else {
		[fStatusController setSelectsInsertedObjects:NO];
	}
	if ([[PTPreferenceManager sharedSingleton] hideDockIcon] != ([fHideDockIcon state] == NSOnState))
		[[PTPreferenceManager sharedSingleton] setHideDockIcon:[fHideDockIcon state] == NSOnState];
	[fMainWindow setFloatingPanel:[[PTPreferenceManager sharedSingleton] alwaysOnTop]];
	[fMainWindow setHasShadow:![[PTPreferenceManager sharedSingleton] disableWindowShadow]];
	[[fMainController fMenuItem] setSwapped:[[PTPreferenceManager sharedSingleton] swapMenuItemBehavior]];
	[fMainWindow setHidesOnDeactivate:[[PTPreferenceManager sharedSingleton] hideOnDeactivate]];
	[self saveKeyCombo];
	[self turnOffHotKey];
	if ([[PTPreferenceManager sharedSingleton] quickPost])
		[self turnOnHotKey];
	if ([[PTPreferenceManager sharedSingleton] quickRead])
		[self turnOnReadHotKey];
	[NSApp endSheet:self];
	if (fShouldReset) [fMainController changeAccount:self];
	fShouldReset = NO;
}

- (void)turnOffHotKey {
	[fShortcutRecorder setCanCaptureGlobalHotKeys:NO];
	[fQuickReadShortcutRecorder setCanCaptureGlobalHotKeys:NO];
	if (fHotKey != nil) {
		[[PTHotKeyCenter sharedCenter] unregisterHotKey: fHotKey];
		[fHotKey release];
		fHotKey = nil;
	}
	if (fHotKeyRead != nil) {
		[[PTHotKeyCenter sharedCenter] unregisterHotKey: fHotKeyRead];
		[fHotKeyRead release];
		fHotKeyRead = nil;
	}
}

- (void)turnOnHotKey {
	[fShortcutRecorder setCanCaptureGlobalHotKeys:YES];
	fHotKey = [[PTHotKey alloc] initWithIdentifier:@"ActivateQuickPost" 
										  keyCombo:[PTKeyCombo keyComboWithKeyCode:[(SRRecorderControl *)fShortcutRecorder keyCombo].code 
																		 modifiers:[(SRRecorderControl *)fShortcutRecorder cocoaToCarbonFlags:[(SRRecorderControl *)fShortcutRecorder keyCombo].flags]]];
	[fHotKey setTarget: self];
	[fHotKey setAction: @selector(hitKey:)];
	[[PTHotKeyCenter sharedCenter] registerHotKey: fHotKey];
}

- (void)turnOnReadHotKey {
	[fQuickReadShortcutRecorder setCanCaptureGlobalHotKeys:YES];
	fHotKeyRead = [[PTHotKey alloc] initWithIdentifier:@"ActivateQuickRead" 
										  keyCombo:[PTKeyCombo keyComboWithKeyCode:[(SRRecorderControl *)fQuickReadShortcutRecorder keyCombo].code 
																		 modifiers:[(SRRecorderControl *)fQuickReadShortcutRecorder cocoaToCarbonFlags:[(SRRecorderControl *)fQuickReadShortcutRecorder keyCombo].flags]]];
	[fHotKeyRead setTarget: self];
	[fHotKeyRead setAction: @selector(hitReadKey:)];
	[[PTHotKeyCenter sharedCenter] registerHotKey: fHotKeyRead];
}

- (void)saveKeyCombo {
	KeyCombo lTempKeyCode = [(SRRecorderControl*)fShortcutRecorder keyCombo];
	id lValues = [[NSUserDefaultsController sharedUserDefaultsController] values];
	NSDictionary *lDefValue = [NSDictionary dictionaryWithObjectsAndKeys: 
							   [NSNumber numberWithShort:lTempKeyCode.code], @"keyCode", 
							   [NSNumber numberWithUnsignedInt:lTempKeyCode.flags], @"modifierFlags", 
							   nil];
	[lValues setValue:lDefValue forKey:@"quick_post_activation_key"];
	lTempKeyCode = [(SRRecorderControl*)fQuickReadShortcutRecorder keyCombo];
	lDefValue = [NSDictionary dictionaryWithObjectsAndKeys: 
				  [NSNumber numberWithShort:lTempKeyCode.code], @"keyCode", 
				  [NSNumber numberWithUnsignedInt:lTempKeyCode.flags], @"modifierFlags", 
				  nil];
	[lValues setValue:lDefValue forKey:@"quick_read_activation_key"];
}

- (void)loadKeyCombo
{
	id lValued = [[NSUserDefaultsController sharedUserDefaultsController] values];
	NSDictionary *lSavedCombo = [lValued valueForKey:@"quick_post_activation_key"];
	signed short lKeyCode = [[lSavedCombo valueForKey:@"keyCode"] shortValue];
	unsigned int lFlags = [[lSavedCombo valueForKey:@"modifierFlags"] unsignedIntValue];
	if (lKeyCode == 0 && lFlags == 0) return;
	KeyCombo keyCombo;
	keyCombo.code = lKeyCode;
	keyCombo.flags = lFlags;
	[(SRRecorderControl *)fShortcutRecorder setKeyCombo:keyCombo];
	lSavedCombo = [lValued valueForKey:@"quick_read_activation_key"];
	lKeyCode = [[lSavedCombo valueForKey:@"keyCode"] shortValue];
	lFlags = [[lSavedCombo valueForKey:@"modifierFlags"] unsignedIntValue];
	if (lKeyCode == 0 && lFlags == 0) return;
	keyCombo.code = lKeyCode;
	keyCombo.flags = lFlags;
	[(SRRecorderControl *)fQuickReadShortcutRecorder setKeyCombo:keyCombo];
}

- (void)hitKey:(PTHotKey *)aHotKey {
	[NSApp activateIgnoringOtherApps:YES];
	[fMainWindow makeKeyAndOrderFront:self];
	[fPostTextField selectText:self];
}

- (void)hitReadKey:(PTHotKey *)aHotKey {
	if ([[PTPreferenceManager sharedSingleton] hideWithQuickReadShortcut] && 
		[NSApp isActive] && [fMainWindow firstResponder] == fStatusCollectionView)
		[NSApp hide:self];
	else {
		[NSApp activateIgnoringOtherApps:YES];
		[fMainWindow makeKeyAndOrderFront:self];
		[fMainWindow makeFirstResponder:fStatusCollectionView];
		if ([[PTPreferenceManager sharedSingleton] selectOldestUnread])
			[fStatusCollectionView selectOldestUnread];
	}
}

- (IBAction)quickPostChanged:(id)sender {
	[fShortcutRecorder setEnabled:[sender state]];
}

- (IBAction)growlDisabled:(id)sender {
    if ([fDisableGrowl state]) {
		[fDisableMessageNotification setEnabled:NO];
		[fDisableStatusNotification setEnabled:NO];
		[fDisableReplyNotification setEnabled:NO];
		[fDisableErrorNotification setEnabled:NO];
	} else {
		[fDisableMessageNotification setEnabled:YES];
		[fDisableStatusNotification setEnabled:YES];
		[fDisableReplyNotification setEnabled:YES];
		[fDisableErrorNotification setEnabled:YES];
	}
}

-(void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
	int lTargetHeight;
	switch ([[tabViewItem identifier] intValue]) {
		case 1:
			lTargetHeight = 387;
			break;
		case 2:
			lTargetHeight = 293;
			break;
		case 3:
			lTargetHeight = 387;
			break;
		case 4:
			lTargetHeight = 322;
			break;
		default:
			lTargetHeight = 387;
			break;
	}
	NSRect lNewFrame = [self frame];
	lNewFrame.origin.y += lNewFrame.size.height - lTargetHeight;
	lNewFrame.size.height = lTargetHeight;
	[NSAnimationContext beginGrouping];
	[[NSAnimationContext currentContext]setDuration: 0.2];
	[[self animator] setFrame:lNewFrame display:YES];
	[NSAnimationContext endGrouping];
}

- (IBAction)quickReadChanged:(id)sender {
    [fQuickReadShortcutRecorder setEnabled:[sender state]];
	[fHideWhenReading setEnabled:[sender state]];
	[fSelectOldestUnread setEnabled:[sender state]];
}

- (IBAction)resetTimeline:(id)sender {
    fShouldReset = YES;
}


@end
