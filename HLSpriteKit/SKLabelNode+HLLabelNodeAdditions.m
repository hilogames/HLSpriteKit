//
//  SKLabelNode+HLLabelNodeAdditions.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 6/3/14.
//  Copyright (c) 2014 Hilo Games. All rights reserved.
//

#import "SKLabelNode+HLLabelNodeAdditions.h"

@implementation SKLabelNode (HLLabelNodeAdditions)

- (void)getAlignmentForHLVerticalAlignmentMode:(HLLabelNodeVerticalAlignmentMode)hlVerticalAlignmentMode
                       skVerticalAlignmentMode:(SKLabelVerticalAlignmentMode *)skVerticalAlignmentMode
                                   labelHeight:(CGFloat *)labelHeight
                                     yPosition:(CGFloat *)yPosition
{
  // note: For the record: I have no idea about the performance of this, especially
  // if dealing with lots of labels that may or may not share the same font name
  // and font size.

  switch (hlVerticalAlignmentMode) {

    case HLLabelNodeVerticalAlignText:
      if (skVerticalAlignmentMode) {
        *skVerticalAlignmentMode = SKLabelVerticalAlignmentModeCenter;
      }
      if (labelHeight) {
        *labelHeight = self.frame.size.height;
      }
      if (yPosition) {
        *yPosition = 0.0f;
      }
      break;

    case HLLabelNodeVerticalAlignFont: {
      UIFont *font = [UIFont fontWithName:self.fontName size:self.fontSize];
      if (skVerticalAlignmentMode) {
        *skVerticalAlignmentMode = SKLabelVerticalAlignmentModeBaseline;
      }
      if (labelHeight) {
        *labelHeight = font.lineHeight;
      }
      if (yPosition) {
        *yPosition = -font.lineHeight / 2.0f - font.descender;
      }
      break;
    }
      
    case HLLabelNodeVerticalAlignFontAscender: {
      UIFont *font = [UIFont fontWithName:self.fontName size:self.fontSize];
      if (skVerticalAlignmentMode) {
        *skVerticalAlignmentMode = SKLabelVerticalAlignmentModeBaseline;
      }
      if (labelHeight) {
        *labelHeight = font.ascender;
      }
      if (yPosition) {
        *yPosition = -font.ascender / 2.0f;
      }
      break;
    }

    case HLLabelNodeVerticalAlignFontAscenderBias: {
      UIFont *font = [UIFont fontWithName:self.fontName size:self.fontSize];
      if (skVerticalAlignmentMode) {
        *skVerticalAlignmentMode = SKLabelVerticalAlignmentModeBaseline;
      }
      if (labelHeight) {
        *labelHeight = font.ascender + font.descender / 2.0f;
      }
      if (yPosition) {
        *yPosition = -font.ascender / 2.0f - font.descender / 4.0f;
      }
      break;
    }

    default:
      [NSException raise:@"HLLabelNodeUnknownVerticalAlignmentMode" format:@"Unknown vertical alignment mode %ld.", (long)hlVerticalAlignmentMode];
  }
}

@end
