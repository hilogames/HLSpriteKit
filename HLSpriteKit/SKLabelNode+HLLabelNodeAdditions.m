//
//  SKLabelNode+HLLabelNodeAdditions.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 6/3/14.
//  Copyright (c) 2014 Hilo Games. All rights reserved.
//

#import "SKLabelNode+HLLabelNodeAdditions.h"

#import <TargetConditionals.h>

@implementation SKLabelNode (HLLabelNodeAdditions)

- (void)getVerticalAlignmentForAlignmentMode:(SKLabelVerticalAlignmentMode)verticalAlignmentMode
                                  heightMode:(HLLabelHeightMode)heightMode
                            useAlignmentMode:(SKLabelVerticalAlignmentMode *)useVerticalAlignmentMode
                                 labelHeight:(CGFloat *)labelHeight
                                     yOffset:(CGFloat *)yOffset
{
  // note: For the record: I have no idea about the performance of this, especially
  // if dealing with lots of labels that may or may not share the same font name
  // and font size.

  if (heightMode == HLLabelHeightModeText) {
    if (useVerticalAlignmentMode) {
      *useVerticalAlignmentMode = verticalAlignmentMode;
    }
    if (labelHeight) {
      *labelHeight = self.frame.size.height;
    }
    if (yOffset) {
      *yOffset = 0.0f;
    }
    return;
  }

#if TARGET_OS_IPHONE
  UIFont *font = [UIFont fontWithName:self.fontName size:self.fontSize];
#else
  NSFont *font = [NSFont fontWithName:self.fontName size:self.fontSize];
#endif
  if (!font) {
    [NSException raise:@"HLLabelNodeUnknownFont" format:@"Could not find font \"%@\".", self.fontName];
  }

  switch (heightMode) {

    case HLLabelHeightModeText:
      // note: Already handled above.
      break;

    case HLLabelHeightModeFont:
      if (useVerticalAlignmentMode) {
        *useVerticalAlignmentMode = SKLabelVerticalAlignmentModeBaseline;
      }
      if (labelHeight) {
        *labelHeight = font.ascender - font.descender;
      }
      if (yOffset) {
        switch (verticalAlignmentMode) {
          case SKLabelVerticalAlignmentModeTop:
            *yOffset = -font.ascender;
            break;
          case SKLabelVerticalAlignmentModeBottom:
            *yOffset = -font.descender;
            break;
          case SKLabelVerticalAlignmentModeCenter:
            *yOffset = -font.ascender / 2.0f - font.descender / 2.0f;
            break;
          case SKLabelVerticalAlignmentModeBaseline:
            *yOffset = 0.0f;
            break;
        }
      }
      break;

    case HLLabelHeightModeFontAscender:
      if (useVerticalAlignmentMode) {
        *useVerticalAlignmentMode = SKLabelVerticalAlignmentModeBaseline;
      }
      if (labelHeight) {
        *labelHeight = font.ascender;
      }
      if (yOffset) {
        switch (verticalAlignmentMode) {
          case SKLabelVerticalAlignmentModeTop:
            *yOffset = -font.ascender;
            break;
          case SKLabelVerticalAlignmentModeBottom:
            *yOffset = 0.0f;
            break;
          case SKLabelVerticalAlignmentModeCenter:
            *yOffset = -font.ascender / 2.0f;
            break;
          case SKLabelVerticalAlignmentModeBaseline:
            *yOffset = 0.0f;
            break;
        }
      }
      break;

    case HLLabelHeightModeFontAscenderBias:
      // note: Ascender bias leaves room for the full ascender plus half of the descender
      // (keep in mind font.descender metric is a negative offset).  This is arbitrary.
      if (useVerticalAlignmentMode) {
        *useVerticalAlignmentMode = SKLabelVerticalAlignmentModeBaseline;
      }
      if (labelHeight) {
        *labelHeight = font.ascender - font.descender / 2.0f;
      }
      if (yOffset) {
        switch (verticalAlignmentMode) {
          case SKLabelVerticalAlignmentModeTop:
            *yOffset = -font.ascender;
            break;
          case SKLabelVerticalAlignmentModeBottom:
            *yOffset = -font.descender / 2.0f;
            break;
          case SKLabelVerticalAlignmentModeCenter:
            // note: Find bottom of line, then go up by half the descender.
            // Simplifies -(a - d/2)/2 - d/2 = -a/2 - d/4
            *yOffset = -font.ascender / 2.0f - font.descender / 4.0f;
            break;
          case SKLabelVerticalAlignmentModeBaseline:
            *yOffset = 0.0f;
            break;
        }
      }
      break;
      break;
  }
}

- (void)alignVerticalWithAlignmentMode:(SKLabelVerticalAlignmentMode)verticalAlignmentMode
                            heightMode:(HLLabelHeightMode)heightMode
{
  CGFloat yOffset;
  SKLabelVerticalAlignmentMode useVerticalAlignmentMode;
  [self getVerticalAlignmentForAlignmentMode:verticalAlignmentMode
                                  heightMode:heightMode
                            useAlignmentMode:&useVerticalAlignmentMode
                                 labelHeight:nil
                                     yOffset:&yOffset];
  self.verticalAlignmentMode = useVerticalAlignmentMode;
  CGPoint position = self.position;
  position.y += yOffset;
  self.position = position;
}

@end
