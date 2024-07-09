//
//  HLRingNode.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 6/5/15.
//  Copyright (c) 2014 Hilo Games. All rights reserved.
//

#import "HLRingNode.h"

#import "HLItemNode.h"
#import "HLItemsNode.h"
#import "HLRingLayoutManager.h"

enum {
  HLRingNodeZPositionLayerBackground = 0,
  HLRingNodeZPositionLayerItems,
  HLRingNodeZPositionLayerFrame,
  HLRingNodeZPositionLayerCount
};

@implementation HLRingNode
{
  HLItemsNode *_itemsNode;
}

- (instancetype)initWithItemCount:(int)itemCount
{
  self = [super init];
  if (self) {
    _itemsNode = [[HLItemsNode alloc] initWithItemCount:itemCount itemPrototype:nil];
    _itemsNode.name = @"items";
    [self addChild:_itemsNode];
    _itemAtPointDistanceMax = 42.0f;
    [self HL_layoutZ];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self) {
    // note: Nodes already decoded by super; decode the references.
    _delegate = [aDecoder decodeObjectForKey:@"delegate"];
    _itemsNode = [aDecoder decodeObjectForKey:@"itemsNode"];
    _itemAtPointDistanceMax = (CGFloat)[aDecoder decodeDoubleForKey:@"itemAtPointDistanceMax"];
    // note: Cannot encode _itemTappedBlock; assume it will be reset.
    _backgroundNode = [aDecoder decodeObjectForKey:@"backgroundNode"];
    _frameNode = [aDecoder decodeObjectForKey:@"frameNode"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [super encodeWithCoder:aCoder];
  // note: Nodes already encoded by super; encode the references.
  [aCoder encodeConditionalObject:_delegate forKey:@"delegate"];
  [aCoder encodeObject:_itemsNode forKey:@"itemsNode"];
  [aCoder encodeDouble:_itemAtPointDistanceMax forKey:@"itemAtPointDistanceMax"];
  [aCoder encodeObject:_backgroundNode forKey:@"backgroundNode"];
  [aCoder encodeObject:_frameNode forKey:@"frameNode"];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
  HLRingNode *copy = [super copyWithZone:zone];
  if (copy) {
    copy->_itemsNode = (HLItemsNode *)[copy childNodeWithName:@"items"];
    copy->_backgroundNode = [copy childNodeWithName:@"background"];
    copy->_frameNode = [copy childNodeWithName:@"frame"];
  }
  return copy;
}

#pragma mark -
#pragma mark Configuring Geometry and Layout

- (void)setLayoutWithRadius:(CGFloat)radius thetas:(NSArray *)thetasRadians
{
  NSArray *itemNodes = _itemsNode.itemNodes;
  if ([thetasRadians count] != [itemNodes count]) {
    [NSException raise:@"HLRingNodeInvalidLayout" format:@"Ring node has %lu items but only %lu thetas were passed.", (unsigned long)[itemNodes count], (unsigned long)[thetasRadians count]];
  }
  HLRingLayoutManager *layoutManager = [[HLRingLayoutManager alloc] init];
  layoutManager.radii = @[ @(radius) ];
  [layoutManager setThetas:thetasRadians];
  [layoutManager layout:itemNodes];
}

- (void)setLayoutWithRadius:(CGFloat)radius initialTheta:(CGFloat)initialThetaRadians
{
  NSArray *itemNodes = _itemsNode.itemNodes;
  HLRingLayoutManager *layoutManager = [[HLRingLayoutManager alloc] init];
  layoutManager.radii = @[ @(radius) ];
  [layoutManager setThetasWithInitialTheta:initialThetaRadians];
  [layoutManager layout:itemNodes];
}

- (void)setLayoutWithRadius:(CGFloat)radius initialTheta:(CGFloat)initialThetaRadians thetaIncrement:(CGFloat)thetaIncrementRadians
{
  NSArray *itemNodes = _itemsNode.itemNodes;
  HLRingLayoutManager *layoutManager = [[HLRingLayoutManager alloc] init];
  layoutManager.radii = @[ @(radius) ];
  [layoutManager setThetasWithInitialTheta:initialThetaRadians thetaIncrement:thetaIncrementRadians];
  [layoutManager layout:itemNodes];
}

- (void)setLayoutWithRadius:(CGFloat)radius centerTheta:(CGFloat)centerThetaRadians thetaIncrement:(CGFloat)thetaIncrementRadians
{
  NSArray *itemNodes = _itemsNode.itemNodes;
  HLRingLayoutManager *layoutManager = [[HLRingLayoutManager alloc] init];
  layoutManager.radii = @[ @(radius) ];
  [layoutManager setThetasWithCenterTheta:centerThetaRadians thetaIncrement:thetaIncrementRadians];
  [layoutManager layout:itemNodes];
}

- (int)itemAtPoint:(CGPoint)location
{
  return [_itemsNode itemClosestToPoint:location maximumDistance:_itemAtPointDistanceMax closestDistance:nil];
}

- (void)setZPositionScale:(CGFloat)zPositionScale
{
  [super setZPositionScale:zPositionScale];
  [self HL_layoutZ];
}

#pragma mark -
#pragma mark Getting and Setting Content

- (void)setContent:(NSArray *)contentNodes
{
  [_itemsNode setContent:contentNodes];
}

- (void)setContent:(SKNode *)contentNode forItem:(int)itemIndex
{
  NSArray *itemNodes = _itemsNode.itemNodes;
  NSUInteger itemCount = [itemNodes count];
  if (itemIndex < 0 || itemIndex >= itemCount) {
    [NSException raise:@"HLRingNodeInvalidIndex" format:@"Item index %d out of range.", itemIndex];
  }
  ((HLItemNode *)itemNodes[itemIndex]).content = contentNode;
}

- (SKNode *)contentForItem:(int)itemIndex
{
  NSArray *itemNodes = _itemsNode.itemNodes;
  NSUInteger itemCount = [itemNodes count];
  if (itemIndex < 0 || itemIndex >= itemCount) {
    [NSException raise:@"HLRingNodeInvalidIndex" format:@"Item index %d out of range.", itemIndex];
  }
  return ((HLItemNode *)itemNodes[itemIndex]).content;
}

- (SKNode *)itemNodeForItem:(int)itemIndex
{
  NSArray *itemNodes = _itemsNode.itemNodes;
  NSUInteger itemCount = [itemNodes count];
  if (itemIndex < 0 || itemIndex >= itemCount) {
    [NSException raise:@"HLRingNodeInvalidIndex" format:@"Item index %d out of range.", itemIndex];
  }
  return (HLItemNode *)itemNodes[itemIndex];
}

- (int)itemCount
{
  return (int)[_itemsNode.itemNodes count];
}

#pragma mark -
#pragma mark Configuring Appearance

- (void)setBackgroundNode:(SKNode *)backgroundNode
{
  if (_backgroundNode) {
    [_backgroundNode removeFromParent];
  }
  _backgroundNode = backgroundNode;
  if (_backgroundNode) {
    _backgroundNode.name = @"background";
    [self addChild:_backgroundNode];
    [self HL_layoutZForBackgroundNode];
  }
}

- (void)setFrameNode:(SKNode *)frameNode
{
  if (_frameNode) {
    [_frameNode removeFromParent];
  }
  _frameNode = frameNode;
  if (_frameNode) {
    _frameNode.name = @"frame";
    [self addChild:_frameNode];
    [self HL_layoutZForFrameNode];
  }
}

#pragma mark -
#pragma mark Managing Ring Item State

- (BOOL)enabledForItem:(int)itemIndex
{
  NSArray *itemNodes = _itemsNode.itemNodes;
  if (itemIndex < 0 || itemIndex >= [itemNodes count]) {
    [NSException raise:@"HLGridNodeInvalidIndex" format:@"Item index %d out of range.", itemIndex];
  }
  return ((HLBackdropItemNode *)itemNodes[itemIndex]).enabled;
}

- (void)setEnabled:(BOOL)enabled forItem:(int)itemIndex
{
  NSArray *itemNodes = _itemsNode.itemNodes;
  if (itemIndex < 0 || itemIndex >= [itemNodes count]) {
    [NSException raise:@"HLGridNodeInvalidIndex" format:@"Item index %d out of range.", itemIndex];
  }
  ((HLBackdropItemNode *)itemNodes[itemIndex]).enabled = enabled;
}

- (BOOL)highlightForItem:(int)itemIndex
{
  NSArray *itemNodes = _itemsNode.itemNodes;
  if (itemIndex < 0 || itemIndex >= [itemNodes count]) {
    [NSException raise:@"HLGridNodeInvalidIndex" format:@"Item index %d out of range.", itemIndex];
  }
  return ((HLBackdropItemNode *)itemNodes[itemIndex]).highlight;
}

- (void)setHighlight:(BOOL)highlight forItem:(int)itemIndex
{
  NSArray *itemNodes = _itemsNode.itemNodes;
  if (itemIndex < 0 || itemIndex >= [itemNodes count]) {
    [NSException raise:@"HLGridNodeInvalidIndex" format:@"Item index %d out of range.", itemIndex];
  }
  ((HLBackdropItemNode *)itemNodes[itemIndex]).highlight = highlight;
}

- (void)setHighlight:(BOOL)finalHighlight
           forItem:(int)itemIndex
          blinkCount:(int)blinkCount
   halfCycleDuration:(NSTimeInterval)halfCycleDuration
          completion:(void(^)(void))completion
{
  NSArray *itemNodes = _itemsNode.itemNodes;
  if (itemIndex < 0 || itemIndex >= [itemNodes count]) {
    [NSException raise:@"HLGridNodeInvalidIndex" format:@"Item index %d out of range.", itemIndex];
  }
  [(HLBackdropItemNode *)itemNodes[itemIndex] setHighlight:finalHighlight
                                                blinkCount:blinkCount
                                         halfCycleDuration:halfCycleDuration
                                                completion:completion];
}

- (int)selectionItem
{
  return _itemsNode.selectionItem;
}

- (void)setSelectionForItem:(int)itemIndex
{
  [_itemsNode setSelectionForItem:itemIndex];
}

- (void)setSelectionForItem:(int)itemIndex
                 blinkCount:(int)blinkCount
          halfCycleDuration:(NSTimeInterval)halfCycleDuration
                 completion:(void (^)(void))completion
{
  [_itemsNode setSelectionForItem:itemIndex
                       blinkCount:blinkCount
                halfCycleDuration:halfCycleDuration
                       completion:completion];
}

- (void)clearSelection
{
  [_itemsNode clearSelection];
}

- (void)clearSelectionBlinkCount:(int)blinkCount
               halfCycleDuration:(NSTimeInterval)halfCycleDuration
                      completion:(void (^)(void))completion
{
  [_itemsNode clearSelectionBlinkCount:blinkCount
                     halfCycleDuration:halfCycleDuration
                            completion:completion];
}

#pragma mark -
#pragma mark HLGestureTarget

- (NSArray *)addsToGestureRecognizers
{
#if TARGET_OS_IPHONE
  return @[ [[UITapGestureRecognizer alloc] init] ];
#else
  return @[ [[NSClickGestureRecognizer alloc] init] ];
#endif
}

- (BOOL)addToGesture:(HLGestureRecognizer *)gestureRecognizer firstLocation:(CGPoint)sceneLocation didAbsorbGesture:(BOOL *)didAbsorbGesture
{
#if TARGET_OS_IPHONE
  if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
    *didAbsorbGesture = YES;
    // note: Require only one tap and one touch, same as our gesture recognizer returned
    // from addsToGestureRecognizers?  I think it's okay to be non-strict.
    [gestureRecognizer addTarget:self action:@selector(handleTap:)];
    return YES;
  }
#else
  if ([gestureRecognizer isKindOfClass:[NSClickGestureRecognizer class]]) {
    *didAbsorbGesture = YES;
    [gestureRecognizer addTarget:self action:@selector(handleClick:)];
    return YES;
  }
#endif
  // note: Absorb only tap gestures.  I can easily imagine other desirable configurations
  // but those will require a custom gesture target implementation.  This is the behavior
  // of this gesture target since 4/2024; previously, the implementation of the gesture
  // controller in `HLScene` would cause taps and long-presses on this gesture target to
  // be absorbed and all other gestures to fall through.
  // note: The ring node currently absorbs gestures whether or not they started on an item
  // in the ring.  This is probably too crude for some users, but I'm preserving it the
  // way it's always been, for now.
  *didAbsorbGesture = NO;
  return NO;
}

#if TARGET_OS_IPHONE

- (void)handleTap:(HLGestureRecognizer *)gestureRecognizer
{
  if (gestureRecognizer.state != UIGestureRecognizerStateEnded) {
    return;
  }

  CGPoint viewLocation = [gestureRecognizer locationInView:self.scene.view];
  CGPoint sceneLocation = [self.scene convertPointFromView:viewLocation];
  CGPoint location = [self convertPoint:sceneLocation fromNode:self.scene];

  int itemIndex = [self itemAtPoint:location];
  if (itemIndex < 0) {
    return;
  }

  if (_itemTappedBlock) {
    _itemTappedBlock(itemIndex);
  }

  id <HLRingNodeDelegate> delegate = _delegate;
  if (delegate) {
    [delegate ringNode:self didTapItem:itemIndex];
  }
}

#else

- (void)handleClick:(HLGestureRecognizer *)gestureRecognizer
{
  if (gestureRecognizer.state != NSGestureRecognizerStateEnded) {
    return;
  }

  CGPoint viewLocation = [gestureRecognizer locationInView:self.scene.view];
  CGPoint sceneLocation = [self.scene convertPointFromView:viewLocation];
  CGPoint location = [self convertPoint:sceneLocation fromNode:self.scene];

  int itemIndex = [self itemAtPoint:location];
  if (itemIndex < 0) {
    return;
  }

  if (_itemClickedBlock) {
    _itemClickedBlock(itemIndex);
  }

  id <HLRingNodeDelegate> delegate = _delegate;
  if (delegate) {
    [delegate ringNode:self didClickItem:itemIndex];
  }
}

#endif

#if TARGET_OS_IPHONE

#pragma mark -
#pragma mark UIResponder

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
  if ([touches count] > 1) {
    return;
  }

  UITouch *touch = [touches anyObject];
  if (touch.tapCount > 1) {
    return;
  }

  CGPoint viewLocation = [touch locationInView:self.scene.view];
  CGPoint sceneLocation = [self.scene convertPointFromView:viewLocation];
  CGPoint location = [self convertPoint:sceneLocation fromNode:self.scene];

  int itemIndex = [self itemAtPoint:location];
  if (itemIndex < 0) {
    return;
  }

  if (_itemTappedBlock) {
    _itemTappedBlock(itemIndex);
  }

  id <HLRingNodeDelegate> delegate = _delegate;
  if (delegate) {
    [delegate ringNode:self didTapItem:itemIndex];
  }
}

