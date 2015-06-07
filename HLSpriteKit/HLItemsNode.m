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

- (instancetype)initWithItemCount:(int)itemCount itemPrototype:(HLItemNode *)itemPrototypeNode
{
  self = [super init];
  if (self) {

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

// commented out: Base class implementation currently is sufficient.
//- (instancetype)initWithCoder:(NSCoder *)aDecoder
//{
//  return [super initWithCoder:aDecoder];
//}

// commented out: Base class implementation currently is sufficient.
//- (instancetype)copyWithZone:(NSZone *)zone
//{
//  return [super copyWithZone:zone];
//}

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
#pragma mark Getting and Setting Content

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
