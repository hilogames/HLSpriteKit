//
//  HLParallaxLayoutManager.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 6/11/2018.
//  Copyright (c) 2018 Hilo Games. All rights reserved.
//

#import "HLParallaxLayoutManager.h"

#import <TargetConditionals.h>

#import "HLMath.h"

const CGFloat HLParallaxLayoutManagerEpsilon = 0.001f;

@implementation HLParallaxLayoutManager

- (instancetype)init
{
  self = [super init];
  return self;
}

- (instancetype)initWithSpeeds:(NSArray *)speeds
{
  self = [super init];
  if (self) {
    _speeds = speeds;
  }
  return self;
}

- (instancetype)initWithNormalDistances:(NSArray *)normalDistancesFromImagePlane
{
  self = [super init];
  if (self) {
    [self setSpeedsWithNormalDistances:normalDistancesFromImagePlane];
  }
  return self;
}

- (instancetype)initWithViewingDistance:(CGFloat)viewingDistance
                              distances:(NSArray *)distancesFromImagePlane
{
  self = [super init];
  if (self) {
    [self setSpeedsWithViewingDistance:viewingDistance
                             distances:distancesFromImagePlane];
  }
  return self;
}

- (instancetype)initWithFieldOfView:(CGFloat)fieldOfViewRadians
                     imagePlaneSize:(CGFloat)imagePlaneSize
                          distances:(NSArray *)distancesFromImagePlane
{
  self = [super init];
  if (self) {
    [self setSpeedsWithFieldOfView:fieldOfViewRadians
                    imagePlaneSize:imagePlaneSize
                         distances:distancesFromImagePlane];
  }
  return self;
}

- (instancetype)initForParallaxPanningWithViewportSize:(CGFloat)viewportSize
                                          panningRange:(CGFloat)panningRange
                                            layerSizes:(NSArray *)layerSizes
{
  self = [super init];
  if (self) {
    [self setSpeedsForParallaxPanningWithViewportSize:viewportSize
                                         panningRange:panningRange
                                           layerSizes:layerSizes];
  }
  return self;
}

