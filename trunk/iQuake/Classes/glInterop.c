
#include "glInterop.h"

#define MAX_VERTICES (4096 * 8)
#define MAX_COORDS (4096 * 8)

GLfloat coordinates[MAX_COORDS];
int coordinatesIndex;

GLfloat vertices[MAX_COORDS];
int verticesIndex;

int _renderMode;

void glBegin(int renderMode) {
	_renderMode = renderMode;
	coordinatesIndex = 0;
	verticesIndex = 0;
}

void glEnd() {
	
	switch (_renderMode) {
		case GL_QUADS: {
			glVertexPointer(3, GL_FLOAT, 0, vertices);
			
			if (coordinatesIndex > 0) {
				glTexCoordPointer(2, GL_FLOAT, 0, coordinates);
			}

			glDrawArrays(GL_TRIANGLE_STRIP, 0, verticesIndex / 3); 
			
			break;
		}

		case GL_POLYGON: {
			glVertexPointer(3, GL_FLOAT, 0, vertices);
			
			if (coordinatesIndex > 0) {
				glTexCoordPointer(2, GL_FLOAT, 0, coordinates);
			}
			
			glDrawArrays(GL_TRIANGLE_FAN, 0, verticesIndex / 3); 
			
			break;
		}
			
		case GL_TRIANGLES: {
			glVertexPointer(3, GL_FLOAT, 0, vertices);
			if (coordinatesIndex > 0) {
				glTexCoordPointer(2, GL_FLOAT, 0, coordinates);
			}
			
			glDrawArrays(GL_TRIANGLES, 0, verticesIndex / 3); 
			
			break;
		}
			
		case GL_LINES: {
			glVertexPointer(3, GL_FLOAT, 0, vertices);
			
			if (coordinatesIndex > 0) {
				glTexCoordPointer(2, GL_FLOAT, 0, coordinates);
			}
			
			glDrawArrays(GL_LINES, 0, verticesIndex / 3); 
			
			break;
		}
			
		case GL_TRIANGLE_FAN: {
			glVertexPointer(3, GL_FLOAT, 0, vertices);
			
			if (coordinatesIndex > 0) {
				glTexCoordPointer(2, GL_FLOAT, 0, coordinates);
			}
			
			glDrawArrays(GL_TRIANGLE_FAN, 0, verticesIndex / 3); 
			break;
		}
			
		case GL_TRIANGLE_STRIP: {
			glVertexPointer(3, GL_FLOAT, 0, vertices);
			
			if (coordinatesIndex > 0) {
				glTexCoordPointer(2, GL_FLOAT, 0, coordinates);
			}
			
			glDrawArrays(GL_TRIANGLE_STRIP, 0, verticesIndex / 3); 
			
			break;
		} 
	}
}

void glColor3f(GLfloat red, GLfloat green, GLfloat blue) {
	glColor4f(red, green, blue, 1);	
}

void glColor4fv(GLfloat* c) {
	glColor4f(c[0], c[1], c[2], c[3]);
}

void glColor3ubv(const GLubyte *v) {
	glColor3f(v[0], v[1], v[2]);
}

void glTexCoord2f (GLfloat u, GLfloat v) {
	if (coordinatesIndex + 4 > MAX_COORDS)
		Sys_Error("Max Coordinates reached");

	if (_renderMode == GL_QUADS) {
		if (((coordinatesIndex / 2) % 4) == 2) {
			coordinates[2 + coordinatesIndex++] = u;
			coordinates[2 + coordinatesIndex++] = v;		
		} else if (((coordinatesIndex / 2)  % 4) == 3) {
			coordinates[coordinatesIndex - 2] = u;
			coordinatesIndex++;
		
			coordinates[coordinatesIndex - 2] = v;			   
			coordinatesIndex++;
		} else {	
			coordinates[coordinatesIndex++] = u;
			coordinates[coordinatesIndex++] = v;
		}
	} else {
		coordinates[coordinatesIndex++] = u;
		coordinates[coordinatesIndex++] = v;
	}
}

void glVertex2f (GLfloat x, GLfloat y) {
	glVertex3f(x, y, 0);
}

void glVertex3f (GLfloat x, GLfloat y, GLfloat z) {
	if (verticesIndex + 6 > MAX_VERTICES)
		Sys_Error("Max Vertices Reached");
	
	if (_renderMode == GL_QUADS) {
		if (((verticesIndex / 3) % 4) == 2) {
			vertices[3 + verticesIndex++] = x;
			vertices[3 + verticesIndex++] = y;
			vertices[3 + verticesIndex++] = z;
		} else if (((verticesIndex / 3) % 4) == 3) {
			vertices[verticesIndex - 3] = x;
			verticesIndex++;
		
			vertices[verticesIndex - 3] = y;
			verticesIndex++;

			vertices[verticesIndex - 3] = z;		
			verticesIndex++;
		} else {
			vertices[verticesIndex++] = x;
			vertices[verticesIndex++] = y;
			vertices[verticesIndex++] = z;
		}
	} else {
		vertices[verticesIndex++] = x;
		vertices[verticesIndex++] = y;
		vertices[verticesIndex++] = z;
	}
}

void glVertex3fv (GLfloat* v) {
	glVertex3f(v[0], v[1], v[2]);
}

void glVertex4fv (GLfloat* v) {
	glVertex3f(v[0], v[1], v[2]);
}

void glReadBuffer(GLenum mode) {
}

void glDrawBuffer(GLenum mode) {
}

void glOrtho (int left, int right, int bottom, int top, int zNear, int zFar) {
	glOrthof((GLfloat)left, (GLfloat)right, (GLfloat)bottom, (GLfloat)top, (GLfloat)zNear, (GLfloat)zFar);
}

