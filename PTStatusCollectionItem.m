//
//  PTStatusCollectionItem.m
//  Pwitter
//
//  Created by Akihiro Noguchi on 26/12/08.
//  Copyright 2008 Aki. All rights reserved.
//

#import "PTStatusCollectionItem.h"
#import "PTStatusEntityView.h"
#import "PTStatusBox.h"

@implementation PTStatusCollectionItem

- (void)setSelected:(BOOL)flag {
	[super setSelected:flag];
	PTStatusEntityView* theView = (PTStatusEntityView* )[self view];
	if([theView isKindOfClass:[PTStatusEntityView class]]) {
		[theView setSelected:flag];
		[theView setNeedsDisplay:YES];
	}
}

- (void)setView:(NSView *)view {
	[(PTStatusEntityView *)view setColItem:self];
	[super setView:view];
}

- (id)initWithCoder:(NSCoder *)decoder {
	
	return [super initWithCoder:decoder];
}

@end
