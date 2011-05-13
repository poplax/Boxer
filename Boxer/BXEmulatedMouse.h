/* 
 Boxer is copyright 2011 Alun Bestor and contributors.
 Boxer is released under the GNU General Public License 2.0. A full copy of this license can be
 found in this XCode project at Resources/English.lproj/BoxerHelp/pages/legalese.html, or read
 online at [http://www.gnu.org/licenses/gpl-2.0.txt].
 */


//BXEmulatedMouse represents the DOS PC's mouse and its driver, and offers an API for sending
//emulated mouse signals.

#import <Foundation/Foundation.h>
#import "BXEventConstants.h"


//How long buttonPressed: should pretend to hold the specified button down before releasing.
#define BXMouseButtonPressDurationDefault 0.25


@interface BXEmulatedMouse: NSObject
{
	BOOL active;
	NSPoint position;
	
	BXMouseButtonMask pressedButtons;
}


#pragma mark -
#pragma mark Properties

//Whether we are responding to mouse input.
@property (assign, getter=isActive) BOOL active;

//The current X and Y coordinates of the mouse relative to a 0.0-to-1.0 canvas.
//This is synchronised by DOSBox, as the DOS program may warp the mouse itself.
@property (assign) NSPoint position;


//Releases all mouse buttons, as if the user took their hand off the mouse.
- (void) clearInput;


#pragma mark -
#pragma mark Mouse input

//Press/release the specified mouse button.
- (void) buttonDown: (BXMouseButton)button;
- (void) buttonUp: (BXMouseButton)button;
- (BOOL) buttonIsDown: (BXMouseButton)button;

//Press the specified mouse button and then release it after the default/specified delay.
- (void) buttonPressed: (BXMouseButton)button;
- (void) buttonPressed: (BXMouseButton)button forDuration: (NSTimeInterval)duration;

//Move the mouse to a relative point on the specified canvas, by the relative delta.
//TODO: simplify this API to always use a 0.0-1.0 canvas.
- (void) movedTo: (NSPoint)point
			  by: (NSPoint)delta
		onCanvas: (NSRect)canvas
	 whileLocked: (BOOL)locked;

@end