#else

#pragma mark -
#pragma mark NSResponder

- (void)mouseUp:(NSEvent *)event
{
  if (event.clickCount > 1) {
    return;
  }

  CGPoint location = [event locationInNode:self];

  int itemIndex = [self itemAtPoint:location];
  if (itemIndex < 0) {
    return;
  }

  if (_itemClickedBlock) {
    _itemClickedBlock(itemIndex);
  }

  id <HLRingNodeDelegate> delegate = _delegate;
  if (delegate) {
    [delegate ringNode:self didClickItem:itemIndex];
  }
}

#endif

#pragma mark -
#pragma mark Private

- (void)HL_layoutZ
{
  CGFloat zPositionLayerIncrement = self.zPositionScale / HLRingNodeZPositionLayerCount;
  if (_backgroundNode) {
    _backgroundNode.zPosition = HLRingNodeZPositionLayerBackground * zPositionLayerIncrement;
    if ([_backgroundNode isKindOfClass:[HLComponentNode class]]) {
      ((HLComponentNode *)_backgroundNode).zPositionScale = zPositionLayerIncrement;
    }
  }
  _itemsNode.zPosition = HLRingNodeZPositionLayerItems * zPositionLayerIncrement;
  _itemsNode.zPositionScale = zPositionLayerIncrement;
  if (_frameNode) {
    _frameNode.zPosition = HLRingNodeZPositionLayerFrame * zPositionLayerIncrement;
    if ([_frameNode isKindOfClass:[HLComponentNode class]]) {
      ((HLComponentNode *)_frameNode).zPositionScale = zPositionLayerIncrement;
    }
  }
}

- (void)HL_layoutZForBackgroundNode
{
  CGFloat zPositionLayerIncrement = self.zPositionScale / HLRingNodeZPositionLayerCount;
  _backgroundNode.zPosition = HLRingNodeZPositionLayerBackground * zPositionLayerIncrement;
  if ([_backgroundNode isKindOfClass:[HLComponentNode class]]) {
    ((HLComponentNode *)_backgroundNode).zPositionScale = zPositionLayerIncrement;
  }
}

- (void)HL_layoutZForFrameNode
{
  CGFloat zPositionLayerIncrement = self.zPositionScale / HLRingNodeZPositionLayerCount;
  _frameNode.zPosition = HLRingNodeZPositionLayerFrame * zPositionLayerIncrement;
  if ([_frameNode isKindOfClass:[HLComponentNode class]]) {
    ((HLComponentNode *)_frameNode).zPositionScale = zPositionLayerIncrement;
  }
}

@end
