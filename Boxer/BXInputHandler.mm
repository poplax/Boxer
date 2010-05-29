/* 
 Boxer is copyright 2010 Alun Bestor and contributors.
 Boxer is released under the GNU General Public License 2.0. A full copy of this license can be
 found in this XCode project at Resources/English.lproj/GNU General Public License.txt, or read
 online at [http://www.gnu.org/licenses/gpl-2.0.txt].
 */


#import "BXInputHandler.h"
#import "BXEmulator.h"

#import "BXEventConstants.h"
#import <Carbon/Carbon.h>	//For OSX keycode constants
#import <SDL/SDL.h>			//For SDL keycode constants
#import "config.h"
#import "video.h"
#import "mouse.h"
#import "sdlmain.h"


//Declared in mapper.cpp
void MAPPER_CheckEvent(SDL_Event *event);

@implementation BXInputHandler
@synthesize emulator;
@synthesize mouseActive;
@synthesize mousePosition;

#pragma mark -
#pragma mark Controlling response state

+ (NSSet *) keyPathsForValuesAffectingMouseActive
{
	return [NSSet setWithObject: @"emulator.isRunningProcess"];
}

- (BOOL) mouseActive
{
	//The mouse active state is not reset by DOSBox when a game exits.
	return mouseActive && [[self emulator] isRunningProcess];
}

- (void) lostFocus
{
	//Release all DOSBox events when we lose focus
	GFX_LosingFocus();
}


#pragma mark -
#pragma mark Mouse handling

- (void) mouseButtonPressed: (NSInteger)button withModifiers: (NSUInteger) modifierFlags
{
	//Happily, DOSBox's mouse button numbering corresponds exactly to OSX's
	Mouse_ButtonPressed(button);
}


- (void) mouseButtonReleased: (NSInteger)button withModifiers: (NSUInteger) modifierFlags
{
	//Happily, DOSBox's mouse button numbering corresponds exactly to OSX's
	Mouse_ButtonReleased(button);
}

- (void) mouseMovedToPoint: (NSPoint)point
				  byAmount: (NSPoint)delta
				  onCanvas: (NSRect)canvas
			   whileLocked: (BOOL)locked
{
	//TODO: control this sensitivity further up the food chain 
	CGFloat sensitivity = sdl.mouse.sensitivity / 100.0f;
	
	//In DOSBox land, absolute position is from 0-1 but delta is in raw pixels,
	//for some silly reason.
	NSPoint canvasDelta = NSMakePoint(delta.x * canvas.size.width,
									  delta.y * canvas.size.height);
	
	//point and delta use bottom-left origins to be consistent with AppKit's coordinate system.
	//We need to flip them to match DOSBox's top-left origin coordinate system.
	Mouse_CursorMoved(canvasDelta.x * sensitivity,
					  -canvasDelta.y * sensitivity,
					  point.x * sensitivity,
					  (1 - point.y) * sensitivity,
					  NO);
}
		 
#pragma mark -
#pragma mark Key handling

- (void) sendKeyEventWithCode: (unsigned short)keyCode
					  pressed: (BOOL)pressed
				withModifiers: (NSUInteger)modifierFlags
{
	SDL_Event keyEvent = [[self class] _SDLKeyEventForKeyCode: keyCode
													  pressed: pressed
												withModifiers: modifierFlags];
	
	MAPPER_CheckEvent(&keyEvent);
}

- (void) sendKeyEventWithCode: (unsigned short)keyCode
					  pressed: (BOOL)pressed
{
	[self sendKeyEventWithCode: keyCode pressed: pressed withModifiers: [[NSApp currentEvent] modifierFlags]];
}

- (void) sendKeypressWithCode: (unsigned short)keyCode
{
	[self sendKeyEventWithCode: keyCode pressed: YES];
	[self sendKeyEventWithCode: keyCode pressed: NO];
}


#pragma mark -
#pragma mark Faking events

