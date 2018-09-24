//
//  HLComponentNode.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 10/6/14.
//  Copyright (c) 2014 Hilo Games. All rights reserved.
//

#import "HLComponentNode.h"

@implementation HLComponentNode

- (instancetype)init
{
  self = [super init];
  if (self) {
    _zPositionScale = 1.0f;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self) {
    _zPositionScale = (CGFloat)[aDecoder decodeDoubleForKey:@"zPositionScale"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [super encodeWithCoder:aCoder];
  [aCoder encodeDouble:_zPositionScale forKey:@"zPositionScale"];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
  HLComponentNode *copy = [super copyWithZone:zone];
  if (copy) {
    copy->_zPositionScale = _zPositionScale;
  }
  return copy;
}

@end

@implementation HLComponentSingleLayerNode

@dynamic zPositionScale;

- (void)setZPositionScale:(CGFloat)zPositionScale
{
  [super setZPositionScale:zPositionScale];
  for (SKNode *childNode in self.children) {
    if ([childNode isKindOfClass:[HLComponentNode class]]) {
      ((HLComponentNode *)childNode).zPositionScale = zPositionScale;
    }
  }
}

@end

@implementation HLComponentLayeredNode

@dynamic zPositionScale;

- (void)setZPositionScale:(CGFloat)zPositionScale
{
  [super setZPositionScale:zPositionScale];
  NSArray *children = self.children;
  NSUInteger childrenCount = [children count];
  CGFloat zPositionLayerIncrement = zPositionScale / childrenCount;
  for (NSUInteger c = 0; c < childrenCount; ++c) {
    SKNode *childNode = children[c];
    childNode.zPosition = zPositionLayerIncrement * c;
    if ([childNode isKindOfClass:[HLComponentNode class]]) {
      ((HLComponentNode *)childNode).zPositionScale = zPositionLayerIncrement;
    }
  }
}

@end
