//
//  HLMath.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 7/21/14.
//  Copyright (c) 2014 Hilo Games. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGGeometry.h>

/**
 * Find the bounds (size-only) of a rectangle (size-only) after it has first been rotated.
 *
 * note: I'm going to document the motivating example in case it helps point to an
 * alternate or better solution.  I've got an SKNode descendent which I'm going to display
 * in a box.  The node's size property does not yet account for the node's desired rotation,
 * but I can use this function to calculate it myself so I know how big to make the display
 * box.  (The node also has a frame.size, which already accounts for rotation and scaling,
 * but unfortunately the calculated frame only contains visible areas of the node, which
 * is not the same as its desired display size.)
 */
FOUNDATION_EXPORT CGSize HLGetBoundsForTransformation(CGSize size, CGFloat theta);