- (void) sendTab	{ return [self sendKeypressWithCode: kVK_Tab]; }
- (void) sendDelete	{ return [self sendKeypressWithCode: kVK_Delete]; }
- (void) sendSpace	{ return [self sendKeypressWithCode: kVK_Space]; }
- (void) sendEnter	{ return [self sendKeypressWithCode: kVK_Return]; }

- (void) sendF1		{ return [self sendKeypressWithCode: kVK_F1]; }
- (void) sendF2		{ return [self sendKeypressWithCode: kVK_F2]; }
- (void) sendF3		{ return [self sendKeypressWithCode: kVK_F3]; }
- (void) sendF4		{ return [self sendKeypressWithCode: kVK_F4]; }
- (void) sendF5		{ return [self sendKeypressWithCode: kVK_F5]; }
- (void) sendF6		{ return [self sendKeypressWithCode: kVK_F6]; }
- (void) sendF7		{ return [self sendKeypressWithCode: kVK_F7]; }
- (void) sendF8		{ return [self sendKeypressWithCode: kVK_F8]; }
- (void) sendF9		{ return [self sendKeypressWithCode: kVK_F9]; }
- (void) sendF10	{ return [self sendKeypressWithCode: kVK_F10]; }


#pragma mark -
#pragma mark Keyboard layout methods

- (NSString *)keyboardLayoutForCurrentInputMethod
{
	TISInputSourceRef keyboardRef	= TISCopyCurrentKeyboardLayoutInputSource();
	NSString *inputSourceID			= (NSString *)TISGetInputSourceProperty(keyboardRef, kTISPropertyInputSourceID);
	CFRelease(keyboardRef);
	
	NSString *layout	= [[[self class] keyboardLayoutMappings] objectForKey: inputSourceID];
	if (!layout) layout	= [[self class] defaultKeyboardLayout];
	return layout;
}

