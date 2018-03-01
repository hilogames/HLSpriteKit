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

- (CGFloat)baselineOffsetYFromVisualCenterForHeightMode:(HLLabelHeightMode)heightMode
{
  return [SKLabelNode baselineOffsetYFromVisualCenterForHeightMode:heightMode
                                                          fontName:self.fontName
                                                          fontSize:self.fontSize];
}

+ (CGFloat)baselineOffsetYFromVisualCenterForHeightMode:(HLLabelHeightMode)heightMode
                                               fontName:(NSString *)fontName
                                               fontSize:(CGFloat)fontSize
{
  // note: For the record: I have no idea about the performance of this, especially
  // if dealing with lots of labels that may or may not share the same font name
  // and font size.

  if (heightMode == HLLabelHeightModeText) {
    // See note in header.  This is not the correct answer, but I don't know how to
    // calculate the correct answer, and this height mode is not relevant to the problem
    // addressed by this method, so I'm too lazy to learn how to calculate the correct
    // answer.
    return 0.0f;
  }

#if TARGET_OS_IPHONE
  UIFont *font = [UIFont fontWithName:fontName size:fontSize];
#else
  NSFont *font = [NSFont fontWithName:fontName size:fontSize];
#endif
  if (!font) {
    [NSException raise:@"HLLabelNodeUnknownFont" format:@"Could not find font \"%@\".", fontName];
  }

  CGFloat offsetY = 0.0;
  switch (heightMode) {
    case HLLabelHeightModeText:
      // note: Already handled above.
      break;
    case HLLabelHeightModeFont:
      offsetY = -font.ascender / 2.0f - font.descender / 2.0f;
      break;
    case HLLabelHeightModeFontAscender:
      offsetY = -font.ascender / 2.0f;
      break;
    case HLLabelHeightModeFontAscenderBias:
      // note: Ascender bias leaves room for the full ascender plus half of the descender
      // (keep in mind font.descender metric is a negative offset).  This is arbitrary.
      // note: Find bottom of line, then go up by half the descender.
      // Simplifies -(a - d/2)/2 - d/2 = -a/2 - d/4
      offsetY = -font.ascender / 2.0f - font.descender / 4.0f;
      break;
  }

  return offsetY;
}

- (CGFloat)baselineInsetYFromBottomForHeightMode:(HLLabelHeightMode)heightMode
{
  return [SKLabelNode baselineInsetYFromBottomForHeightMode:heightMode
                                                   fontName:self.fontName
                                                   fontSize:self.fontSize];
}

+ (CGFloat)baselineInsetYFromBottomForHeightMode:(HLLabelHeightMode)heightMode
                                        fontName:(NSString *)fontName
                                        fontSize:(CGFloat)fontSize
{
  // note: For the record: I have no idea about the performance of this, especially
  // if dealing with lots of labels that may or may not share the same font name
  // and font size.

  if (heightMode == HLLabelHeightModeText) {
    // See note in header.  This is not the correct answer, but I don't know how to
    // calculate the correct answer, and this height mode is not relevant to the problem
    // addressed by this method, so I'm too lazy to learn how to calculate the correct
    // answer.
    return 0.0f;
  }

#if TARGET_OS_IPHONE
  UIFont *font = [UIFont fontWithName:fontName size:fontSize];
#else
  NSFont *font = [NSFont fontWithName:fontName size:fontSize];
#endif
  if (!font) {
    [NSException raise:@"HLLabelNodeUnknownFont" format:@"Could not find font \"%@\".", fontName];
  }

  CGFloat insetY = 0.0;
  switch (heightMode) {
    case HLLabelHeightModeText:
      // note: Already handled above.
      break;
    case HLLabelHeightModeFont:
      insetY = -font.descender / (font.ascender - font.descender);
      break;
    case HLLabelHeightModeFontAscender:
      insetY = 0.0f;
      break;
    case HLLabelHeightModeFontAscenderBias:
      // note: Ascender bias leaves room for the full ascender plus half of the descender
      // (keep in mind font.descender metric is a negative offset).  This is arbitrary.
      // Height of line is considered to be (a - d/2); the part that is considered to be
      // below the baseline is only (-d/2).
      // Simplifies: (-d/2) / (a - d/2) = -d / (2a - d)
      insetY = -font.descender / (font.ascender * 2.0f - font.descender);
      break;
  }

  return insetY;
}

- (void)getVerticalAlignmentForAlignmentMode:(SKLabelVerticalAlignmentMode)verticalAlignmentMode
                                  heightMode:(HLLabelHeightMode)heightMode
                            useAlignmentMode:(SKLabelVerticalAlignmentMode *)useVerticalAlignmentMode
                                 labelHeight:(CGFloat *)labelHeight
                                     offsetY:(CGFloat *)offsetY
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
    if (offsetY) {
      *offsetY = 0.0f;
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
      if (offsetY) {
        switch (verticalAlignmentMode) {
          case SKLabelVerticalAlignmentModeTop:
            *offsetY = -font.ascender;
            break;
          case SKLabelVerticalAlignmentModeBottom:
            *offsetY = -font.descender;
            break;
          case SKLabelVerticalAlignmentModeCenter:
            *offsetY = -font.ascender / 2.0f - font.descender / 2.0f;
            break;
          case SKLabelVerticalAlignmentModeBaseline:
            *offsetY = 0.0f;
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
      if (offsetY) {
        switch (verticalAlignmentMode) {
          case SKLabelVerticalAlignmentModeTop:
            *offsetY = -font.ascender;
            break;
          case SKLabelVerticalAlignmentModeBottom:
            *offsetY = 0.0f;
            break;
          case SKLabelVerticalAlignmentModeCenter:
            *offsetY = -font.ascender / 2.0f;
            break;
          case SKLabelVerticalAlignmentModeBaseline:
            *offsetY = 0.0f;
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
      if (offsetY) {
        switch (verticalAlignmentMode) {
          case SKLabelVerticalAlignmentModeTop:
            *offsetY = -font.ascender;
            break;
          case SKLabelVerticalAlignmentModeBottom:
            *offsetY = -font.descender / 2.0f;
            break;
          case SKLabelVerticalAlignmentModeCenter:
            // note: Using full ascender and half descender as the considered height of
            // the font: (a - d/2).  Start at the visual center and find the offset to the
            // baseline: go down half the line height and then back up by half the
            // descender; that's where the basline should go.
            // Simplifies -(a - d/2)/2 - d/2 = -a/2 - d/4
            *offsetY = -font.ascender / 2.0f - font.descender / 4.0f;
            break;
          case SKLabelVerticalAlignmentModeBaseline:
            *offsetY = 0.0f;
            break;
        }
      }
      break;
  }
}

- (void)alignVerticalWithAlignmentMode:(SKLabelVerticalAlignmentMode)verticalAlignmentMode
                            heightMode:(HLLabelHeightMode)heightMode
{
  CGFloat offsetY;
  SKLabelVerticalAlignmentMode useVerticalAlignmentMode;
  [self getVerticalAlignmentForAlignmentMode:verticalAlignmentMode
                                  heightMode:heightMode
                            useAlignmentMode:&useVerticalAlignmentMode
                                 labelHeight:nil
                                     offsetY:&offsetY];
  self.verticalAlignmentMode = useVerticalAlignmentMode;
  CGPoint position = self.position;
  position.y += offsetY;
  self.position = position;
}

@end
