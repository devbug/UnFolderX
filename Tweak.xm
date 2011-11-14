//
//  UnFolderX
//  
//  
//  Copyright (c) 2011 deVbug
//  
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//  
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import <UIKit/UIKit.h>
#include "objc/runtime.h"


#define ALERTVIEW_TAG					20111114
#define MAX_HOMESCREEN_PAGES			12



@interface SBIconView : UIView
- (id)icon;
- (id)iconImageView;
- (int)location;
- (void)setLocation:(int)fp8;
- (void)setShowsCloseBox:(BOOL)flag animated:(BOOL)animated;
@end

@interface SBFolder : NSObject
- (id)lists;
- (BOOL)isNewsstandFolder;
- (id)listAtIndex:(unsigned int)fp8;
- (void)removeIconAtIndexPath:(id)fp8;
- (id)allIcons;
- (id)leafIcons;
- (id)iconAtIndexPath:(id)fp8;
@end

@interface SBRootFolder : SBFolder
@end

@interface SBIcon : NSObject
- (NSString *)displayName;
@end

@interface SBFolderIcon : SBIcon
- (SBFolder *)folder;
@end

@interface SBApplication : NSObject
- (NSString *)displayIdentifier;
@end

@interface SBApplicationIcon : SBIcon
- (SBApplication *)application;
@end


@interface SBIconListModel : NSObject
- (SBFolder *)folder;
- (NSMutableArray *)icons;
- (unsigned int)firstFreeSlotIndex;
- (void)removeIconAtIndex:(unsigned int)fp8;
- (void)removeIcon:(id)fp8;
@end

@interface SBIconListView : UIView
+ (unsigned int)maxIcons;
- (SBIconListModel *)model;
- (unsigned int)firstFreeSlotIndex;
- (id)placeIcon:(id)fp8 atIndex:(unsigned int)fp12 moveNow:(BOOL)fp16 pop:(BOOL)fp20;
- (id)insertIcon:(id)fp8 atIndex:(unsigned int)fp12 moveNow:(BOOL)fp16 pop:(BOOL)fp20;
- (id)insertIcon:(id)fp8 atIndex:(unsigned int)fp12 moveNow:(BOOL)fp16;
- (void)removeIconAtIndex:(unsigned int)fp8;
- (void)removeIcon:(id)fp8;
- (void)layoutIconsNow;
@end

@interface SBIconController : NSObject
+ (id)sharedInstance;
- (SBIconListView *)rootIconListAtIndex:(int)fp8;
- (SBIconListView *)folderIconListAtIndex:(unsigned int)fp8;
- (SBIconListView *)currentRootIconList;
- (SBIconListView *)currentFolderIconList;
- (int)currentIconListIndex;
- (void)removeEmptyIconList:(id)fp8 animate:(BOOL)fp12;
- (void)removeIcon:(id)fp8 andCompactFolder:(BOOL)fp12 folderRef:(id *)fp16;
- (void)removeIcon:(id)fp8 compactFolder:(BOOL)fp12;
@end




@interface UnFolderXAlertDelegate : NSObject <UIAlertViewDelegate> {
	SBIcon *icon;
}
- (id)initWithSBIcon:(SBIcon *)_icon;
- (void)alertView:(UIAlertView *)aView clickedButtonAtIndex:(NSInteger)anIndex;
@end

@implementation UnFolderXAlertDelegate

- (id)initWithSBIcon:(SBIcon *)_icon {
	if ((self = [super init]) != nil)
		icon = [_icon retain];
	return self;
}