+ (NSDictionary *)keyboardLayoutMappings
{
	//Note: these are not exact matches, and the ones marked with ?? are purely speculative.
	//DOSBox doesn't even natively support all of them.
	//This is a disgusting solution, and will be the first against the wall when the Unicode
	//revolution comes. 
	
	static NSDictionary *mappings = nil;
	if (!mappings) mappings = [[NSDictionary alloc] initWithObjectsAndKeys:
							   @"be",	@"com.apple.keylayout.Belgian",
							   
							   @"bg",	@"com.apple.keylayout.Bulgarian",				
							   @"bg",	@"com.apple.keylayout.Bulgarian-Phonetic",	//??
							   
							   @"br",	@"com.apple.keylayout.Brazilian",
							   
							   //There should be different mappings for Canadian vs French-Canadian
							   @"ca",	@"com.apple.keylayout.Canadian",
							   @"ca",	@"com.apple.keylayout.Canadian-CSA",
							   
							   //Note: DOS cz layout is QWERTY, not QWERTZ like the standard Mac Czech layout
							   @"cz",	@"com.apple.keylayout.Czech",
							   @"cz",	@"com.apple.keylayout.Czech-QWERTY",
							   
							   @"de",	@"com.apple.keylayout.Austrian",
							   @"de",	@"com.apple.keylayout.German",
							   
							   @"dk",	@"com.apple.keylayout.Danish",
							   
							   @"dv",	@"com.apple.keylayout.DVORAK-QWERTYCMD",
							   @"dv",	@"com.apple.keylayout.Dvorak",
							   
							   @"es",	@"com.apple.keylayout.Spanish",
							   @"es",	@"com.apple.keylayout.Spanish-ISO",
							   
							   @"fi",	@"com.apple.keylayout.Finnish",
							   @"fi",	@"com.apple.keylayout.FinnishExtended",
							   @"fi",	@"com.apple.keylayout.FinnishSami-PC",		//??
							   
							   //There should be different DOS mappings for French and French Numerical
							   @"fr",	@"com.apple.keylayout.French",
							   @"fr",	@"com.apple.keylayout.French-numerical",
							   
							   @"gk",	@"com.apple.keylayout.Greek",
							   @"gk",	@"com.apple.keylayout.GreekPolytonic",		//??
							   
							   @"hu",	@"com.apple.keylayout.Hungarian",
							   
							   @"is",	@"com.apple.keylayout.Icelandic",
							   
							   @"it",	@"com.apple.keylayout.Italian",
							   @"it",	@"com.apple.keylayout.Italian-Pro",			//??
							   
							   @"nl",	@"com.apple.keylayout.Dutch",
							   
							   @"no",	@"com.apple.keylayout.Norwegian",
							   @"no",	@"com.apple.keylayout.NorwegianExtended",
							   @"no",	@"com.apple.keylayout.NorwegianSami-PC",	//??
							   
							   @"pl",	@"com.apple.keylayout.Polish",
							   @"pl",	@"com.apple.keylayout.PolishPro",			//??
							   
							   @"po",	@"com.apple.keylayout.Portuguese",
							   
							   @"ru",	@"com.apple.keylayout.Russian",				//??
							   @"ru",	@"com.apple.keylayout.Russian-Phonetic",	//??
							   @"ru",	@"com.apple.keylayout.RussianWin",			//??
							   
							   @"sf",	@"com.apple.keylayout.SwissFrench",
							   @"sg",	@"com.apple.keylayout.SwissGerman",
							   
							   @"sv",	@"com.apple.keylayout.Swedish",
							   @"sv",	@"com.apple.keylayout.Swedish-Pro",
							   @"sv",	@"com.apple.keylayout.SwedishSami-PC",		//??
							   
							   @"uk",	@"com.apple.keylayout.British",
							   @"uk",	@"com.apple.keylayout.Irish",				//??
							   @"uk",	@"com.apple.keylayout.IrishExtended",		//??
							   @"uk",	@"com.apple.keylayout.Welsh",				//??
							   
							   @"us",	@"com.apple.keylayout.Australian",
							   @"us",	@"com.apple.keylayout.Hawaiian",			//??
							   @"us",	@"com.apple.keylayout.US",
							   @"us",	@"com.apple.keylayout.USExtended",
							   nil];
	return mappings;
}

+ (NSString *)defaultKeyboardLayout	{ return @"us"; }

@end


#pragma mark -
#pragma mark Internal methods

@implementation BXInputHandler (BXInputHandlerInternals)

//"Private-but-not-quite" - exposed here for coalface functions
- (SDLMod) currentSDLModifiers
{
	return [[self class] _convertToSDLModifiers: [[NSApp currentEvent] modifierFlags]];
}


+ (SDL_Event) _SDLKeyEventForKeyCode: (CGKeyCode)keyCode
							 pressed: (BOOL)pressed
					   withModifiers: (NSUInteger)modifierFlags
{
	
    SDL_Event keyEvent;
	keyEvent.type		= (pressed) ? SDL_KEYDOWN : SDL_KEYUP;
	keyEvent.key.state	= (pressed) ? SDL_PRESSED : SDL_RELEASED;
	
	keyEvent.key.keysym.scancode = keyCode;
	keyEvent.key.keysym.sym	= [self _convertToSDLKeyCode: keyCode];
	keyEvent.key.keysym.mod	= [self _convertToSDLModifiers: modifierFlags];
	
	return keyEvent;
}

