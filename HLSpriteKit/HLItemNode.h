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
 A interface that allows special interaction when implemented by the content node of an
 `HLItemNode`.

 In particular, an `HLItemContentNode` will be notified about state changes of the
 `HLItemNode`.
 */
@protocol HLItemContentNode <NSObject>

@optional

/**
 Called when this content node's `HLItemNode` changes enabled state.
 */
- (void)hlItemContentSetEnabled:(BOOL)enabled;

/**
 Called when this content node's `HLItemNode` changes highlight state.
 */
- (void)hlItemContentSetHighlight:(BOOL)highlight;

@end

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
 Sets the enabled state of the item.

 Default value `YES`.

 Item nodes, and their content nodes, typically indicate enabled state visually.

 This base-class implementation checks the content node, if set, to see if it conforms to
 `HLToolNode` implementing `hlItemContentSetEnabled`, and calls it if so.

 A derived item node can decide for itself how to indicate enabled state.  Calling this
 base class implementation is optional.
 */
@property (nonatomic, assign) BOOL enabled;

/**
 Sets the highlight state of the item.

 Default value `NO`.

 Item nodes, and their content nodes, typically indicate highlight state visually.

 This base-class implementation checks the content node, if set, to see if it conforms to
 `HLToolNode` implementing `hlItemContentSetHighlight`, and calls it if so.

 A derived item node can decide for itself how to indicate highlight state.  Calling this
 base class implementation is optional.
 */
@property (nonatomic, assign) BOOL highlight;

@end

/**
 An item node that shows its content over a rectangular, single-color backdrop.
 */
@interface HLBackdropItemNode : HLItemNode

/// @name Creating a Backdrop Item Node

/**
 Initializes a backdrop item node with a given size.
 */
- (instancetype)initWithSize:(CGSize)size;

/// @name Configuring Geometry

/**
 * The size of the backdrop.
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
 The alpha of the item (and inherited by content) in enabled state.

 The alpha value is applied to the item node regardless of the item's current color,
 and thus it will multiply with the color's alpha.

 Default value `1.0`.
 */
@property (nonatomic, assign) CGFloat enabledAlpha;

/**
 The alpha of the item (and inherited by content) in disabled state.

 The alpha value is applied to the item node regardless of the item's current color,
 and thus it will multiply with the color's alpha.

 Default value `0.4`.
 */
@property (nonatomic, assign) CGFloat disabledAlpha;

@end
