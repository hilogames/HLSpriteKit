//
//  SKLabelNode+HLLabelNodeAdditions.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 6/3/14.
//  Copyright (c) 2014 Hilo Games. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

/**
 A vertical alignment mode which can measure a label not only by its current size (based
 on its current text) but alternately by its inherent font metrics.

 In particular, these alignments are helpful when aligning a label node to a background
 which must appear to frame the text in the label; and even more particularly, when the
 text might change (or be visually compared to other such labels-plus-background).  For
 example, the caller might want to leave space in the background for the font descender
 even if the current label contains no descenders.
*/
typedef NS_ENUM(NSInteger, HLLabelNodeVerticalAlignmentMode) {
  /**
   Measure the label using the exact height of the current text (for example, not
   including the font descender if the current text has no descending characters).  Align
   the label by the center of that height.
  */
  HLLabelNodeVerticalAlignText,
  /**
   Measure the label using the full height of the font (regardless of the current text,
   and including both ascender and descender).  Align the label by the center of that
   height.  This means that the location of the baseline won't change depending on the
   current text; space will be reserved for ascenders and descenders.
  */
  HLLabelNodeVerticalAlignFont,
  /**
   Measure the label using the full ascender of the font, but excluding the descender
   (regardless of the current text).  Align the label by the center of that height.  This
   means that the location of the baseline won't change depending on the current text;
   space will be reserved for ascenders; any descenders in the current text will extend
   down below the space reserved for the label.  (This might be useful for all-caps text.)
  */
  HLLabelNodeVerticalAlignFontAscender,
  /**
   Partway between using the entire font height (including descender) and using only the
   ascender.  Can be useful where you want room for the descender, for instance for
   mixed-case text, and yet the full font height just seems to leave a little too much
   space below the baseline.
  */
  HLLabelNodeVerticalAlignFontAscenderBias
};

@interface SKLabelNode (HLLabelNodeAdditions)

/// @name Calculating Vertical Alignment

/**
 Gets alignment parameters for this `SKLabelNode` to be used when aligning vertically by
 `HLLabelNodeVerticalAlignmentMode`.

 See `HLLabelNodeVerticalAlignmentMode` for details.

 ### Example
 
 Say you have two label nodes.  The first has no descenders: its text is "bdfhklt".
 The second has no ascenders: "gpqy".  You wisely choose a vertical alignment of
 `SKLabelVerticalAlignmentModeBaseline`.
 
 Now the baseline of the label nodes can be set, and they will line up.  You want
 the labels to appear centered within a red background message bar.  Where should
 you position the baseline?  You try putting it in the (vertical) center of the
 bar.  It seems way too high, because for your font the ascenders are much taller
 than the descenders.  So you lower it.  But...by how much?
 
 This method can help.  Choose your alignment mode from `HLLableNodeVerticalAlignmentMode`,
 then set the position of your label according to the (vertical) center of where you
 want it.  Then add the returned `yOffset` to the y-position, and use the returned
 `skVerticalAlignmentMode` as the label's `verticalAlignmentMode`.
*/
- (void)getAlignmentForHLVerticalAlignmentMode:(HLLabelNodeVerticalAlignmentMode)hlVerticalAlignmentMode
                       skVerticalAlignmentMode:(SKLabelVerticalAlignmentMode *)skVerticalAlignmentMode
                                   labelHeight:(CGFloat *)labelHeight
                                       yOffset:(CGFloat *)yOffset;

/**
 Sets alignment parameters for an `SKLabelNode`.
 
 Sets the label's `verticalAlignmentMode` and adds an offset to the label's y-position,
 depending on the value of the passed `HLLabelNodeVerticalAlignmentNode`.
 
 See `HLLabelNodeVerticalAlignmentMode` for details.
*/
- (void)alignForHLVerticalAlignmentMode:(HLLabelNodeVerticalAlignmentMode)hlVerticalAlignmentMode;

@end
