#include "pch.h"
#include <Kore/System.h>
#include <Kore/Application.h>
#include <Kore/Input/KeyEvent.h>
#include <Kore/Input/Keyboard.h>
#import <Cocoa/Cocoa.h>
#import "BasicOpenGLView.h"

using namespace Kore;

extern const char* macgetresourcepath();

const char* macgetresourcepath() {
	return [[[NSBundle mainBundle] resourcePath] cStringUsingEncoding:1];
}

@interface MyApplication : NSApplication {
	bool shouldKeepRunning;
}

- (void)run;
- (void)terminate:(id)sender;

@end

@interface MyAppDelegate : NSObject<NSWindowDelegate> {
	
}

- (void)windowWillClose:(NSNotification *)notification;

@end

namespace {
	NSApplication* myapp;
	NSWindow* window;
	BasicOpenGLView* view;
	MyAppDelegate* delegate;
}

bool System::handleMessages() {
	NSEvent* event = [myapp nextEventMatchingMask:NSAnyEventMask untilDate:[NSDate distantPast] inMode:NSDefaultRunLoopMode dequeue:YES]; //distantPast: non-blocking
	if (event != nil) {
		[myapp sendEvent:event];
		[myapp updateWindows];
	}
	return true;
}

void System::swapBuffers() {
	[view switchBuffers];
}

void* System::createWindow() {
	view = [[BasicOpenGLView alloc] initWithFrame:NSMakeRect(0, 0, Kore::Application::the()->width(), Kore::Application::the()->height()) ];
	window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, Kore::Application::the()->width(), Kore::Application::the()->height()) styleMask:NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask backing:NSBackingStoreBuffered defer:TRUE];
	delegate = [MyAppDelegate alloc];
	[window setDelegate: delegate];
	[window setTitle:[NSString stringWithCString: Kore::Application::the()->name() encoding: 1]];
	[window setAcceptsMouseMovedEvents:YES];
	[[window contentView] addSubview:view];
	[window center];
	[window makeKeyAndOrderFront: nil];
		
	return nullptr;
}

void System::destroyWindow() {
	
}

int System::screenWidth() {
	return Application::the()->width();
}

int System::screenHeight() {
	return Application::the()->height();
}

int main(int argc, char** argv) {
	@autoreleasepool {
		myapp = [MyApplication sharedApplication];
		[myapp performSelectorOnMainThread:@selector(run) withObject:nil waitUntilDone:YES];
	}
	return 0;
}

@implementation MyApplication

- (void)run {
	@autoreleasepool {
		[self finishLaunching];
		//try {
			kore(0, nullptr);
		//}
		//catch (Kt::Exception& ex) {
		//	printf("Exception caught");
		//}
	}
}

- (void)terminate:(id)sender {
	Application::the()->stop();
}

@end

@implementation MyAppDelegate

- (void)windowWillClose:(NSNotification *)notification {
	Application::the()->stop();
}

@end