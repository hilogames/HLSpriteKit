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
  // type-generic cos() macro defined in tgmath.h.  But without the casts I I get
  // loss-of-precision warnings when compiling for 32-bit simulator; I'm not sure who is
  // to blame.
  CGFloat widthRotatedWidth = size.width * (CGFloat)cos(theta);
  CGFloat widthRotatedHeight = size.width * (CGFloat)sin(theta);
  CGFloat heightRotatedWidth = size.height * (CGFloat)sin(theta);
  CGFloat heightRotatedHeight = size.height * (CGFloat)cos(theta);
  return CGSizeMake(widthRotatedWidth + heightRotatedWidth,
                    widthRotatedHeight + heightRotatedHeight);
}