+ (SDLKey) _convertToSDLKeyCode: (CGKeyCode)keyCode
{
#define KEYMAP_SIZE 256
	static SDLKey map[KEYMAP_SIZE];
	static BOOL mapGenerated = NO;
	if (!mapGenerated)
	{
		NSUInteger i;
		//Clear all of the keymap entries first
		for (i=0; i < KEYMAP_SIZE; i++)
			map[i] = SDLK_UNKNOWN;
		
		map[kVK_F1] = SDLK_F1;
		map[kVK_F2] = SDLK_F2;
		map[kVK_F3] = SDLK_F3;
		map[kVK_F4] = SDLK_F4;
		map[kVK_F5] = SDLK_F5;
		map[kVK_F6] = SDLK_F6;
		map[kVK_F7] = SDLK_F7;
		map[kVK_F8] = SDLK_F8;
		map[kVK_F9] = SDLK_F9;
		map[kVK_F10] = SDLK_F10;
		map[kVK_F11] = SDLK_F11;
		map[kVK_F12] = SDLK_F12;
		map[kVK_F13] = SDLK_F13;
		map[kVK_F14] = SDLK_F14;
		map[kVK_F15] = SDLK_F15;		
		
		map[kVK_ANSI_1] = SDLK_1;
		map[kVK_ANSI_2] = SDLK_2;
		map[kVK_ANSI_3] = SDLK_3;
		map[kVK_ANSI_4] = SDLK_4;
		map[kVK_ANSI_5] = SDLK_5;
		map[kVK_ANSI_6] = SDLK_6;
		map[kVK_ANSI_7] = SDLK_7;
		map[kVK_ANSI_8] = SDLK_8;
		map[kVK_ANSI_9] = SDLK_9;
		map[kVK_ANSI_0] = SDLK_0;
		
		map[kVK_ANSI_Q] = SDLK_q;
		map[kVK_ANSI_W] = SDLK_w;
		map[kVK_ANSI_E] = SDLK_e;
		map[kVK_ANSI_R] = SDLK_r;
		map[kVK_ANSI_T] = SDLK_t;
		map[kVK_ANSI_Y] = SDLK_y;
		map[kVK_ANSI_U] = SDLK_u;
		map[kVK_ANSI_I] = SDLK_i;
		map[kVK_ANSI_O] = SDLK_o;
		map[kVK_ANSI_P] = SDLK_p;
		
		map[kVK_ANSI_A] = SDLK_a;
		map[kVK_ANSI_S] = SDLK_s;
		map[kVK_ANSI_D] = SDLK_d;
		map[kVK_ANSI_F] = SDLK_f;
		map[kVK_ANSI_G] = SDLK_g;
		map[kVK_ANSI_H] = SDLK_h;
		map[kVK_ANSI_J] = SDLK_j;
		map[kVK_ANSI_K] = SDLK_k;
		map[kVK_ANSI_L] = SDLK_l;
		
		map[kVK_ANSI_Z] = SDLK_z;
		map[kVK_ANSI_X] = SDLK_x;
		map[kVK_ANSI_C] = SDLK_c;
		map[kVK_ANSI_V] = SDLK_v;
		map[kVK_ANSI_B] = SDLK_b;
		map[kVK_ANSI_N] = SDLK_n;
		map[kVK_ANSI_M] = SDLK_m;
		
		map[kVK_ANSI_Keypad1] = SDLK_KP1;
		map[kVK_ANSI_Keypad2] = SDLK_KP2;
		map[kVK_ANSI_Keypad3] = SDLK_KP3;
		map[kVK_ANSI_Keypad4] = SDLK_KP4;
		map[kVK_ANSI_Keypad5] = SDLK_KP5;
		map[kVK_ANSI_Keypad6] = SDLK_KP6;
		map[kVK_ANSI_Keypad7] = SDLK_KP7;
		map[kVK_ANSI_Keypad8] = SDLK_KP8;
		map[kVK_ANSI_Keypad9] = SDLK_KP9;
		map[kVK_ANSI_Keypad0] = SDLK_KP0;
		map[kVK_ANSI_KeypadDecimal] = SDLK_KP_PERIOD;
		
		map[kVK_ANSI_KeypadPlus] = SDLK_KP_PLUS;
		map[kVK_ANSI_KeypadMinus] = SDLK_KP_MINUS;
		map[kVK_ANSI_KeypadEquals] = SDLK_KP_EQUALS;
		map[kVK_ANSI_KeypadDivide] = SDLK_KP_DIVIDE;
		map[kVK_ANSI_KeypadMultiply] = SDLK_KP_MULTIPLY;
		map[kVK_ANSI_KeypadEnter] = SDLK_KP_ENTER;
		
		map[kVK_Escape] = SDLK_ESCAPE;
		map[kVK_CapsLock] = SDLK_CAPSLOCK;
		map[kVK_Tab] = SDLK_TAB;
		map[kVK_Delete] = SDLK_BACKSPACE;
		map[kVK_ForwardDelete] = SDLK_DELETE;
		map[kVK_Return] = SDLK_RETURN;
		map[kVK_Space] = SDLK_SPACE;
		
		map[kVK_Home] = SDLK_HOME;
		map[kVK_End] = SDLK_END;
		map[kVK_PageUp] = SDLK_PAGEUP;
		map[kVK_PageDown] = SDLK_PAGEDOWN;
		
		map[kVK_UpArrow] = SDLK_UP;
		map[kVK_LeftArrow] = SDLK_LEFT;
		map[kVK_DownArrow] = SDLK_DOWN;
		map[kVK_RightArrow] = SDLK_RIGHT;
		
		map[kVK_Shift] = SDLK_LSHIFT;
		map[kVK_Control] = SDLK_LCTRL;
		map[kVK_Option] = SDLK_LALT;
		
		map[kVK_RightControl] = SDLK_RCTRL;
		map[kVK_RightOption] = SDLK_RALT;
		map[kVK_RightShift] = SDLK_RSHIFT;
		
		map[kVK_ANSI_Minus] = SDLK_MINUS;
		map[kVK_ANSI_Equal] = SDLK_EQUALS;
		
		map[kVK_ANSI_LeftBracket] = SDLK_LEFTBRACKET;
		map[kVK_ANSI_RightBracket] = SDLK_RIGHTBRACKET;
		map[kVK_ANSI_Backslash] = SDLK_BACKSLASH;
		
		map[kVK_ANSI_Grave] = SDLK_BACKQUOTE;
		map[kVK_ANSI_Semicolon] = SDLK_SEMICOLON;
		map[kVK_ANSI_Quote] = SDLK_QUOTE;
		map[kVK_ANSI_Comma] = SDLK_COMMA;
		map[kVK_ANSI_Period] = SDLK_PERIOD;
		map[kVK_ANSI_Slash] = SDLK_SLASH;
		map[kVK_ISO_Section] = SDLK_WORLD_0;
		
		mapGenerated = YES;
	}
	
	if (keyCode < KEYMAP_SIZE) return map[keyCode];
	//Just in case
	else return SDLK_UNKNOWN;
}

