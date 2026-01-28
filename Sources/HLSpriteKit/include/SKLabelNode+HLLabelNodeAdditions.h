//
//  SKLabelNode+HLLabelNodeAdditions.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 6/3/14.
//  Copyright (c) 2014 Hilo Games. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

/**
 A height mode used when aligning text vertically.

 See `getVerticalAlignmentForAlignmentMode:heightMode:useAlignmentMode:labelHeight:offsetY:`
 for details.
*/
typedef NS_ENUM(NSInteger, HLLabelHeightMode) {
  /**
   Measure the label using the exact height of the current text (for example, not
   including the font descender if the current text has no descending characters).
  */
  HLLabelHeightModeText,
  /**
   Measure the label using the full height of the font (regardless of the current text,
   and including both ascender and descender).
  */
  HLLabelHeightModeFont,
  /**
   Measure the label using the full ascender of the font, but excluding the descender
   (regardless of the current text).
  */
  HLLabelHeightModeFontAscender,
  /**
   Measure the label using the full ascender of the font and a portion of the descender
   (regardless of the current text).
  */
  HLLabelHeightModeFontAscenderBias,
};

/**
 A truncation mode used when truncating text.
*/
typedef NS_ENUM(NSInteger, HLLabelTruncationMode) {
  /**
   Do not truncate.
  */
  HLLabelTruncationModeNone,
  /**
   Truncate the text at a particular character index.
  */
  HLLabelTruncationModeIndexed,
  /**
   Trunate the text at the beginning.
  */
  HLLabelTruncationModeHead,
  /**
   Trunate the text in the middle.
  */
  HLLabelTruncationModeMiddle,
  /**
   Trunate the text at the end.
  */
  HLLabelTruncationModeTail,
};

@interface SKLabelNode (HLLabelNodeAdditions)

/// @name Calculating Vertical Alignment

/**
 Returns the vertical offset, in points, of a label's font baseline from the visual
 center position of the label according to the height mode.

 This is addressing a similar problem as `getVerticalAlignmentForAlignmentMode:`, but in a
 simplified form.  This method answers the following question:

    > I have a label that I would like to visually center at a given `y`.  How far from
    > that `y` should I position the label's baseline?

 The height mode describes what should be considered "visually centered".  For instance if
 the height mode is `HLLabelHeightModeFont`, then the returned offset shifts the baseline
 (probably down) so that the full line height of the font is centered.

 (Try `HLLabelHeightModeFontAscenderBias` for a pleasing alternative.)

 To position a label according to the returned offset, set its `verticalAlignmentMode` to
 `SKLabelVerticalAlignmentModeBaseline` and add the offset to its `position.y`.
 Alternately, call `alignVerticalWithAlignmentMode:heightMode`, passing center-alignment
 for the first parameter.

 Note: Returns `0.0` if `heightMode` is `HLLabelHeightModeText`.  This is not the correct
 answer, but: 1) I'm too stupid to know how to calculate the correct answer; and 2) If you
 want to visually center by text-height, you can use `SKVerticalAlignmentModeCenter`, and
 forget all this baseline-and-offset stuff.
*/
+ (CGFloat)baselineOffsetYFromVisualCenterForHeightMode:(HLLabelHeightMode)heightMode
                                               fontName:(NSString *)fontName
                                               fontSize:(CGFloat)fontSize;

/**
 Convenience method for `baselineOffsetYFromVisualCenterForHeightMode:fontName:fontSize:`
 using the font name and size from this label.
*/
- (CGFloat)baselineOffsetYFromVisualCenterForHeightMode:(HLLabelHeightMode)heightMode;

