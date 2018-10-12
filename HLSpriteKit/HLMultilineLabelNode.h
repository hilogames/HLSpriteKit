//
//  HLMultilineLabelNode.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 5/11/16.
//  Copyright (c) 2016 Hilo Games. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

/**
 HLMultilineLabelNode is a node capable of displaying multiple lines of text.

 The current implementation works by rendering an image of the text and displaying it in a
 private sprite node.  (Another common implementation, not currently used here, is to
 create one `SKLabelNode` for each line.)

 The interface is similar to `SKLabelNode`; however, see `widthMaximum` to control line
 breaks, and see `anchorPoint` and `alignment` to control vertical and horizontal text
 alignment.

 @bug In iOS 8.4 and earlier, `widthMaximum` works more like a suggestion than a limit.
      Its behavior is determined by `[NSAttributedString
      boundingRectWithSize:options:context:]` which notes

        > However, the actual bounding rectangle returned by this method can be larger
        > than the constraints if additional space is needed to render the entire
        > string. Typically, the renderer preserves the width constraint and adjusts the
        > height constraint as needed.

      In iOS 8.4 and earlier, the width would usually not, in fact, be preserved.
*/

@interface HLMultilineLabelNode : SKNode <NSCoding>

/// @name Creating a Multiline Label Node

/**
 Initializes a new multiline label node.

 The label will not be rendered until `text` is set (and non-empty).
*/
- (instancetype)initWithFontNamed:(NSString *)fontName;

/**
 Initializes a new multiline label node with all render-relevant properties.

 The label will be rendered only once.  This is an efficient way to set multiple
 properties (which would otherwise each separately trigger a render of the label).

 Depending on implementation, the parameters to this method might change.  Therefore this
 version of `init` is to be used by a caller who cares about the rendering performance of
 the current implementation.
*/
- (instancetype)initWithText:(NSString *)text
                widthMaximum:(CGFloat)widthMaximum
          lineHeightMultiple:(CGFloat)lineHeightMultiple
                 lineSpacing:(CGFloat)lineSpacing
                   alignment:(NSTextAlignment)alignment
                    fontName:(NSString *)fontName
                    fontSize:(CGFloat)fontSize
                   fontColor:(SKColor *)fontColor
                      shadow:(NSShadow *)shadow;

/**
 Returns an initialized multiline label node.

 The label will not be rendered until `text` is set (and non-empty).
*/
+ (instancetype)multilineLabelNodeWithFontNamed:(NSString *)fontName;

/// @name Configuring Text

/**
 The text of the multiline label node.

 Default value is `nil`.

 Setting this property results in the label being rendered (if `text` is non-nil and
 non-empty).  To ensure the label isn't rendered repeatedly on multiple property sets,
 either use the version of `init` which sets all render-relevant properites, or else defer
 setting `text` until last.  For example:

     HLMultilineLabelNode *labelNode = [[HLMultilineLabelNode alloc] initWithFontNamed:@"Helvetica"];
     labelNode.fontColor = [SKColor blueColor];
     labelNode.fontSize = 16.0f;
     labelNode.widthMaximum = 100.0f;
     labelNode.text = @"Setting the text last, so that only now will the label render.";
*/
@property (nonatomic, copy) NSString *text;

/// @name Configuring Layout

/**
 The maximum width in points of the multiline label node.

 A value of `0.0` means "no maximum."

 Default value is `0.0`.

 In iOS 9 and later, the configured text will wrap so that no line is longer than the
 maximum width.  In the current implementation, the line will prefer to break on word
 boundaries.  If constrained by a long word, it will not hyphenate, but will break on
 latter boundaries.  If constrained so that even a single letter doesn't fit on the line,
 it will visually truncate the letter.

 Before iOS 9, the `widthMaximum` is more approximate; the label width will be near, but
 not necessarily less than, the maximum.

 Setting this property results in the label being rendered (if `text` is set and
 non-empty).
*/
@property (nonatomic, assign) CGFloat widthMaximum;

/**
 A multiplier for the natural line height of the multiline label node.

 A value of `0.0` means "no multiplier."

 Default value is `0.0`.

 Setting this property results in the label being rendered (if `text` is set and
 non-empty).
*/
@property (nonatomic, assign) CGFloat lineHeightMultiple;

/**
 The distance in points between the bottom of one line and the top of the next.

 A value of `0.0` means "no extra space."

 Default value is `0.0`.

 Setting this property results in the label being rendered (if `text` is set and
 non-empty).
*/
@property (nonatomic, assign) CGFloat lineSpacing;

/**
 The point in the multiline label node, in unit coordinate space, which corresponds to the
 node's position.

 Default value is `(0.5, 0.5)`.

 In the current implementation, setting this property does not result in the label being
 rendered.
*/
@property (nonatomic, assign) CGPoint anchorPoint;

/**
 The text alignment.

 Default value is `NSTextAlignmentCenter`.

 Not all `NSTextAlignment` options may be available on iOS; see documentation.

 Setting this property results in the label being rendered (if `text` is set and
 non-empty).
*/
@property (nonatomic, assign) NSTextAlignment alignment;

/**
 The bounding box size of the rendered multiline label.

 Until `text` is set and non-empty, the node's size will be zero.
*/
@property (nonatomic, readonly) CGSize size;

/// @name Configuring Appearance

/**
 The font used for the text in the multiline label.

 Setting this property results in the label being rendered (if `text` is set and
 non-empty).
*/
@property (nonatomic, copy) NSString *fontName;

/**
 The size in points of the font used in the multiline label.

 Default value is `32.0`.

 Setting this property results in the label being rendered (if `text` is set and
 non-empty).
*/
@property (nonatomic, assign) CGFloat fontSize;

/**
 The color of the text in the multiline label.

 Default value is white.

 Setting this property results in the label being rendered (if `text` is set and
 non-empty).
*/
@property (nonatomic, strong) SKColor *fontColor;

/**
 Shadow parameters for the rendered multiline label; `nil` for no shadow.

 Default value is `nil`.

 Setting this property results in the label being rendered (if `text` is set and
 non-empty).
*/
@property (nonatomic, strong) NSShadow *shadow;

@end
