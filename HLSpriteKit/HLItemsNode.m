//
//  HLItemsNode.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 6/5/15.
//  Copyright (c) 2014 Hilo Games. All rights reserved.
//

#import "HLItemsNode.h"

#import "HLItemNode.h"

enum {
  HLItemsNodeZPositionLayerItems = 0,
  HLItemsNodeZPositionLayerCount
};

@implementation HLItemsNode
{
  int _selectionItemIndex;
}

- (instancetype)initWithItemCount:(int)itemCount itemPrototype:(HLItemNode *)itemPrototypeNode
{
  self = [super init];
  if (self) {

    _selectionItemIndex = -1;

    for (int i = 0; i < itemCount; ++i) {
      HLItemNode *itemNode;
      if (itemPrototypeNode) {
        itemNode = [itemPrototypeNode copy];
      } else {
        itemNode = [[HLItemNode alloc] init];
      }
      [self addChild:itemNode];
    }

    [self HL_layoutZ];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self) {
    _selectionItemIndex = [aDecoder decodeIntForKey:@"selectionItemIndex"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [super encodeWithCoder:aCoder];
  [aCoder encodeInt:_selectionItemIndex forKey:@"selectionItemIndex"];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
  HLItemsNode *copy = [super copyWithZone:zone];
  if (copy) {
    copy->_selectionItemIndex = _selectionItemIndex;
  }
  return copy;
}

- (void)setZPositionScale:(CGFloat)zPositionScale
{
  super.zPositionScale = zPositionScale;
  [self HL_layoutZ];
}

#pragma mark -
#pragma mark Getting Items

- (NSArray *)itemNodes
{
  return self.children;
}

#pragma mark -
#pragma mark Setting Item Content

- (void)setContent:(NSArray *)contentNodes
{
  NSArray *itemNodes = self.children;
  NSUInteger itemCount = [itemNodes count];
  NSUInteger contentCount = [contentNodes count];
  NSUInteger i = 0;
  while (i < contentCount && i < itemCount) {
    SKNode *contentNode = nil;
    if (contentNodes[i] != [NSNull null]) {
      contentNode = (SKNode *)contentNodes[i];
    }
    HLItemNode *itemNode = (HLItemNode *)itemNodes[i];
    itemNode.content = contentNode;
    ++i;
  }
}

#pragma mark -
#pragma mark Managing Item Geometry

- (int)itemContainingPoint:(CGPoint)location
{
  int itemIndex = 0;
  NSArray *itemNodes = self.children;
  for (HLItemNode *itemNode in itemNodes) {
    if ([itemNode containsPoint:location]) {
      return itemIndex;
    }
    ++itemIndex;
  }
  return -1;
}

- (int)itemClosestToPoint:(CGPoint)location maximumDistance:(CGFloat)maximumDistance closestDistance:(CGFloat *)closestDistance
{
  int closestItemIndex = -1;
  CGFloat closestDistanceSquared = 0.0f;
  int itemIndex = 0;
  NSArray *itemNodes = self.children;
  for (HLItemNode *itemNode in itemNodes) {
    CGPoint itemNodePosition = itemNode.position;
    CGFloat distanceSquared = (itemNodePosition.x - location.x) * (itemNodePosition.x - location.x) + (itemNodePosition.y - location.y) * (itemNodePosition.y - location.y);
    if (closestItemIndex == -1 || distanceSquared < closestDistanceSquared) {
      closestItemIndex = itemIndex;
      closestDistanceSquared = distanceSquared;
    }
    ++itemIndex;
  }
  if (closestItemIndex >= 0) {
    CGFloat d = (CGFloat)sqrt(closestDistanceSquared);
    if (d <= maximumDistance) {
      if (closestDistance) {
        *closestDistance = d;
      }
      return closestItemIndex;
    }
  }
  return -1;
}

#pragma mark -
#pragma mark Configuring Item State

- (int)selectionItem
{
  return _selectionItemIndex;
}

- (void)setSelectionForItem:(int)itemIndex
{
  if (_selectionItemIndex >= 0) {
    HLItemNode *itemNode = self.children[_selectionItemIndex];
    itemNode.highlight = NO;
  }
  NSUInteger itemsCount = [self.children count];
  if (itemIndex >= 0 && itemIndex < itemsCount) {
    HLItemNode *itemNode = (HLItemNode *)self.children[itemIndex];
    itemNode.highlight = YES;
    _selectionItemIndex = itemIndex;
  } else {
    _selectionItemIndex = -1;
  }
}

- (void)setSelectionForItem:(int)itemIndex
                 blinkCount:(int)blinkCount
          halfCycleDuration:(NSTimeInterval)halfCycleDuration
                 completion:(void (^)(void))completion
{
  if (_selectionItemIndex >= 0) {
    HLItemNode *itemNode = self.children[_selectionItemIndex];
    itemNode.highlight = NO;
  }
  NSUInteger itemsCount = [self.children count];
  if (itemIndex >= 0 && itemIndex < itemsCount) {
    HLItemNode *itemNode = (HLItemNode *)self.children[itemIndex];
    [itemNode setHighlight:YES blinkCount:blinkCount halfCycleDuration:halfCycleDuration completion:completion];
    _selectionItemIndex = itemIndex;
  } else {
    _selectionItemIndex = -1;
  }
}

- (void)clearSelection
{
  if (_selectionItemIndex >= 0) {
    HLItemNode *itemNode = (HLItemNode *)self.children[_selectionItemIndex];
    itemNode.highlight = NO;
    _selectionItemIndex = -1;
  }
}

- (void)clearSelectionBlinkCount:(int)blinkCount
               halfCycleDuration:(NSTimeInterval)halfCycleDuration
                      completion:(void (^)(void))completion
{
  if (_selectionItemIndex >= 0) {
    HLItemNode *itemNode = (HLItemNode *)self.children[_selectionItemIndex];
    [itemNode setHighlight:NO blinkCount:blinkCount halfCycleDuration:halfCycleDuration completion:completion];
    _selectionItemIndex = -1;
  }
}

#pragma mark -
#pragma mark Private

- (void)HL_layoutZ
{
  CGFloat zPositionLayerIncrement = self.zPositionScale / HLItemsNodeZPositionLayerCount;
  NSArray *itemNodes = self.children;
  for (HLItemNode *itemNode in itemNodes) {
    itemNode.zPosition = HLItemsNodeZPositionLayerItems * zPositionLayerIncrement;
    itemNode.zPositionScale = zPositionLayerIncrement;
  }
}

@end
