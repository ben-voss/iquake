//
//  iQuakeAppDelegate.m
//  iQuake
//
//  Created by Ben on 16/11/2008.
//  Copyright 2008. All rights reserved.
//

#import "iQuakeAppDelegate.h"
#import "iQuakeViewController.h"
#import "quakedef.h"

#define kRenderingFPS				15.0 // Hz
#define kFilteringFactor 0.02


void SetView(void* view);

@implementation iQuakeAppDelegate

- init {
	if ((self = [super init])) {
		// Set the accelerometer to update at the same frequency as the frame rate and to send the updates
		// to this app delegate		
		[[UIAccelerometer sharedAccelerometer] setUpdateInterval:(1.0 / (kRenderingFPS))];
		[[UIAccelerometer sharedAccelerometer] setDelegate:self];
	}
	return self;
}

- (void)applicationDidFinishLaunching:(UIApplication *)application {
		
	static quakeparms_t    parms;
	
	parms.memsize = 16*1024*1024;
	parms.membase = malloc (parms.memsize);
	
	// Set the base dir to the location of the game data files
	parms.basedir = (char*)[[[NSBundle mainBundle] resourcePath] UTF8String];

	SetView(view);
	
	Host_Init (&parms);
	//Host_Frame(1.0 / kRenderingFPS);

	// Start the rendering timer
	_timer = [NSTimer scheduledTimerWithTimeInterval:(1.0 / kRenderingFPS) target:self selector:@selector(renderScene) userInfo:nil repeats:YES];
	[UIApplication sharedApplication].idleTimerDisabled = YES;
}

// Renders one scene of the game
- (void)renderScene {
	Host_Frame(1.0 / kRenderingFPS);
}

- (void)dealloc {
	[view release];
    [window release];
    [super dealloc];
}

static double timestamp = 0;
int mouse_x;
int mouse_y;

// UIAccelerometer delegate method, which delivers the latest acceleration data.
- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration {
    // Use a basic low-pass filter to only keep the gravity in the accelerometer values for the X and Y axes
    accelerationX = acceleration.x;// * kFilteringFactor + accelerationX * (1.0 - kFilteringFactor);
    accelerationY = acceleration.y;// * kFilteringFactor + accelerationY * (1.0 - kFilteringFactor);	
	double newTimestamp = acceleration.timestamp;
	
	mouse_x = (accelerationX + .6) * ((newTimestamp - timestamp) * 8000);
	mouse_y = -accelerationY * ((newTimestamp - timestamp) * 10000);
		
	timestamp = newTimestamp;
}

void IN_Move (usercmd_t *cmd)
{
	cl.viewangles[YAW] -= m_yaw.value * mouse_y;
	cl.viewangles[PITCH] += m_pitch.value * mouse_x;
	
	if (cl.viewangles[PITCH] > 80)
		cl.viewangles[PITCH] = 80;
	
	if (cl.viewangles[PITCH] < -70)
		cl.viewangles[PITCH] = -70;
}

-(void)applicationWillResignActive:(UIApplication *)application {
	Key_Event(K_PAUSE, TRUE);
	Host_Frame(1.0 / kRenderingFPS);

	Key_Event(K_PAUSE, FALSE);
	Host_Frame(1.0 / kRenderingFPS);

	if (_timer != nil) {
		[_timer invalidate];
		_timer = nil;
	}
}

-(void)applicationDidBecomeActive:(UIApplication *)application {
	Key_Event(K_PAUSE, TRUE);
	Host_Frame(1.0 / kRenderingFPS);
	
	Key_Event(K_PAUSE, FALSE);
	Host_Frame(1.0 / kRenderingFPS);

	if (_timer != nil)
		_timer = [NSTimer scheduledTimerWithTimeInterval:(1.0 / kRenderingFPS) target:self selector:@selector(renderScene) userInfo:nil repeats:YES];
}


@end
