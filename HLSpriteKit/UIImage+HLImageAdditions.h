//
//  UIImage+HLImageAdditions.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 5/31/13.
//  Copyright (c) 2013 Hilo Games. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (HLImageAdditions)

/// @name Convenience Methods for Manipulating Images

/**
 Convenience method for creating a CoreGraphics context, drawing the image scaled to the
 passed size, and returning a new `UIImage` with the result.
*/
- (UIImage *)scaleToSize:(CGSize)size;

/**
 Convenience method for creating a CoreGraphics context, clipping to the image,
 copying in the passsed color, and returning a new `UIImage` with the result.

 note: In iOS7, can use Template Images to achieve same effect with `UIImageViews`.
*/
- (UIImage *)colorizeWithColor:(UIColor *)color;

/**
 Convenience method for creating a CoreGraphics context, setting a shadow, drawing the
 image, and returning a new `UIImage` with the result.

 If cutout is passed `YES`, the original image will be cut out of the resulting image
 before it is returned.
*/
- (UIImage *)shadowWithColor:(UIColor *)color offset:(CGSize)offset blur:(CGFloat)blur cutout:(BOOL)cutout;

/**
 Convenience method for creating a CoreGraphics context, redrawing multiple shadowed
 copies of the image at radial offsets from the image's center, and returning a new `UIImage`
 with the result.

 The effect is something like an outline or glow (depending on how blurred the shadows
 are).  Uses `CGContextSetShadowWithColor`.

 @param offsetDistance The distance of the offset of the shadows (extending radially from
                       the center of the image).

 @param shadowCount The number of shadows drawn.  The first copy is offset in the
                    direction of zero radians in polar coordinates; the other copies are
                    offset at regular subdivisions of the unit circle.  For instance, if
                    the value of the parameter is `4`, the shadows will be drawn directly
                    left, right, up, and down.

 @param blur The blur for the shadows.

 @param color The color for the shadows.

 @param cutout Whether or not the original image is cut out of the resulting image before
               it is returned.

 @warning Performance not measured.  Assume this is slow, especially with increasing
          `shadowCount`.
*/
- (UIImage *)multiShadowWithOffsetDistance:(CGFloat)offsetDistance shadowCount:(int)shadowCount blur:(CGFloat)blur color:(UIColor *)color cutout:(BOOL)cutout;

@end
