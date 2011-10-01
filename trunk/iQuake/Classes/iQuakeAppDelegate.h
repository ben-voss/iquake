//
//  iQuakeAppDelegate.h
//  iQuake
//
//  Created by Ben on 16/11/2008.
//  Copyright 2008. All rights reserved.
//

#import <UIKit/UIKit.h>

@class iQuakeView;

@interface iQuakeAppDelegate : NSObject <UIApplicationDelegate, UIAccelerometerDelegate> {
    IBOutlet UIWindow *window;
    IBOutlet iQuakeView *view;

	UIAccelerationValue accelerationX;
    UIAccelerationValue accelerationY;

	NSTimer* _timer;
}

@end