+ (SDLMod) _convertToSDLModifiers: (NSUInteger)modifierFlags
{
	//To avoid compilation errors because of the OR operator, we declare
	//this as an integer and then cast it to SDLMod once we're done.
	NSUInteger SDLModifiers = KMOD_NONE;
	
	//This flag doesn't work the way that NumLock works in PC-land, so we shouldn't expose it.
	//if (modifierFlags & NSNumericPadKeyMask)		SDLModifiers |= KMOD_NUM;
	
	if (modifierFlags & NSAlphaShiftKeyMask)		SDLModifiers |= KMOD_CAPS;
	if (modifierFlags & BXLeftControlKeyMask)		SDLModifiers |= KMOD_LCTRL;
	if (modifierFlags & BXRightControlKeyMask)		SDLModifiers |= KMOD_RCTRL;
	if (modifierFlags & BXLeftShiftKeyMask)			SDLModifiers |= KMOD_LSHIFT;
	if (modifierFlags & BXRightShiftKeyMask)		SDLModifiers |= KMOD_RSHIFT;
	if (modifierFlags & BXLeftAlternateKeyMask)		SDLModifiers |= KMOD_LALT;
	if (modifierFlags & BXRightAlternateKeyMask)	SDLModifiers |= KMOD_RALT;
	
	return (SDLMod)SDLModifiers;
}
@end