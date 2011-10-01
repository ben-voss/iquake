//
//  iQuakeView.h
//  iQuake
//
//  Created by Ben on 10/12/2008.
//  Copyright 2008. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/EAGLDrawable.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

@class iQuakeView;

@protocol iQuakeEAGLViewDelegate <NSObject>
- (void) didResizeEAGLSurfaceForView:(iQuakeView*)view; //Called whenever the EAGL surface has been resized
@end

@interface iQuakeView : UIView {
	
@private
	NSString*				_format;
	GLuint					_depthFormat;
	BOOL					_autoresize;
	EAGLContext				*_context;
	GLuint					_framebuffer;
	GLuint					_renderbuffer;
	GLuint					_depthBuffer;
	CGSize					_size;
	BOOL					_hasBeenCurrent;
	id<iQuakeEAGLViewDelegate>	_delegate;	
}

- (id)initWithCoder:(NSCoder*)coder; 

@property(readonly) GLuint framebuffer;
@property(readonly) NSString* pixelFormat;
@property(readonly) GLuint depthFormat;
@property(readonly) EAGLContext *context;

@property BOOL autoresizesSurface; //NO by default - Set to YES to have the EAGL surface automatically resized when the view bounds change, otherwise the EAGL surface contents is rendered scaled
@property(readonly, nonatomic) CGSize surfaceSize;

@property(assign) id<iQuakeEAGLViewDelegate> delegate;

- (void) setCurrentContext;
- (BOOL) isCurrentContext;
- (void) clearCurrentContext;

- (void) swapBuffers; //This also checks the current OpenGL error and logs an error if needed

- (CGPoint) convertPointFromViewToSurface:(CGPoint)point;
- (CGRect) convertRectFromViewToSurface:(CGRect)rect;

@end
