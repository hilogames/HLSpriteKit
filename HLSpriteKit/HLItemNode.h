//
//  HLItemNode.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 6/5/15.
//  Copyright (c) 2015 Hilo Games. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

#import "HLComponentNode.h"

/**
 A base class defining an interface (and simple implementation) for an "item" in a
 collection of items.

 The name is horribly vague, but the idea is this: The item defines button-like or
 tool-like behavior in a menu, toolbar, button bar, or popup.  It tracks state typical of
 such things, such as "enabled" and "highlight".  It has content.
*/
@interface HLItemNode : HLComponentNode <NSCopying, NSCoding>

/// @name Creating an Item Node

/**
 Initializes an empty item node.
*/
- (instancetype)init;

/// @name Getting and Setting Content

/**
 The content of the item; may be `nil` for none.

 Any `SKNode` descendant may be used as content, but any content nodes which conforms to
 `HLItemContentNode` can customize their behavior and/or appearance for certain item node
 functions (for example, setting enabled or highlight); see `HLItemContentNode` for
 details.

 The origin `(0, 0)` is considered the center of the item for geometrical purposes, and
 the content should normally be positioned so that its visual center is on that origin.
*/
@property (nonatomic, strong) SKNode *content;

/// @name Configuring Item State

/**
 The enabled state of the item.

 Default value `YES`.

 The item node and/or the item content node will show enabled state visually.  The
 base-class implementation is designed to enforce a behavior for the entire class
 hierarchy: If the content node can set itself enabled, then it always will, and the item
 node probably will not do anything additional.  The item content node's visual behavior,
 in other words, overrides the item node.

 The implementation, therefore, checks the content node (if any) to see if it conforms to
 `HLItemContentNode` implementing `hlItemContentSetEnabled`, and calls it if so.  Derived
 classes should probably call `[super setEnabled:contentDidSetEnabled:]` (rather than
 `[super setEnabled:]`) because then they can skip their own visual configuration if the
 content responded.
*/
@property (nonatomic, assign) BOOL enabled;

/**
 Sets the enabled state of the item and returns whether or not the content node was called
 to set its own enabled effect.

 Considered a protected method: Should only be called by derived classes.

 See notes in property `enabled`.
*/
- (void)setEnabled:(BOOL)enabled contentDidSetEnabled:(BOOL *)contentDidSetEnabled;

/**
 The highlight state of the item.

 Default value `NO`.

 The item node and/or the item content node will show highlight state visually.  The
 base-class implementation is designed to enforce a behavior for the entire class
 hierarchy: If the content node can set itself highlighted, then it always will, and the
 item node probably will not do anything additional.  The item content node's visual
 behavior, in other words, overrides the item node.

 The implementation, therefore, checks the content node (if any) to see if it conforms to
 `HLItemContentNode` implementing `hlItemContentSetHighlight`, and calls it if so.
 Derived classes should probably call `[super setHighlight:contentDidSetHighlight:]`
 (rather than `[super setHighlight:]`) because then they can skip their own visual
 configuration if the content responded.
*/
@property (nonatomic, assign) BOOL highlight;

/**
 Sets the highlight state of the item and returns whether or not the content node was
 called to set its own highlight effect.

 Considered a protected method: Should only be called by derived classes.

 See notes in property `highlight`.
*/
- (void)setHighlight:(BOOL)highlight contentDidSetHighlight:(BOOL *)contentDidSetHighlight;

/**
 Sets the highlight state of the item with animation.

 This base-class implementation checks the content node, if set, to see if it conforms to
 `HLItemContentNode` implementing
 `hlItemContentSetHighlight:blinkCount:halfCycleDuration:completion:`, and calls it if so.

 @param finalHighlight The intended highlight value for the item when the animation is
                       complete.

 @param blinkCount The number of times the highlight value will cycle from its current
                   value to the final value.

 @param halfCycleDuration The amount of time it takes to cycle the highlight during a
                          blink; a full blink will be completed in twice this duration.

 @param completion A block that will be run when the animation is complete.
*/
- (void)setHighlight:(BOOL)finalHighlight
          blinkCount:(int)blinkCount
   halfCycleDuration:(NSTimeInterval)halfCycleDuration
          completion:(void(^)(void))completion;

/**
 Sets the highlight state of the item with animation, and returns whether or not the
 content node was called to set its own highlight effect.

 Considered a protected method: Should only be called by derived classes.

 See notes in property `highlight`.
*/
- (void)setHighlight:(BOOL)finalHighlight
          blinkCount:(int)blinkCount
   halfCycleDuration:(NSTimeInterval)halfCycleDuration
          completion:(void(^)(void))completion
contentDidSetHighlight:(BOOL *)contentDidSetHighlight;

@end

/**
 An item node that shows its content over a rectangular, single-color backdrop.

 For all overrides of state setter methods (for states like enabled and highlight), the
 backdrop item node will first check the content node to see if it conforms to
 `HLItemContentNode` implementing an appropriate state setter.  If so, only the content
 node's setter will be called.  Otherwise, the state will be visually indicated in the
 backdrop item node according to object configuration.  See, for example, `normalColor`
 and `highlightColor`.
*/
@interface HLBackdropItemNode : HLItemNode <NSCoding>

/// @name Creating a Backdrop Item Node

/**
 Initializes a backdrop item node with a given size.
*/
- (instancetype)initWithSize:(CGSize)size;

/// @name Configuring Geometry

/**
 The size of the backdrop.
*/
@property (nonatomic, assign) CGSize size;

/// @name Configuring Appearance

/**
 The color of the backdrop in normal (non-highlight) state.

 Default value `[SKColor colorWithWhite:0.5 alpha:1.0]`.
*/
@property (nonatomic, strong) SKColor *normalColor;

/**
 The color of the backdrop in highlighted state.

 Default value `[SKColor colorWithWhite:1.0 alpha:1.0]`.
*/
@property (nonatomic, strong) SKColor *highlightColor;

/**
 The alpha of the item in enabled state.

 The alpha value is applied to the item node regardless of the item's current color,
 and thus it will multiply with the color's alpha.

 Default value `1.0`.
*/
@property (nonatomic, assign) CGFloat enabledAlpha;

/**
 The alpha of the item in disabled state.

 The alpha value is applied to the item node regardless of the item's current color,
 and thus it will multiply with the color's alpha.

 Default value `0.4`.
*/
@property (nonatomic, assign) CGFloat disabledAlpha;

@end