- (void)alertView:(UIAlertView *)aView clickedButtonAtIndex:(NSInteger)anIndex {
	if (anIndex == 0) {
		SBIconController *iconController = [objc_getClass("SBIconController") sharedInstance];
		
		SBIconListModel *folderListModel = [[[(SBFolderIcon *)icon folder] lists] objectAtIndex:0];
		
		NSUInteger currentIconListIndex = [iconController currentIconListIndex];
		// homescreen's default is 16
		NSUInteger maxIcons = [objc_getClass("SBIconListView") maxIcons];
		
		SBIconListView *currentRootIconList = [iconController currentRootIconList];
		SBIconListView *tempIconList = currentRootIconList;
		if (currentIconListIndex == 0)
			tempIconList = [iconController rootIconListAtIndex:(++currentIconListIndex)];
		
		for (SBIcon *ticon in [[(SBFolderIcon *)icon folder] allIcons]) {
			// zero base index
			NSUInteger firstFreeSlotIndex = [tempIconList firstFreeSlotIndex];
			
			while (maxIcons <= firstFreeSlotIndex) {
				currentIconListIndex++;
				tempIconList = [iconController rootIconListAtIndex:currentIconListIndex];
				firstFreeSlotIndex = [tempIconList firstFreeSlotIndex];
				
				if (currentIconListIndex > MAX_HOMESCREEN_PAGES-1) break;
			}
			
			if (currentIconListIndex > MAX_HOMESCREEN_PAGES-1) break;
			
			[folderListModel removeIcon:ticon];
			[tempIconList insertIcon:ticon atIndex:firstFreeSlotIndex moveNow:YES];
			[tempIconList placeIcon:ticon atIndex:firstFreeSlotIndex moveNow:YES pop:YES];
		}
		
		if (currentIconListIndex <= MAX_HOMESCREEN_PAGES-1)
			[iconController removeIcon:icon compactFolder:YES];
	}
	
	[icon release];
	icon = nil;
}

- (void)dealloc {
	[icon release];
	[super dealloc];
}

@end


static UnFolderXAlertDelegate *unFolderXDelegate = nil;
static NSBundle *unFolderXBundle = nil;


%hook SBIconController

- (void)setIsEditing:(BOOL)isEditing {
	if (isEditing == 0) {
		UIApplication *application = [UIApplication sharedApplication];
		for (UIWindow *window in application.windows) {
			UIView *view = [window viewWithTag:ALERTVIEW_TAG];
			
			if ([view isKindOfClass:[UIAlertView class]]) {
				UIAlertView *tview = (UIAlertView *)view;
				[tview dismissWithClickedButtonIndex:1 animated:NO];
				[tview.delegate alertView:tview clickedButtonAtIndex:1];
				break;
			}
		}
	}
	
	%orig;
}

%end


%hook SBIconView

- (void)setIsJittering:(BOOL)isJittering {
	%orig;

	if (isJittering != 0) {
		if ([[self icon] isKindOfClass:[objc_getClass("SBFolderIcon") class]]) {
			if (![[(SBFolderIcon *)[self icon] folder] isNewsstandFolder])
				[self setShowsCloseBox:1 animated:1];
		}
	}
}

- (void)closeBoxTapped {
	if ([[self icon] isKindOfClass:[objc_getClass("SBFolderIcon") class]] && 
		![[(SBFolderIcon *)[self icon] folder] isNewsstandFolder] &&
		([self location] == 0 || [self location] == 1)) 
	{
		SBIconController *iconController = [objc_getClass("SBIconController") sharedInstance];
		
		// this must do when folder is close.
		if ([iconController currentFolderIconList] != nil) return;
		
		[unFolderXDelegate release];
		unFolderXDelegate = [[UnFolderXAlertDelegate alloc] initWithSBIcon:[self icon]];
		
		if (unFolderXBundle == nil)
			unFolderXBundle = [[NSBundle alloc] initWithPath:@"/Library/Application Support/UnFolderX"];
		
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:(unFolderXBundle ? [unFolderXBundle localizedStringForKey:@"ALERT_MSG" value:@"Do you really want to unfolder?" table:@"UnFolderX"] : @"Do you really want to unfolder?") 
															message:[(SBFolderIcon *)[self icon] displayName] 
														   delegate:unFolderXDelegate 
												  cancelButtonTitle:(unFolderXBundle ? [unFolderXBundle localizedStringForKey:@"YES" value:@"Yes" table:@"UnFolderX"] : @"Yes") 
												  otherButtonTitles:(unFolderXBundle ? [unFolderXBundle localizedStringForKey:@"NO" value:@"No" table:@"UnFolderX"] : @"No"), nil];
		alertView.tag = ALERTVIEW_TAG;
		[alertView show];
		[alertView release];
	} else 
		%orig;
}

%end