/**
 Returns the inset, in unit coordinate space, of a label's font baseline from the bottom
 of the label according to the height mode.

 See `baselineOffsetYFromVisualCenterForHeightMode:fontName:fontSize`.  This method is
 answering the same question, but in terms of a relative (unit coordinate space) inset
 from the bottom rather than an absolute (point coordinate space) offset from the center.

 By example:

                             ___ A) top according to height mode "ascender bias"
             |
             | _   o   o
             |/ \  |   |     --- A) center according to height mode "ascender bias"
             |  |  |   |     ___ B) baseline
                       |     ___ C) bottom according to height mode "ascender bias"
                     \_/

 The height mode "ascender bias" uses font metrics to count half of the descender; in the
 illustration, the bottom (C) is below the "h" and "i" glyph bottom, but above the "j"
 glyph bottom.  The baseline offset method returns the offset from (A) to (B), in points;
 this method returns the inset from (C) to (B), as a fraction of the total height (A) to
 (C).

 The offset is typically more useful, but the inset can be used in places where
 anchor-point type positioning is required or appropriate.

 Note: Returns `0.0` if `heightMode` is `HLLabelHeightModeText`.  This is not the correct
 answer, but: 1) I'm too stupid to know how to calculate the correct answer; and 2) If you
 want to visually center by text-height, you can use `SKVerticalAlignmentModeCenter`, and
 forget all this baseline-and-inset stuff.
*/
+ (CGFloat)baselineInsetYFromBottomForHeightMode:(HLLabelHeightMode)heightMode
                                        fontName:(NSString *)fontName
                                        fontSize:(CGFloat)fontSize;

/**
 Convenience method for `baselineInsetYFromBottomForHeightMode:fontName:fontSize:` using
 the font name and size from this label.
*/
- (CGFloat)baselineInsetYFromBottomForHeightMode:(HLLabelHeightMode)heightMode;

/**
 Returns the label height as calculated by other methods in this module, most notably
 `getVerticalAlignmentForAlignmentMode:heightMode:useAlignmentMode:labelHeight:offsetY:`.

 Note: Returns `0.0` if `heightMode` is `HLLabelHeightModeText`.  The label height, in
 this case, depends on the text of the label.  Use `labelHeightForHeightMode:` to get a
 better answer.
*/
+ (CGFloat)labelHeightForHeightMode:(HLLabelHeightMode)heightMode
                           fontName:(NSString *)fontName
                           fontSize:(CGFloat)fontSize;

/**
 Returns label height for this label as calculated by other methods in this module.

 If `heightMode` is `HLLabelHeightModeText`, then a height based on the current `text` of
 the `SKLabelNode` is returned.  Otherwise this is merely a convenience method for
 `labelHeightForHeightMode:fontName:fontSize:` using the font name and size from this
 label.
*/
- (CGFloat)labelHeightForHeightMode:(HLLabelHeightMode)heightMode;

