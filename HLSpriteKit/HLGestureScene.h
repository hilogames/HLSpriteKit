//
//  HLGestureScene.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 5/27/14.
//  Copyright (c) 2014 Hilo. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

#import "HLScene.h"

/**
 * HLGestureScene implements a gesture handler for any of its child nodes which
 * conform to HLGestureTarget.
 *
 * note: This is a feature useful to different kinds of scenes; consider making
 * this a component for composition rather than a class for subclassing.
 */

@interface HLGestureScene : HLScene <UIGestureRecognizerDelegate>

@end
