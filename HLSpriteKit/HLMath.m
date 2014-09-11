//
//  HLMath.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 7/21/14.
//  Copyright (c) 2014 Hilo. All rights reserved.
//

#import "HLMath.h"

#include <tgmath.h>

CGSize
HLGetBoundsForTransformation(CGSize size, CGFloat theta)
{
  // note: These casts back to CGFloat are supposed to be unnecessary because of the
  // type-generic cos() macro defined in tgmath.h.  But without the casts I get
  // loss-of-precision warnings when compiling for 32-bit simulator; I'm not sure who is
  // to blame.
  CGFloat cosTheta = (CGFloat)fabs(cos(theta));
  CGFloat sinTheta = (CGFloat)fabs(sin(theta));
  CGFloat widthRotatedWidth = size.width * cosTheta;
  CGFloat widthRotatedHeight = size.width * sinTheta;
  CGFloat heightRotatedWidth = size.height * sinTheta;
  CGFloat heightRotatedHeight = size.height * cosTheta;
  return CGSizeMake(widthRotatedWidth + heightRotatedWidth,
                    widthRotatedHeight + heightRotatedHeight);
}