- (instancetype)initForParallaxPanningWithViewportSize:(CGFloat)viewportSize
                                          panningRange:(CGFloat)panningRange
                                            layerCount:(NSUInteger)layerCount
                                        firstLayerSize:(CGFloat)firstLayerSize
                                         lastLayerSize:(CGFloat)lastLayerSize
{
  self = [super init];
  if (self) {
    [self setSpeedsForParallaxPanningWithViewportSize:viewportSize
                                         panningRange:panningRange
                                           layerCount:layerCount
                                       firstLayerSize:firstLayerSize
                                        lastLayerSize:lastLayerSize];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super init];
  if (self) {
#if TARGET_OS_IPHONE
    _parallaxPosition = [aDecoder decodeCGPointForKey:@"parallaxPosition"];
    _offset = [aDecoder decodeCGPointForKey:@"offset"];
#else
    _parallaxPosition = [aDecoder decodePointForKey:@"parallaxPosition"];
    _offset = [aDecoder decodePointForKey:@"offset"];
#endif
    _speeds = [aDecoder decodeObjectForKey:@"speeds"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
#if TARGET_OS_IPHONE
  [aCoder encodeCGPoint:_parallaxPosition forKey:@"parallaxPosition"];
  [aCoder encodeCGPoint:_offset forKey:@"offset"];
#else
  [aCoder encodePoint:_parallaxPosition forKey:@"parallaxPosition"];
  [aCoder encodePoint:_offset forKey:@"offset"];
#endif
  [aCoder encodeObject:_speeds forKey:@"speeds"];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
  HLParallaxLayoutManager *copy = [[[self class] allocWithZone:zone] init];
  if (copy) {
    copy->_parallaxPosition = _parallaxPosition;
    copy->_offset = _offset;
    copy->_speeds = [_speeds copy];
  }
  return copy;
}

- (void)setSpeedsWithNormalDistances:(NSArray *)normalDistancesFromImagePlane
{
  if (!normalDistancesFromImagePlane || [normalDistancesFromImagePlane count] == 0) {
    _speeds = nil;
    return;
  }

  NSMutableArray *speeds = [NSMutableArray array];

  for (NSNumber *distanceNumber in normalDistancesFromImagePlane) {
    CGFloat distance = (CGFloat)[distanceNumber doubleValue];
    CGFloat scale = 1.0f / (1.0f + distance);
    [speeds addObject:@(scale)];
  }

  _speeds = speeds;
}

- (void)setSpeedsWithViewingDistance:(CGFloat)viewingDistance
                           distances:(NSArray *)distancesFromImagePlane
{
  if (!distancesFromImagePlane || [distancesFromImagePlane count] == 0) {
    _speeds = nil;
    return;
  }

  NSMutableArray *speeds = [NSMutableArray array];

  for (NSNumber *distanceNumber in distancesFromImagePlane) {
    CGFloat distance = (CGFloat)[distanceNumber doubleValue];
    CGFloat scale = viewingDistance / (viewingDistance + distance);
    [speeds addObject:@(scale)];
  }

  _speeds = speeds;
}

- (void)setSpeedsWithFieldOfView:(CGFloat)fieldOfViewRadians
                  imagePlaneSize:(CGFloat)imagePlaneSize
                       distances:(NSArray *)distancesFromImagePlane
{
  if (!distancesFromImagePlane || [distancesFromImagePlane count] == 0) {
    _speeds = nil;
    return;
  }

  NSMutableArray *speeds = [NSMutableArray array];

  CGFloat viewingDistance = imagePlaneSize / 2.0f / (CGFloat)tan(fieldOfViewRadians / 2.0);
  for (NSNumber *distanceNumber in distancesFromImagePlane) {
    CGFloat distance = (CGFloat)[distanceNumber doubleValue];
    CGFloat scale = viewingDistance / (viewingDistance + distance);
    [speeds addObject:@(scale)];
  }

  _speeds = speeds;
}

- (void)setSpeedsForParallaxPanningWithViewportSize:(CGFloat)viewportSize
                                       panningRange:(CGFloat)panningRange
                                         layerSizes:(NSArray *)layerSizes
{
  if (!layerSizes || [layerSizes count] == 0) {
    _speeds = nil;
    return;
  }

  NSMutableArray *speeds = [NSMutableArray array];

  for (NSNumber *layerSizeNumber in layerSizes) {
    CGFloat layerSize = (CGFloat)[layerSizeNumber doubleValue];
    CGFloat scale = (layerSize - viewportSize) / panningRange;
    [speeds addObject:@(scale)];
  }

  _speeds = speeds;
}

- (void)setSpeedsForParallaxPanningWithViewportSize:(CGFloat)viewportSize
                                       panningRange:(CGFloat)panningRange
                                         layerCount:(NSUInteger)layerCount
                                     firstLayerSize:(CGFloat)firstLayerSize
                                      lastLayerSize:(CGFloat)lastLayerSize
{
  if (layerCount == 0) {
    _speeds = nil;
    return;
  }

  NSMutableArray *speeds = [NSMutableArray array];

  CGFloat layerIncrement;
  if (layerCount > 1) {
    layerIncrement = (lastLayerSize - firstLayerSize) / (layerCount - 1);
  } else {
    layerIncrement = 0.0f;
  }
  for (NSUInteger i = 0; i < layerCount; ++i) {
    CGFloat layerSize = firstLayerSize + i * layerIncrement;
    CGFloat scale = (layerSize - viewportSize) / panningRange;
    [speeds addObject:@(scale)];
  }

  _speeds = speeds;
}

- (void)layout:(NSArray *)nodes
{
  NSUInteger nodeCount = [nodes count];
  if (nodeCount == 0) {
    return;
  }

  NSUInteger speedsCount = (_speeds ? [_speeds count] : 0);

  CGFloat speed = 1.0f;
  for (NSUInteger nodeIndex = 0; nodeIndex < nodeCount; ++nodeIndex) {

    SKNode *node = nodes[nodeIndex];

    if (nodeIndex < speedsCount) {
      speed = [_speeds[nodeIndex] floatValue];
    }

    node.position = CGPointMake(_parallaxPosition.x + _offset.x * speed,
                                _parallaxPosition.y + _offset.y * speed);
  }
}

@end
