//
//  UIImage+HLImageAdditions.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 5/31/13.
//  Copyright (c) 2013 Hilo. All rights reserved.
//

#import "UIImage+HLImageAdditions.h"

#include <tgmath.h>

@implementation UIImage (HLImageAdditions)

// note: In all conversions between UIKit and CoreGraphics:
//
//   The default coordinate system used throughout UIKit is different from the coordinate system used by Quartz. In UIKit,
//   the origin is in the upper-left corner, with the positive-y value pointing downward. The UIView object modifies the
//   CTM of the Quartz graphics context to match the UIKit conventions by translating the origin to the upper left corner
//   of the view and inverting the y-axis by multiplying it by -1. For more information on modified-coordinate systems and
//   the implications in your own drawing code, see “Quartz 2D Coordinate Systems.”
//
// Hence the common code after beginning an image context:
//
//   CGContextTranslateCTM(context, 0.0f, imageSize.height);
//   CGContextScaleCTM(context, 1.0, -1.0);

- (UIImage *)scaleToSize:(CGSize)size
{
  UIGraphicsBeginImageContext(size);
  [self drawInRect:CGRectMake(0, 0, size.width, size.height)];
  UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return scaledImage;
}

- (UIImage *)colorizeWithColor:(UIColor *)color
{
  CGSize imageSize = self.size;
  UIGraphicsBeginImageContext(imageSize);
  CGContextRef context = UIGraphicsGetCurrentContext();

  CGContextTranslateCTM(context, 0.0f, imageSize.height);
  CGContextScaleCTM(context, 1.0, -1.0);

  CGRect imageRect = CGRectMake(0.0, 0.0, imageSize.width, imageSize.height);
  CGContextDrawImage(context, imageRect, [self CGImage]);

  CGContextClipToMask(context, imageRect, [self CGImage]);
  CGContextSetBlendMode(context, kCGBlendModeCopy);
  CGContextSetFillColorWithColor(context, [color CGColor]);
  CGContextAddRect(context, imageRect);
  CGContextDrawPath(context, kCGPathFill);

  UIImage *colorizedImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

  return colorizedImage;
}

- (UIImage *)shadowWithColor:(UIColor *)color offset:(CGSize)offset blur:(CGFloat)blur cutout:(BOOL)cutout
{
  CGSize originalImageSize = self.size;
  CGSize shadowedImageSize = CGSizeMake(originalImageSize.width + 2.0f * blur, originalImageSize.height + 2.0f * blur);
  UIGraphicsBeginImageContext(shadowedImageSize);
  CGContextRef context = UIGraphicsGetCurrentContext();

  CGContextTranslateCTM(context, 0.0f, shadowedImageSize.height);
  CGContextScaleCTM(context, 1.0, -1.0);

  CGContextSetShadowWithColor(context, offset, blur, [color CGColor]);
  CGRect imageRect = CGRectMake(blur, blur, originalImageSize.width, originalImageSize.height);
  CGContextDrawImage(context, imageRect, [self CGImage]);

  if (cutout) {
    CGContextSetBlendMode(context, kCGBlendModeDestinationOut);
    CGContextDrawImage(context, imageRect, [self CGImage]);
  }

  UIImage *shadowedImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

  return shadowedImage;
}

- (UIImage *)multiShadowWithOffsetDistance:(CGFloat)offsetDistance shadowCount:(int)shadowCount blur:(CGFloat)blur color:(UIColor *)color cutout:(BOOL)cutout
{
  CGSize originalImageSize = self.size;
  CGSize shadowedImageSize = CGSizeMake(originalImageSize.width + 2.0f * (offsetDistance + blur), originalImageSize.height + 2.0f * (offsetDistance + blur));
  UIGraphicsBeginImageContext(shadowedImageSize);
  CGContextRef context = UIGraphicsGetCurrentContext();
  
  CGContextTranslateCTM(context, 0.0f, shadowedImageSize.height);
  CGContextScaleCTM(context, 1.0, -1.0);

  CGFloat theta = 0.0f;
  CGFloat thetaIncrement = 2.0f * (CGFloat)M_PI / shadowCount;
  CGRect imageRect = CGRectMake(offsetDistance + blur,
                                offsetDistance + blur,
                                originalImageSize.width,
                                originalImageSize.height);
  for (int s = 0; s < shadowCount; ++s) {
    // noob: The type-generic tgmath.h is supposed to make the CGFloat casts unnecessary
    // in a 32-bit environment.  I'm not sure why it's not working.
    CGFloat sinTheta = (CGFloat)sin(theta);
    CGFloat cosTheta = (CGFloat)cos(theta);
    CGContextSetShadowWithColor(context, CGSizeMake(offsetDistance * cosTheta, offsetDistance * sinTheta), blur, [color CGColor]);
    CGContextDrawImage(context, imageRect, [self CGImage]);
    theta += thetaIncrement;
  }

  if (cutout) {
    CGContextSetBlendMode(context, kCGBlendModeDestinationOut);
    CGContextDrawImage(context, imageRect, [self CGImage]);
  }

  UIImage *shadowedImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  
  return shadowedImage;
}

@end
