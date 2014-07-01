//
//  HLToolbarNode.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 12/12/13.
//  Copyright (c) 2013 Hilo. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@class HLTextureStore;

typedef enum HLToolbarNodeJustification {
  HLToolbarNodeJustificationCenter,
  HLToolbarNodeJustificationLeft,
  HLToolbarNodeJustificationRight
} HLToolbarNodeJustification;

typedef enum HLToolbarNodeAnimation {
  HLToolbarNodeAnimationNone,
  HLToolbarNodeAnimationSlideUp,
  HLToolbarNodeAnimationSlideDown,
  HLToolbarNodeAnimationSlideLeft,
  HLToolbarNodeAnimationSlideRight
} HLToolbarNodeAnimation;

@interface HLToolbarNode : SKSpriteNode <NSCoding>

@property (nonatomic) BOOL automaticWidth;
@property (nonatomic) BOOL automaticHeight;

@property (nonatomic) HLToolbarNodeJustification justification;

/**
 * The amount of toolbar background that shows as a border around all the tools.
 */
@property (nonatomic) CGFloat borderSize;

/**
 * The amount of toolbar background that shows between each tool on the toolbar.
 */
@property (nonatomic) CGFloat toolSeparatorSize;

/**
 * The extra space added between the edge of the box (made for the tool) and the tool sprite.
 * Negative values mean the box will be drawn smaller than the tool sprite.
 */
@property (nonatomic) CGFloat toolPad;

- (id)initWithSize:(CGSize)size;

/**
 * Sets toolbar with tools from the textures specified by the passed keys.
 * Rotations (array of NSNumbers with CGFloats) and offets (array of NSValues
 * with CGPoints) are used to rotate and offset the textures within their
 * allotted toolbar spaces (before scaling); if passed nil, the rotation default
 * is M_PI_2 and the offset default is CGPointZero.
 *
 * The toolbar will size itself in the relevant dimension if automaticWidth
 * or automaticHeight properties are true (and according to the textures of the
 * passed tools); if false, then the size used will be according to the size
 * property (inherited from SKSpriteNode).
 */
- (void)setToolsWithTextureKeys:(NSArray *)keys store:(HLTextureStore *)textureStore rotations:(NSArray *)rotations offsets:(NSArray *)offsets animation:(HLToolbarNodeAnimation)animation;

/**
 * Returns the key of the tool at the passed location, or nil for none.  The
 * location is expected to be in the coordinate system of this toolbar node.
 */
- (NSString *)toolAtLocation:(CGPoint)location;

- (CGRect)toolFrame:(NSString *)key;

- (NSUInteger)toolCount;

- (void)setHighlight:(BOOL)highlight forTool:(NSString *)key;

- (void)animateHighlight:(BOOL)finalHighlight count:(int)blinkCount halfCycleDuration:(NSTimeInterval)halfCycleDuration forTool:(NSString *)key;

- (void)setEnabled:(BOOL)enabled forTool:(NSString *)key;

- (BOOL)enabledForTool:(NSString *)key;

- (void)showWithOrigin:(CGPoint)origin finalPosition:(CGPoint)finalPosition fullScale:(CGFloat)fullScale animated:(BOOL)animated;

- (void)hideAnimated:(BOOL)animated;

@end
