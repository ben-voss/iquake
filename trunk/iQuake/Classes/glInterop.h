/*
 *  glInterop.h
 *  iQuake
 *
 *  Created by Ben on 10/12/2008.
 *  Copyright 2008. All rights reserved.
 *
 */

#include <OpenGLES/ES1/gl.h>
#include <OpenGLES/ES1/glext.h>

#define GL_QUADS 0x0007
#define GL_POLYGON 0x0009

#define GL_INTENSITY GL_LUMINANCE_ALPHA

#define GLdouble GLfloat

#define glDepthRange glDepthRangef
#define glFrustum glFrustumf


void glBegin(int renderMode);

void glEnd();

void glColor3f(GLfloat red, GLfloat green, GLfloat blue);
void glColor4fv(GLfloat* c);
void glColor3ubv(const GLubyte *v);

void glTexCoord2f (GLfloat u, GLfloat v);

void glVertex2f (GLfloat x, GLfloat y);
void glVertex3f (GLfloat x, GLfloat y, GLfloat z);
void glVertex3fv (GLfloat* v);
void glVertex4fv (GLfloat* v);
void glReadBuffer(GLenum mode);
void glDrawBuffer(GLenum mode);
void glOrtho (int left, int right, int bottom, int top, int zNear, int zFar);
//void glFrustumf (GLfloat left, GLfloat right, GLfloat bottom, GLfloat top, GLfloat zNear, GLfloat zFar);

