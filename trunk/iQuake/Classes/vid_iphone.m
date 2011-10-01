/*
 *  vid_iphone.c
 *  iQuake
 *
 *  Created by Ben on 13/12/2008.
 *  Copyright 2008. All rights reserved.
 *
 */

#include "quakedef.h"
//#include "d_local.h"
#include "iQuakeView.h"
#include "Texture2D.h"

iQuakeView* _view;

int texture_extension_number;

const char* gl_renderer = "Glide";
int		texture_mode = GL_LINEAR;
cvar_t	gl_ztrick = {"gl_ztrick","1"};
qboolean isPermedia = false;
qboolean gl_mtexable = false;
float		gldepthmin, gldepthmax;


viddef_t	vid;				// global video state

unsigned short	d_15to8table[65536];
unsigned	d_8to24table[256];

Texture2D* gameControlsTexture;

void SetView(void* view) {
	_view = (iQuakeView*)view;
	
	_view.contentScaleFactor = 1.0f;
}


void	VID_SetPalette (unsigned char *palette)
{
	byte	*pal;
	unsigned r,g,b;
	unsigned v;
	int     r1,g1,b1;
	int		k;
	unsigned short i;
	unsigned	*table;
	int dist, bestdist;

	//
	// 8 8 8 encoding
	//
	pal = palette;
	table = d_8to24table;
	for (i=0 ; i<256 ; i++)
	{
		r = pal[0];
		g = pal[1];
		b = pal[2];
		pal += 3;
		
		r *= 2;
		g *= 2;
		b *= 2;
		
		if (r > 255)
			r = 255;
		if (g > 255)
			g = 255;
		if (b > 255)
			b = 255;

		v = (255<<24) + (r<<0) + (g<<8) + (b<<16);
		*table++ = v;
	}
	d_8to24table[255] &= 0x00ffffff;	// 255 is transparent
	
	for (i=0; i < (1<<15); i++) {
		/* Maps
		 000000000000000
		 000000000011111 = Red  = 0x1F
		 000001111100000 = Blue = 0x03E0
		 111110000000000 = Grn  = 0x7C00
		 */
		r = ((i & 0x1F) << 3)+4;
		g = ((i & 0x03E0) >> 2)+4;
		b = ((i & 0x7C00) >> 7)+4;
		pal = (unsigned char *)d_8to24table;
		for (v=0,k=0,bestdist=10000*10000; v<256; v++,pal+=4) {
			r1 = (int)r - (int)pal[0];
			g1 = (int)g - (int)pal[1];
			b1 = (int)b - (int)pal[2];
			dist = (r1*r1)+(g1*g1)+(b1*b1);
			if (dist < bestdist) {
				k=v;
				bestdist = dist;
			}
		}
		d_15to8table[i]=k;
	}
}


void	VID_ShiftPalette (unsigned char *palette)
{
}

void	VID_Init (unsigned char *palette)
{
	CGRect rect = [[UIScreen mainScreen] bounds];	

	Con_Printf ("Screen Size w:%d x h:%d\n", (int)rect.size.height, (int)rect.size.width);
	
	// Game is played sideways so the screens width is the height of the game view and
	// the height is the width of the game view
	vid.maxwarpwidth = vid.width = vid.conwidth = (int)rect.size.height;
	vid.maxwarpheight = vid.height = vid.conheight = (int)rect.size.width;
	vid.aspect = 1.0;
	vid.numpages = 1;
	vid.colormap = host_colormap;
	vid.fullbright = 256 - LittleLong (*((int *)vid.colormap + 2048));
	vid.buffer = vid.conbuffer = 0;
	vid.rowbytes = vid.conrowbytes = (int)rect.size.height;

	// Dump out the available GL extension info etc
	const GLubyte* gl_vendor = glGetString (GL_VENDOR);
	Con_Printf ("GL_VENDOR: %s\n", gl_vendor);
	const GLubyte* gl_renderer = glGetString (GL_RENDERER);
	Con_Printf ("GL_RENDERER: %s\n", gl_renderer);
	
	const GLubyte* gl_version = glGetString (GL_VERSION);
	Con_Printf ("GL_VERSION: %s\n", gl_version);
	const GLubyte* gl_extensions = glGetString (GL_EXTENSIONS);
	Con_Printf ("GL_EXTENSIONS: %s\n", gl_extensions);
	
	//Initialize OpenGL states
	glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
	glEnable(GL_TEXTURE_2D);
	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	glDisable(GL_BLEND);
		
	//glClearColor (1,0,0,0);
	//glCullFace(GL_FRONT);

	glShadeModel (GL_FLAT);
	
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
	
	glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	
	//glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);

	// Set the game palette translation tables
	VID_SetPalette(palette);
	
	// Load the controls overlay
	UIImage* image = [UIImage imageNamed:@"GameControls.png"];
	gameControlsTexture = [[Texture2D alloc]initWithImage:image];
	[image release];	
	
	Con_Printf("%d\n", vid.width);
}


void	VID_Shutdown (void)
{
}

void	VID_Update (vrect_t *rects)
{
}

qboolean VID_Is8bit(void) {
	return false;
}

/*
 ================
 D_BeginDirectRect
 ================
 */
void D_BeginDirectRect (int x, int y, byte *pbitmap, int width, int height)
{
}


/*
 ================
 D_EndDirectRect
 ================
 */
void D_EndDirectRect (int x, int y, int width, int height)
{
}

void GL_BeginRendering (int *x, int *y, int *width, int *height)
{
	CGRect rect = [[UIScreen mainScreen] bounds];	
		
	// Game is played sideways so the screens width is the height of the game view and
	// the height is the width of the game view
	*x = *y = 0;
	*width = (int)rect.size.height;
	*height = (int)rect.size.width;
	
	R_Clear();
}

void GL_EndRendering (void)
{
	if (!block_drawing) {
		CGRect rect = [[UIScreen mainScreen] bounds];	

		glViewport (glx, gly, glheight, glwidth);
		
		glMatrixMode(GL_PROJECTION);
		glLoadIdentity ();
		glRotatef(-90, 0, 0, 1);
		glOrthof(0, rect.size.width, 0, rect.size.height, -1, 1);
		
		glMatrixMode(GL_MODELVIEW);
		glLoadIdentity ();
		
		// Draw the alpha blended game controls overlay
		glEnable(GL_BLEND);
		[gameControlsTexture drawInRect:rect];
		glDisable(GL_BLEND);
		
		[_view swapBuffers];
	}
}
