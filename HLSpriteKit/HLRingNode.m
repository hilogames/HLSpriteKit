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
    _itemsNode = [aDecoder decodeObjectForKey:@"itemsNode"];
    _itemAtPointDistanceMax = (CGFloat)[aDecoder decodeDoubleForKey:@"itemAtPointDistanceMax"];
    // note: Assume _delegate will be reset.
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

- (void)setZPositionScale:(CGFloat)zPositionScale
{
  super.zPositionScale = zPositionScale;
  [self HL_layoutZ];
}

#pragma mark -
#pragma mark Configuring Geometry and Layout

- (void)setLayoutWithRadius:(CGFloat)radius thetas:(NSArray *)thetasRadians
{
  NSArray *itemNodes = _itemsNode.itemNodes;
  if ([thetasRadians count] != [itemNodes count]) {
    [NSException raise:@"HLRingNodeInvalidLayout" format:@"Ring node has %lu items but only %lu thetas were passed.", [itemNodes count], [thetasRadians count]];
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

- (int)itemAtPoint:(CGPoint)location
{
  return [_itemsNode itemClosestToPoint:location maximumDistance:_itemAtPointDistanceMax closestDistance:nil];
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

#pragma mark -
#pragma mark HLGestureTarget

- (NSArray *)addsToGestureRecognizers
{
  return @[ [[UITapGestureRecognizer alloc] init] ];
}

- (BOOL)addToGesture:(UIGestureRecognizer *)gestureRecognizer firstTouch:(UITouch *)touch isInside:(BOOL *)isInside
{
  *isInside = YES;
  if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
    // note: Require only one tap and one touch, same as our gesture recognizer returned
    // from addsToGestureRecognizers?  I think it's okay to be non-strict.
    [gestureRecognizer addTarget:self action:@selector(handleTap:)];
    return YES;
  }
  return NO;
}

- (void)handleTap:(UIGestureRecognizer *)gestureRecognizer
{
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
