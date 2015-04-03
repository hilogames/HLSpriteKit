//
//  SKSpriteNode+HLSpriteNodeAdditions.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 4/3/15.
//
//

#import <SpriteKit/SpriteKit.h>

@interface SKSpriteNode (HLSpriteNodeAdditions)

// Convenience Methods for Manipulating Sprite Nodes

/**
 Convenience method for creating a (single) shadow for the sprite node.

 The shadow is returned as a separate node, to be inserted into the node
 tree by the caller as desired.
*/
- (SKNode *)shadowWithColor:(UIColor *)color blur:(CGFloat)blur;

/**
 Convenience method for creating a "multi-shadow" for the sprite node.
 
 The multi-shadow gives a glow or outline effect.  The effect is achieved as follows:
 
   - First, the correct shape is created by copying the sprite node texture multiple
     times at radial offsets from a center point.
     
   - Next, the shape is replaced by the passed color using a crop node.
   
   - Finally, the colorized shape is blurred using an effect node with a Gaussian filter.
   
 @param offset The distance of the offset of the shadows (extending radially from
 the center).

 @param shadowCount The number of shadows drawn.  The first copy is offset in the
 direction of `initialTheta` radians in polar coordinates; the other copies are
 offset at regular subdivisions of the unit circle.  For instance, if
 `initialTheta` is `0` and `shadowCount` is `4`, the shadows will be drawn directly
 right, up, left, and down.
 
 @param initialTheta The direction of the offset of the first shadow, in radians.
 (`0` represents right, and the positive direction is counter-clockwise.)
 
 @param blur The blur radius for the multi-shadow shape.
 
 @param color The color for the multi-shadow shape.
 
 @warning Performance not measured.  Assume this is slow and memory-intensive.
 */
- (SKNode *)multiShadowWithOffset:(CGFloat)offset
                      shadowCount:(int)shadowCount
                     initialTheta:(CGFloat)initialTheta
                            color:(UIColor *)color
                             blur:(CGFloat)blur;

@end
