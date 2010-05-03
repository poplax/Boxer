/* 
 Boxer is copyright 2010 Alun Bestor and contributors.
 Boxer is released under the GNU General Public License 2.0. A full copy of this license can be
 found in this XCode project at Resources/English.lproj/GNU General Public License.txt, or read
 online at [http://www.gnu.org/licenses/gpl-2.0.txt].
 */


#import "BXStatusBarController.h"
#import "BXAppController.h"
#import "BXSessionWindowController+BXRenderController.h"
#import "BXSessionWindowController+BXInputController.h"
#import "BXRenderViewController.h"
#import "BXInspectorController.h"
#import "BXSession.h"
#import "BXEmulator.h"
#import "BXRenderView.h"

@implementation BXStatusBarController

- (BXSessionWindowController *)windowController
{
	return (BXSessionWindowController *)[[[self view] window] windowController];
}
- (void) awakeFromNib
{
	//Give statusbar text an indented appearance
	[[notificationMessage cell] setBackgroundStyle: NSBackgroundStyleRaised];
	
	BXSessionWindowController *windowController = [self windowController];
	BXAppController *appController = (BXAppController *)[NSApp delegate];
	
	//Observe changes that will affect our segmented button states
	[appController addObserver: self
					forKeyPath: @"inspectorPanelShown"
					   options: NSKeyValueObservingOptionInitial
					   context: nil];
	
	[windowController addObserver: self
					   forKeyPath: @"programPanelShown"
						  options: NSKeyValueObservingOptionInitial
						  context: nil];

	[windowController addObserver: self
					   forKeyPath: @"document.isGamePackage"
						  options: NSKeyValueObservingOptionInitial
						  context: nil];
	
	[windowController addObserver: self
					   forKeyPath: @"renderViewController.mouseLocked"
						  options: NSKeyValueObservingOptionInitial
						  context: nil];
	
	[windowController addObserver: self
					   forKeyPath: @"renderViewController.mouseActive"
						  options: NSKeyValueObservingOptionInitial
						  context: nil];
	
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(_preventOverlappingStatusItems)
												 name: @"NSViewFrameDidChangeNotification"
											   object: [self view]];
}

- (IBAction) performSegmentedButtonAction: (id)sender
{
	BXSessionWindowController *controller = [self windowController];
	BOOL mouseLocked = [[controller renderViewController] mouseLocked];
	
	//Because we have no easy way of telling which segment was just toggled, just synchronise them all
	
	if ([sender isSelectedForSegment: BXStatusBarInspectorSegment] != [[NSApp delegate] inspectorPanelShown])
	{
		[[NSApp delegate] toggleInspectorPanel: sender];
	}
	
	if ([sender isSelectedForSegment: BXStatusBarProgramPanelSegment] != [controller programPanelShown])
	{
		[controller toggleProgramPanelShown: sender];
	}
	
	if ([sender isSelectedForSegment: BXStatusBarMouseLockSegment] != mouseLocked)
	{
		[[controller renderViewController] toggleMouseLocked: sender];		
	}
	
	[self _syncSegmentedButtonStates];
}


//Whenever the represented icon changes, force a redraw of our icon view
- (void) observeValueForKeyPath: (NSString *)keyPath
					   ofObject: (id)object
						 change: (NSDictionary *)change
						context: (void *)context
{
	[self _syncSegmentedButtonStates];
}

+ (NSSet *) keyPathsForValuesAffectingNotificationText
{
	return [NSSet setWithObjects:
			@"windowController.renderViewController.mouseActive",
			@"windowController.renderViewController.mouseLocked",
			@"windowController.renderViewController.mouseInView",
			nil];
}

- (NSString *) notificationText
{
	BXRenderViewController *viewController = [[self windowController] renderViewController];
	if ([viewController mouseActive])
	{
		if ([viewController mouseLocked])	return NSLocalizedString(@"Cmd-click to release the mouse.",
																	 @"Statusbar message when mouse is locked");
		if ([viewController mouseInView])	return NSLocalizedString(@"Cmd-click to lock the mouse to the window.",
																	 @"Statusbar message when mouse is unlocked and over DOS viewport");
	}
	return @"";
}

- (void) _preventOverlappingStatusItems
{
	//Hide the notification text if it overlaps the button
	[notificationMessage setHidden: NSIntersectsRect([notificationMessage frame], [statusBarControls frame])];
}

- (void) _syncSegmentedButtonStates
{
	BXSessionWindowController *windowController	= [self windowController];
	BXRenderViewController *viewController		= [windowController renderViewController];
	
	[statusBarControls setSelected: [[NSApp delegate] inspectorPanelShown]	forSegment: BXStatusBarInspectorSegment];
	[statusBarControls setSelected: [windowController programPanelShown]	forSegment: BXStatusBarProgramPanelSegment];
	[statusBarControls setSelected: [viewController mouseLocked]			forSegment: BXStatusBarMouseLockSegment];
	
	[statusBarControls setEnabled:	[[windowController document] isGamePackage]	forSegment: BXStatusBarProgramPanelSegment];
	[statusBarControls setEnabled:	[viewController mouseActive]				forSegment: BXStatusBarMouseLockSegment];
	
	NSString *panelButtonImage;
	if ([statusBarControls isSelectedForSegment: BXStatusBarProgramPanelSegment])
			panelButtonImage = @"PanelCollapseTemplate.png";
	else	panelButtonImage = @"PanelExpandTemplate.png";
	[statusBarControls setImage: [NSImage imageNamed: panelButtonImage] forSegment: BXStatusBarProgramPanelSegment];
	
	NSString *lockButtonImage;
	if ([statusBarControls isSelectedForSegment: BXStatusBarMouseLockSegment])
			lockButtonImage = @"NSLockLockedTemplate";
	else	lockButtonImage = @"NSLockUnlockedTemplate";
	[statusBarControls setImage: [NSImage imageNamed: lockButtonImage] forSegment: BXStatusBarMouseLockSegment];
}
@end