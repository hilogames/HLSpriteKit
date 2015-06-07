//
//  HLRingLayoutManager.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 10/27/14.
//  Copyright (c) 2014 Hilo Games. All rights reserved.
//

#import "HLRingLayoutManager.h"

const CGFloat HLRingLayoutManagerEpsilon = 0.001f;

typedef NS_ENUM(NSInteger, HLRingLayoutManagerThetasMode) {
  HLRingLayoutManagerThetasNone,
  HLRingLayoutManagerThetasAssigned,
  HLRingLayoutManagerThetasRegular,
  HLRingLayoutManagerThetasIncremental,
};

@implementation HLRingLayoutManager
{
  HLRingLayoutManagerThetasMode _thetasMode;
  NSArray *_thetas;
  CGFloat _initialTheta;
  CGFloat _thetaIncrement;
}

- (instancetype)init
{
  self = [super init];
  if (self) {
    _thetasMode = HLRingLayoutManagerThetasNone;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super init];
  if (self) {
    _ringOffset = [aDecoder decodeCGPointForKey:@"ringOffset"];
    _radii = [aDecoder decodeObjectForKey:@"radii"];
    _thetasMode = [aDecoder decodeIntegerForKey:@"thetasMode"];
    switch (_thetasMode) {
      case HLRingLayoutManagerThetasAssigned:
        _thetas = [aDecoder decodeObjectForKey:@"thetas"];
        break;
      case HLRingLayoutManagerThetasRegular:
        _initialTheta = [aDecoder decodeDoubleForKey:@"initialTheta"];
        break;
      case HLRingLayoutManagerThetasIncremental:
        _initialTheta = [aDecoder decodeDoubleForKey:@"initialTheta"];
        _thetaIncrement = [aDecoder decodeDoubleForKey:@"thetaIncrement"];
        break;
      case HLRingLayoutManagerThetasNone:
        break;
    }
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [aCoder encodeCGPoint:_ringOffset forKey:@"ringOffset"];
  [aCoder encodeObject:_radii forKey:@"radii"];
  [aCoder encodeInteger:_thetasMode forKey:@"thetasMode"];
  switch (_thetasMode) {
    case HLRingLayoutManagerThetasAssigned:
      [aCoder encodeObject:_thetas forKey:@"thetas"];
      break;
    case HLRingLayoutManagerThetasRegular:
      [aCoder encodeDouble:_initialTheta forKey:@"initialTheta"];
      break;
    case HLRingLayoutManagerThetasIncremental:
      [aCoder encodeDouble:_initialTheta forKey:@"initialTheta"];
      [aCoder encodeDouble:_thetaIncrement forKey:@"thetaIncrement"];
      break;
    case HLRingLayoutManagerThetasNone:
      break;
  }
}

- (instancetype)copyWithZone:(NSZone *)zone
{
  HLRingLayoutManager *copy = [[[self class] allocWithZone:zone] init];
  if (copy) {
    copy->_ringOffset = _ringOffset;
    copy->_radii = [_radii copy];
    copy->_thetasMode = _thetasMode;
    switch (_thetasMode) {
      case HLRingLayoutManagerThetasAssigned:
        copy->_thetas = [_thetas copy];
        break;
      case HLRingLayoutManagerThetasRegular:
        copy->_initialTheta = _initialTheta;
        break;
      case HLRingLayoutManagerThetasIncremental:
        copy->_initialTheta = _initialTheta;
        copy->_thetaIncrement = _thetaIncrement;
        break;
      case HLRingLayoutManagerThetasNone:
        break;
    }
  }
  return copy;
}

- (void)setThetas:(NSArray *)thetasRadians
{
  _thetasMode = HLRingLayoutManagerThetasAssigned;
  _thetas = thetasRadians;
}

- (void)setThetasWithInitialTheta:(CGFloat)initialThetaRadians
{
  _thetasMode = HLRingLayoutManagerThetasRegular;
  _thetas = nil;
  _initialTheta = initialThetaRadians;
}

- (void)setThetasWithInitialTheta:(CGFloat)initialThetaRadians thetaIncrement:(CGFloat)thetaIncrementRadians
{
  _thetasMode = HLRingLayoutManagerThetasIncremental;
  _thetas = nil;
  _initialTheta = initialThetaRadians;
  _thetaIncrement = thetaIncrementRadians;
}

- (void)layout:(NSArray *)nodes
{
  NSUInteger radiiCount = [_radii count];
  if (radiiCount == 0) {
    return;
  }

  NSUInteger nodeCount = [nodes count];
  if (nodeCount == 0) {
    return;
  }

  NSUInteger thetasCount = [_thetas count];
  CGFloat theta = 0.0f;
  CGFloat thetaIncrement = 0.0f;
  switch (_thetasMode) {
    case HLRingLayoutManagerThetasAssigned:
      if (thetasCount == 0) {
        return;
      }
      break;
    case HLRingLayoutManagerThetasRegular:
      theta = _initialTheta;
      thetaIncrement = (CGFloat)(2.0 * M_PI / nodeCount);
      break;
    case HLRingLayoutManagerThetasIncremental:
      theta = _initialTheta;
      thetaIncrement = _thetaIncrement;
      break;
    case HLRingLayoutManagerThetasNone:
      return;
  }
  
  CGFloat radius = 0.0f;
  for (NSUInteger nodeIndex = 0; nodeIndex < nodeCount; ++nodeIndex) {

    id entry = nodes[nodeIndex];
    if (![entry isKindOfClass:[SKNode class]]) {
      continue;
    }
    SKNode *node = (SKNode *)entry;

    if (nodeIndex < radiiCount) {
      radius = [_radii[nodeIndex] floatValue];
    }

    if (_thetasMode == HLRingLayoutManagerThetasAssigned) {
      if (nodeIndex < thetasCount) {
        theta = [_thetas[nodeIndex] floatValue];
      }
    }

    node.position = CGPointMake(radius * (CGFloat)cos(theta), radius * (CGFloat)sin(theta));

    if (_thetasMode != HLRingLayoutManagerThetasAssigned) {
      theta += thetaIncrement;
    }
  }
}

@end