/**
 Gets vertical alignment parameters for this `SKLabelNode` when aligning using
 a combination of `SKLabelVerticalAlignmentMode` and `HLLabelHeightMode`.

 For a passed alignment mode and height mode, this method calculates a vertical
 alignment mode and a vertical position offset for the label.

 This method does not change any properties of its label.  To align the label as
 intended, use convenience method `alignVerticalWithAlignmentMode`, which sets the label's
 `verticalAlignmentMode` and `position` properties according to the results of this
 method.

 ## Discussion

 This kind of alignment is most useful when trying to align text within an enclosing box.

 See the Example project included with some `HLSpriteKit` distributions for visual
 illustration of the various vertical alignment and height modes.

 `SKLabelVerticalAlignmentMode` permits baseline, top, center, or bottom alignment.  In
 a paragraph of text, baseline alignment is the norm.  Baseline alignment is also most
 common when text is broken up into multiple aligned labels, for example:

             Object: Widget
              Color: Blue
               Size: 10

 When positioning text in enclosing boxes, baseline alignment is still good, but there
 is usually an additional challenge: Keeping the text more-or-less visually centered in
 the enclosing box.  Consider trying to layout a toolbar of text buttons:

         +----------+   +--------------+   +-------------+
         |   mano   |   |   slotifab   |   |   yapgaxp   |
         +----------+   +--------------+   +-------------+

 Each text label has a different height because of its mix of descenders and ascenders.
 Using `SKLabelVerticalAlignmentMode` does a good job with the visual centering of the
 various heights, but of course then the baselines are unaligned, which in most
 applications looks bad.

 So again, baseline alignment is good.  But where to put the baseline?

   - The center of the box?  No, too high.

   - The bottom of the box?  Clearly too low.

   - One-third of the way up from the bottom of the box?  Good for some fonts.  Not so
     good for others.

 This method attempts to solve the problem by using an additional parameter to do
 vertical alignment: in addition to an `SKLabelVerticalAlignmentMode`, it requires an
 `HLLabelHeightMode`.  Examples:

   - Height mode "ascender" with alignment mode "center".  This centers only the ascender
     portion of the font (regardless of the current text of each label).  This can look
     good when ascenders dominate:

         +----------+   +--------------+   +-------------+
         |   MANO   |   |   SLOTIFAB   |   |   YAPGAXP   |
         +----------+   +--------------+   +-------------+

     On the other hand, fonts tend to claim more space for their ascenders than is used
     by most glyphs, so this often looks too empty above the text.

   - Height mode "font" with alignment mode "center".  This centers the full height of the
     font (regardless of the current text of each label).  This can look good with mixed
     ascenders and descenders:

         +----------+   +--------------+   +-------------+
         |   Mano   |   |   Slotifab   |   |   Yapgaxp   |
         +----------+   +--------------+   +-------------+

     In English, though, ascenders tend to dominate, and extra room reserved for
     descenders is more noticeable than extra room reserved for ascenders.  So depending
     on the font, this alignment can leave the labels looking too high in their boxes.

   - Height mode "ascender-bias" with alignment mode "center".  Like "font", this centers
     using the height of the font (regardless of label text), but when calculating the
     height of the font, the descender is discounted.  This can look good with mixed
     ascenders and descenders, but where the descenders are less prevalent.

   - Alignment modes "top" and "bottom" don't affect how the label height is calculated,
     but allow you to handle the labels using a different anchor point, if that's useful.

 Not all combinations of vertical alignment mode and height mode are useful, but this
 method is parameterized this way for maximum compatibility with normal SpriteKit
 alignment.  Two examples:

   - When using height mode `HLLabelHeightModeText`, all alignments are the same as just
     setting the label's `verticalAlignmentMode` property with no offset.

   - Height mode "ascender" with alignment mode "bottom" is the same as normal SpriteKit
     baseline alignment.  (Although the returned `labelHeight` might be useful for
     calculating a consistent enclosing box size.)

 Note that most height modes cause baseline alignment of text regardless of alignment
 mode.  But perhaps some alternate height modes will prove useful: A height halfway
 between font height and current text height, so that baselines move a little bit based on
 current text?
*/
- (void)getVerticalAlignmentForAlignmentMode:(SKLabelVerticalAlignmentMode)verticalAlignmentMode
                                  heightMode:(HLLabelHeightMode)heightMode
                            useAlignmentMode:(SKLabelVerticalAlignmentMode *)useVerticalAlignmentMode
                                 labelHeight:(CGFloat *)labelHeight
                                     offsetY:(CGFloat *)offsetY;

/**
 Convenience method for calculating an alignment and setting label properties according to
 the results.

 In particular, this method sets the `verticalAlignmentMode` of the label, and offsets the
 label's `position.y`.

 See `getVerticalAlignmentMode:heightMode:useAlignmentMode:labelHeight:offsetY` for
 information on calculating the alignment.
*/
- (void)alignVerticalWithAlignmentMode:(SKLabelVerticalAlignmentMode)verticalAlignmentMode
                            heightMode:(HLLabelHeightMode)heightMode;

/**
 Sets the `text` property of this label to the given text, perhaps reducing font size
 according to the parameters.
*/
- (void)setText:(NSString *)text
   widthMaximum:(CGFloat)widthMaximum
fontSizePreferred:(CGFloat)fontSizePreferred
fontSizeMinimum:(CGFloat)fontSizeMinimum;

/**
 Sets the `text` property of this label to the given text, perhaps truncating it according
 to the parameters.

 The text is truncated to something less than or equal to the specified `widthMaximum`,
 if possible; an ellipsis is inserted in place of the removed characters.

 See `HLLabelTruncationMode` for details about how the text is truncated.
*/
- (void)setText:(NSString *)text
   widthMaximum:(CGFloat)widthMaximum
 truncationMode:(HLLabelTruncationMode)truncationMode
truncationIndex:(NSUInteger)truncationIndex;

/**
 Sets the `text` property of this label to the given text, perhaps reducing font size
 or truncating it according to the parameters.

 Font size reduction is prioritized over truncation.

 See `setText:WidthMaximum:fontSizePreferred:fontSizeMinimum:` and
 `setText:widthMaximum:truncationMode:truncationIndex:` for details.
*/
- (void)setText:(NSString *)text
   widthMaximum:(CGFloat)widthMaximum
fontSizePreferred:(CGFloat)fontSizePreferred
fontSizeMinimum:(CGFloat)fontSizeMinimum
 truncationMode:(HLLabelTruncationMode)truncationMode
truncationIndex:(NSUInteger)truncationIndex;

@end
