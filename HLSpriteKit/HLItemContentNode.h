//
//  HLItemContentNode.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 4/13/15.
//  Copyright (c) 2015 Hilo Games. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

#import "HLComponentNode.h"

/**
 A interface that allows special interaction when implemented by the content node of an
 `HLItemNode`.

 In particular, an `HLItemContentNode` will be notified about state changes of the
 `HLItemNode`.

 A design note: The methods are optional, and so `HLItemNode` must check not just for
 conformance to the protocol but also for response to a particular selector.  Another good
 possibility: Require implementation of all methods, but return an additional boolean
 which indicates whether or not the `HLItemContentNode` has implemented anything special
 or not.
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

/**
 Called when this content node's `HLItemNode` changes highlight state with animation.
*/
- (void)hlItemContentSetHighlight:(BOOL)finalHighlight
                       blinkCount:(int)blinkCount
                halfCycleDuration:(NSTimeInterval)halfCycleDuration
                       completion:(void(^)(void))completion;

@end

/**
 An implementation of `HLItemContentNode` which displays another node behind the content
 when the item is highlighted.
*/
@interface HLItemContentBackHighlightNode : HLComponentNode <HLItemContentNode, NSCopying, NSCoding>

/// @name Creating a Back-Highlight Content Node

/**
 Initialize a back-highlight content node.
*/
- (instancetype)initWithContentNode:(SKNode *)contentNode backHighlightNode:(SKNode *)backHighlightNode;

/// @name Getting the Back-Highlight Node

/**
 The back-highlight node passed to `init`.
*/
@property (nonatomic, readonly) SKNode *backHighlightNode;

/// @name Setting Node State

/**
 Sets the highlight of the back-highlight content node.

 A back-highlight node displays highlight by showing a second node behind its content.
 Here, "behind" refers to `zPosition`.
*/
- (void)hlItemContentSetHighlight:(BOOL)highlight;

/**
 Sets the highlight of the back-highlight content node with animation.

 A back-highlight node displays highlight by showing a second node behind its content.
 Here, "behind" refers to `zPosition`.
*/
- (void)hlItemContentSetHighlight:(BOOL)finalHighlight
                       blinkCount:(int)blinkCount
                halfCycleDuration:(NSTimeInterval)halfCycleDuration
                       completion:(void(^)(void))completion;

@end

/**
 An implementation of `HLItemContentNode` which displays another node in front of the
 content when the item is highlighted.
*/
@interface HLItemContentFrontHighlightNode : HLComponentNode <HLItemContentNode, NSCopying, NSCoding>

/// @name Creating a Front-Highlight Content Node

/**
 Initialize a front-highlight content node.
*/
- (instancetype)initWithContentNode:(SKNode *)contentNode frontHighlightNode:(SKNode *)frontHighlightNode;

/// @name Getting the Front-Highlight Node

/**
 The front-highlight node passed to `init`.
 */
@property (nonatomic, readonly) SKNode *frontHighlightNode;

/// @name Setting Node State

/**
 Sets the highlight of the front-highlight content node.

 A front-highlight node displays highlight by showing a second node in front of its
 content.  Here, "in front of" refers to `zPosition`.
*/
- (void)hlItemContentSetHighlight:(BOOL)highlight;

/**
 Sets the highlight of the back-highlight content node with animation.

 A front-highlight node displays highlight by showing a second node in front of its
 content.  Here, "in front of" refers to `zPosition`.
*/
- (void)hlItemContentSetHighlight:(BOOL)finalHighlight
                       blinkCount:(int)blinkCount
                halfCycleDuration:(NSTimeInterval)halfCycleDuration
                       completion:(void(^)(void))completion;

@end
