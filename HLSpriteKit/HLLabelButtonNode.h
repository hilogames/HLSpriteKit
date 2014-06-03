//
//  HLLabelButtonNode.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 5/2/14.
//  Copyright (c) 2014 Hilo. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface HLLabelButtonNode : SKNode <NSCopying, NSCoding>

@property (nonatomic, copy) NSString *text;

@property (nonatomic, assign) CGSize size;

/**
 * Specifies if the button should automatically set its width and height
 * based on the label.
 */
@property (nonatomic, assign) BOOL automaticWidth;
@property (nonatomic, assign) BOOL automaticHeight;

/**
 * Specifies how to calculate the label text height and center when
 * sizing the button and/or centering the text within the button
 * (depending on the value of automaticHeight).  The options are:
 *
 *   HLLabelButtonNodeVerticalAlignText.  Measure the label using the
 *   exact height of the current text (for example, not including the
 *   font descender if the current text has no descending characters).
 *   Align the label by the center of that height.
 *
 *   HLLabelButtonNodeVerticalAlignFont.  Measure the label using the
 *   full height of the font (regardless of the current text, and
 *   including both ascender and descender).  Align the label by the
 *   center of that height.  This means that the location of the
 *   baseline won't change depending on the current text; space will be
 *   reserved for ascenders and descenders.
 *
 *   HLLabelButtonNodeVerticalAlignFontAscender.  Measure the label using
 *   the full ascender of the font, but excluding the descender (regardless
 *   of the current text).  Align the label by the center of that height.
 *   This means that the location of the baseline won't change depending
 *   on the current text; space will be reserved for ascenders; any
 *   descenders in the current text will extend down below the space
 *   reserved for the label.
 *
 * sizing the button (in case automaticHeight is true) or centering the
 * text Specifies whether to use fixed font metrics or the current text
 * when calculating the label's height.  This will affect the height
 * of the overall button if property automaticHeight is YES, or the
 * centering of the label (within the button) if automaticHeight is NO.
 */
typedef enum HLLabelButtonNodeVerticalAlignmentMode {
  HLLabelButtonNodeVerticalAlignText,
  HLLabelButtonNodeVerticalAlignFont,
  HLLabelButtonNodeVerticalAlignFontAscender,
} HLLabelButtonNodeVerticalAlignmentMode;
@property (nonatomic, assign) HLLabelButtonNodeVerticalAlignmentMode verticalAlignmentMode;

/**
 * The amount of space, when using automatic height or automatic width,
 * to leave between the label and the edge of the button.
 */
@property (nonatomic, assign) CGFloat labelPadX;
@property (nonatomic, assign) CGFloat labelPadY;

@property (nonatomic, copy) NSString *fontName;

@property (nonatomic, assign) CGFloat fontSize;

@property (nonatomic, strong) SKColor *fontColor;

@property (nonatomic, strong) SKColor *color;

@property (nonatomic, assign) CGFloat colorBlendFactor;

@property (nonatomic, assign) CGRect centerRect;

- (id)initWithColor:(UIColor *)color size:(CGSize)size;

- (id)initWithTexture:(SKTexture *)texture;

- (id)initWithImageNamed:(NSString *)name;

@end
