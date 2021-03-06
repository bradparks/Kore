#import "GLView.h"
#include "pch.h"
#include <Kore/Application.h>
#include <Kore/Input/Keyboard.h>
#include <Kore/Input/KeyEvent.h>
#include <Kore/Input/Mouse.h>
#include <Kore/System.h>

@implementation GLView

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:(CGRect)frame];
	
	CAEAGLLayer* eaglLayer = (CAEAGLLayer*)self.layer;
	
	eaglLayer.opaque = YES;
	eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool:FALSE], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
	[eaglLayer setAffineTransform:CGAffineTransformConcat(CGAffineTransformMakeRotation(M_PI / 2), CGAffineTransformMakeTranslation(-128, 128))];

	context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
	
	if (!context || ![EAGLContext setCurrentContext:context]) {
		[self release];
		return nil;
	}
	
	glGenFramebuffersOES(1, &defaultFramebuffer);
	glGenRenderbuffersOES(1, &colorRenderbuffer);
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, defaultFramebuffer);
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, colorRenderbuffer);
	glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, colorRenderbuffer);
	
	glGenRenderbuffersOES(1, &depthRenderbuffer);
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, depthRenderbuffer);
    glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER_OES, depthRenderbuffer);
	
	return self;
}

- (void)begin {
	[EAGLContext setCurrentContext:context];
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, defaultFramebuffer);
    glViewport(0, 0, backingWidth, backingHeight);
}

- (void)end {
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, colorRenderbuffer);
    [context presentRenderbuffer:GL_RENDERBUFFER_OES];
}

- (void)layoutSubviews {
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, colorRenderbuffer);
    [context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(CAEAGLLayer*)self.layer];
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);
	
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, depthRenderbuffer);
    glRenderbufferStorageOES(GL_RENDERBUFFER_OES, GL_DEPTH_COMPONENT24_OES, backingWidth, backingHeight);
	
    if (glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES) {
        NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
    }
}

- (void)dealloc {
	if (defaultFramebuffer) {
		glDeleteFramebuffersOES(1, &defaultFramebuffer);
		defaultFramebuffer = 0;
	}
	
	if (colorRenderbuffer) {
		glDeleteRenderbuffersOES(1, &colorRenderbuffer);
		colorRenderbuffer = 0;
	}
	
	if ([EAGLContext currentContext] == context) [EAGLContext setCurrentContext:nil];
	
	[context release];
	context = nil;
	
	[super dealloc];
}

static void adjustxy(float& x, float& y) {
	/*
#ifdef ROTATE90
	float oldx = x;
	x = y;
	y = Kore::System::screenHeight() - 1 - oldx;
#endif
	x = x / Kore::System::screenWidth() * Kore::Application::the()->width();
	y = y / Kore::System::screenHeight() * Kore::Application::the()->height();
	*/
	CGFloat scale = [[UIScreen mainScreen] scale];
	x *= scale;
	y *= scale;
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
	CGPoint point = [touch locationInView:self];
	adjustxy(point.x, point.y);
	Kore::Mouse::the()->_pressLeft(Kore::MouseEvent(point.x, point.y));
}

- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
	CGPoint point = [touch locationInView:self];
	adjustxy(point.x, point.y);
	Kore::Mouse::the()->_move(Kore::MouseEvent(point.x, point.y));
}

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
	CGPoint point = [touch locationInView:self];
	adjustxy(point.x, point.y);
	Kore::Mouse::the()->_releaseLeft(Kore::MouseEvent(point.x, point.y));
}

- (void)touchesCancelled:(NSSet*)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
	CGPoint point = [touch locationInView:self];
	adjustxy(point.x, point.y);
	Kore::Mouse::the()->_releaseLeft(Kore::MouseEvent(point.x, point.y));
}

namespace {
	NSString* keyboardstring;
    UITextField* myTextField;
	bool shiftDown = false;
}

- (void)showKeyboard {
	[UIApplication sharedApplication].statusBarOrientation = UIInterfaceOrientationLandscapeRight;
	keyboardstring = [NSString string];
	myTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
	[myTextField setDelegate:self];
	[myTextField setBorderStyle:UITextBorderStyleRoundedRect];
	[myTextField setBackgroundColor:[UIColor whiteColor]];
	[myTextField setTextColor:[UIColor blackColor]];
	[myTextField setClearButtonMode:UITextFieldViewModeAlways];
	[myTextField setFont:[UIFont fontWithName:@"Arial" size:18.0f]];
	[myTextField setPlaceholder:@"Tap here to edit"];
	//[myTextField setTextAlignment:UITextAlignmentCenter];
	[myTextField setReturnKeyType:UIReturnKeyDone];
	[self addSubview:myTextField];
	[myTextField becomeFirstResponder];
}

- (void)hideKeyboard {
    [myTextField endEditing:YES];
    [myTextField removeFromSuperview];
}

- (void)textFieldDidEndEditing:(UITextField*)textField {
	//NSLog([textField text]);
	[textField endEditing:YES];
	[textField removeFromSuperview];
}

- (BOOL)textFieldShouldReturn:(UITextField*)texField {
	// end editing
	[texField resignFirstResponder];
	return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	if ([string length] == 1) {
		char ch = [string characterAtIndex: [string length] - 1];
		if (ch >= L'a' && ch <= L'z') {
			if (shiftDown) {
				Kore::Keyboard::the()->keyup(Kore::KeyEvent(Kore::Key_Shift));
				shiftDown = false;
			}
			Kore::Keyboard::the()->keydown(Kore::KeyEvent(ch + L'A' - L'a'));
		}
		else {
			if (!shiftDown) {
				Kore::Keyboard::the()->keydown(Kore::KeyEvent(Kore::Key_Shift));
				shiftDown = true;
			}
			Kore::Keyboard::the()->keydown(Kore::KeyEvent(ch));
		}
	}
	else if ([string length] == 0 && range.length == 1) {
		Kore::Keyboard::the()->keydown(Kore::KeyEvent(Kore::Key_Backspace));
	}
	return YES;
}

@end