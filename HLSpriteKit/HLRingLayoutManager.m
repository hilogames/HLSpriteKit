//
//  HLRingLayoutManager.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 10/27/14.
//  Copyright (c) 2014 Hilo Games. All rights reserved.
//

#import "HLRingLayoutManager.h"

#import <TargetConditionals.h>

const CGFloat HLRingLayoutManagerEpsilon = 0.001f;

typedef NS_ENUM(NSInteger, HLRingLayoutManagerThetasMode) {
  HLRingLayoutManagerThetasNone,
  HLRingLayoutManagerThetasAssigned,
  HLRingLayoutManagerThetasRegular,
  HLRingLayoutManagerThetasIncremental,
  HLRingLayoutManagerThetasCentered,
};

@implementation HLRingLayoutManager
{
  HLRingLayoutManagerThetasMode _thetasMode;
  NSArray *_thetas;
  CGFloat _guideTheta;
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
#if TARGET_OS_IPHONE
    _ringOffset = [aDecoder decodeCGPointForKey:@"ringOffset"];
#else
    _ringOffset = [aDecoder decodePointForKey:@"ringOffset"];
#endif
    _radii = [aDecoder decodeObjectForKey:@"radii"];
    _thetasMode = [aDecoder decodeIntegerForKey:@"thetasMode"];
    switch (_thetasMode) {
      case HLRingLayoutManagerThetasAssigned:
        _thetas = [aDecoder decodeObjectForKey:@"thetas"];
        break;
      case HLRingLayoutManagerThetasRegular:
        // note: Coded as "initialTheta" for legacy reasons.
        _guideTheta = [aDecoder decodeDoubleForKey:@"initialTheta"];
        break;
      case HLRingLayoutManagerThetasIncremental:
        // note: Coded as "initialTheta" for legacy reasons.
        _guideTheta = [aDecoder decodeDoubleForKey:@"initialTheta"];
        _thetaIncrement = [aDecoder decodeDoubleForKey:@"thetaIncrement"];
        break;
      case HLRingLayoutManagerThetasCentered:
        // note: Coded as "initialTheta" for legacy reasons.
        _guideTheta = [aDecoder decodeDoubleForKey:@"initialTheta"];
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
#if TARGET_OS_IPHONE
  [aCoder encodeCGPoint:_ringOffset forKey:@"ringOffset"];
#else
  [aCoder encodePoint:_ringOffset forKey:@"ringOffset"];
#endif
  [aCoder encodeObject:_radii forKey:@"radii"];
  [aCoder encodeInteger:_thetasMode forKey:@"thetasMode"];
  switch (_thetasMode) {
    case HLRingLayoutManagerThetasAssigned:
      [aCoder encodeObject:_thetas forKey:@"thetas"];
      break;
    case HLRingLayoutManagerThetasRegular:
      // note: Coded as "initialTheta" for legacy reasons.
      [aCoder encodeDouble:_guideTheta forKey:@"initialTheta"];
      break;
    case HLRingLayoutManagerThetasIncremental:
      // note: Coded as "initialTheta" for legacy reasons.
      [aCoder encodeDouble:_guideTheta forKey:@"initialTheta"];
      [aCoder encodeDouble:_thetaIncrement forKey:@"thetaIncrement"];
      break;
    case HLRingLayoutManagerThetasCentered:
      // note: Coded as "initialTheta" for legacy reasons.
      [aCoder encodeDouble:_guideTheta forKey:@"initialTheta"];
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
        copy->_guideTheta = _guideTheta;
        break;
      case HLRingLayoutManagerThetasIncremental:
        copy->_guideTheta = _guideTheta;
        copy->_thetaIncrement = _thetaIncrement;
        break;
      case HLRingLayoutManagerThetasCentered:
        copy->_guideTheta = _guideTheta;
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
  _guideTheta = initialThetaRadians;
}

- (void)setThetasWithInitialTheta:(CGFloat)initialThetaRadians thetaIncrement:(CGFloat)thetaIncrementRadians
{
  _thetasMode = HLRingLayoutManagerThetasIncremental;
  _thetas = nil;
  _guideTheta = initialThetaRadians;
  _thetaIncrement = thetaIncrementRadians;
}

- (void)setThetasWithCenterTheta:(CGFloat)centerThetaRadians thetaIncrement:(CGFloat)thetaIncrementRadians
{
  _thetasMode = HLRingLayoutManagerThetasCentered;
  _thetas = nil;
  _guideTheta = centerThetaRadians;
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

  NSUInteger thetasCount = (_thetas ? [_thetas count] : 0);
  CGFloat theta = 0.0f;
  CGFloat thetaIncrement = 0.0f;
  switch (_thetasMode) {
    case HLRingLayoutManagerThetasAssigned:
      if (thetasCount == 0) {
        return;
      }
      break;
    case HLRingLayoutManagerThetasRegular:
      theta = _guideTheta;
      thetaIncrement = (CGFloat)(2.0 * M_PI / nodeCount);
      break;
    case HLRingLayoutManagerThetasIncremental:
      theta = _guideTheta;
      thetaIncrement = _thetaIncrement;
      break;
    case HLRingLayoutManagerThetasCentered:
      theta = _guideTheta - _thetaIncrement * (CGFloat)(nodeCount - 1) / 2.0f;
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
