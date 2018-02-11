//
//  HLStackLayoutManager.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 1/30/18.
//  Copyright (c) 2018 Hilo Games. All rights reserved.
//

#import "HLStackLayoutManager.h"

#import <TargetConditionals.h>

const CGFloat HLStackLayoutManagerEpsilon = 0.001f;

void
HLStackLayoutManagerVerticalAlignLabelNodes(NSArray *nodes,
                                            SKLabelVerticalAlignmentMode alignmentMode,
                                            HLLabelHeightMode heightMode,
                                            CGFloat additionalOffsetY)
{
  CGFloat offsetY;
  SKLabelVerticalAlignmentMode useAlignmentMode;
  for (id node in nodes) {
    if ([node isKindOfClass:[SKLabelNode class]]) {
      SKLabelNode *labelNode = (SKLabelNode *)node;
      [labelNode getVerticalAlignmentForAlignmentMode:alignmentMode
                                           heightMode:heightMode
                                     useAlignmentMode:&useAlignmentMode
                                          labelHeight:nil
                                              offsetY:&offsetY];
      labelNode.verticalAlignmentMode = useAlignmentMode;
      CGPoint labelNodePosition = labelNode.position;
      labelNodePosition.y = labelNodePosition.y + offsetY + additionalOffsetY;
      labelNode.position = labelNodePosition;
    }
  }
}

NSArray *
HLStackLayoutManagerBaselineCellOffsetsFromVisualCenter(NSArray *nodes,
                                                        HLLabelHeightMode heightMode,
                                                        CGFloat additionalOffsetY)
{
  NSMutableArray *cellOffsets = [NSMutableArray array];
  NSMutableArray *duplicateCellOffsets = [NSMutableArray array];
  CGFloat lastCellOffset = 0.0f;

  for (id node in nodes) {
    CGFloat cellOffset;
    if ([node isKindOfClass:[SKLabelNode class]]) {
      SKLabelNode *labelNode = (SKLabelNode *)node;
      // note: Could check labelNode.verticalAlignmentMode == baseline, and issue a
      // warning if not.  But for now, trust the caller.
      CGFloat baselineOffsetY = [labelNode baselineOffsetYFromVisualCenterForHeightMode:heightMode];
      cellOffset = baselineOffsetY + additionalOffsetY;
    } else {
      cellOffset = 0.0f;
    }
    if (fabs(cellOffset - lastCellOffset) < HLStackLayoutManagerEpsilon) {
      [duplicateCellOffsets addObject:@(cellOffset)];
    } else {
      [cellOffsets addObjectsFromArray:duplicateCellOffsets];
      [duplicateCellOffsets removeAllObjects];
      [cellOffsets addObject:@(cellOffset)];
      lastCellOffset = cellOffset;
    }
  }

  return cellOffsets;
}

@implementation HLStackLayoutManager

- (instancetype)init
{
  self = [super init];
  if (self) {
    _anchorPoint = 0.5f;
  }
  return self;
}

- (instancetype)initWithStackDirection:(HLStackLayoutManagerStackDirection)stackDirection
{
  self = [super init];
  if (self) {
    _anchorPoint = 0.5f;
    _stackDirection = stackDirection;
  }
  return self;
}

- (instancetype)initWithStackDirection:(HLStackLayoutManagerStackDirection)stackDirection
                           cellLengths:(NSArray *)cellLengths
{
  self = [super init];
  if (self) {
    _anchorPoint = 0.5f;
    _stackDirection = stackDirection;
    _cellLengths = cellLengths;
  }
  return self;
}

- (instancetype)initWithStackDirection:(HLStackLayoutManagerStackDirection)stackDirection
                           cellLengths:(NSArray *)cellLengths
                      cellAnchorPoints:(NSArray *)cellAnchorPoints;
{
  self = [super init];
  if (self) {
    _anchorPoint = 0.5f;
    _stackDirection = stackDirection;
    _cellLengths = cellLengths;
    _cellAnchorPoints = cellAnchorPoints;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super init];
  if (self) {
    _stackDirection = [aDecoder decodeIntegerForKey:@"stackDirection"];
    _anchorPoint = (CGFloat)[aDecoder decodeDoubleForKey:@"anchorPoint"];
#if TARGET_OS_IPHONE
    _stackPosition = [aDecoder decodeCGPointForKey:@"stackPosition"];
#else
    _stackPosition = [aDecoder decodePointForKey:@"stackPosition"];
#endif
    _constrainedLength = (CGFloat)[aDecoder decodeDoubleForKey:@"constrainedLength"];
    _cellLengths = [aDecoder decodeObjectForKey:@"cellLengths"];
    _cellAnchorPoints = [aDecoder decodeObjectForKey:@"cellAnchorPoints"];
    _cellOffsets = [aDecoder decodeObjectForKey:@"cellOffsets"];
    _stackBorder = (CGFloat)[aDecoder decodeDoubleForKey:@"stackBorder"];
    _cellSeparator = (CGFloat)[aDecoder decodeDoubleForKey:@"cellSeparator"];
    _length = (CGFloat)[aDecoder decodeDoubleForKey:@"length"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [aCoder encodeInteger:_stackDirection forKey:@"stackDirection"];
  [aCoder encodeDouble:_anchorPoint forKey:@"anchorPoint"];
#if TARGET_OS_IPHONE
  [aCoder encodeCGPoint:_stackPosition forKey:@"stackPosition"];
#else
  [aCoder encodePoint:_stackPosition forKey:@"stackPosition"];
#endif
  [aCoder encodeDouble:_constrainedLength forKey:@"constrainedLength"];
  [aCoder encodeObject:_cellLengths forKey:@"cellLengths"];
  [aCoder encodeObject:_cellAnchorPoints forKey:@"cellAnchorPoints"];
  [aCoder encodeObject:_cellOffsets forKey:@"cellOffsets"];
  [aCoder encodeDouble:_stackBorder forKey:@"stackBorder"];
  [aCoder encodeDouble:_cellSeparator forKey:@"cellSeparator"];
  [aCoder encodeDouble:_length forKey:@"length"];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
  HLStackLayoutManager *copy = [[[self class] allocWithZone:zone] init];
  if (copy) {
    copy->_stackDirection = _stackDirection;
    copy->_anchorPoint = _anchorPoint;
    copy->_stackPosition = _stackPosition;
    copy->_constrainedLength = _constrainedLength;
    copy->_cellLengths = [_cellLengths copyWithZone:zone];
    copy->_cellAnchorPoints = [_cellAnchorPoints copyWithZone:zone];
    copy->_cellOffsets = [_cellOffsets copyWithZone:zone];
    copy->_stackBorder = _stackBorder;
    copy->_cellSeparator = _cellSeparator;
    copy->_length = _length;
  }
  return copy;
}

- (void)layout:(NSArray *)nodes
withLabelNodesVerticalAlign:(SKLabelVerticalAlignmentMode)alignmentMode
    heightMode:(HLLabelHeightMode)heightMode
additionalOffsetY:(CGFloat)additionalOffsetY
{
  [self layout:nodes];
  HLStackLayoutManagerVerticalAlignLabelNodes(nodes, alignmentMode, heightMode, additionalOffsetY);
}

- (void)layout:(NSArray *)nodes
{
  NSUInteger nodesCount = (nodes ? [nodes count] : 0);
  if (nodesCount == 0) {
    return;
  }
  NSUInteger cellLengthsCount = (_cellLengths ? [_cellLengths count] : 0);
  NSUInteger cellAnchorPointsCount = (_cellAnchorPoints ? [_cellAnchorPoints count] : 0);
  NSUInteger cellOffsetsCount = (_cellOffsets ? [_cellOffsets count] : 0);

  CGFloat (*cellLengthAutoFunction)(id);
  switch (_stackDirection) {
    case HLStackLayoutManagerStackRight:
    case HLStackLayoutManagerStackLeft:
      cellLengthAutoFunction = &HLLayoutManagerGetNodeWidth;
      break;
    case HLStackLayoutManagerStackUp:
    case HLStackLayoutManagerStackDown:
      cellLengthAutoFunction = &HLLayoutManagerGetNodeHeight;
      break;
  }

  // First pass: Calculate fixed-size lengths, and sum expanding-length ratios.
  CGFloat *finalCellLengths = (CGFloat *)malloc(nodesCount * sizeof(CGFloat));
  CGFloat lengthTotalFixed = 0.0f;
  CGFloat lengthExpandingRatioSum = 0.0f;
  {
    CGFloat cellLength = 0.0f;
    for (NSUInteger nodeIndex = 0; nodeIndex < nodesCount; ++nodeIndex) {
      if (nodeIndex < cellLengthsCount) {
        NSNumber *cellLengthNumber = _cellLengths[nodeIndex];
        cellLength = (CGFloat)[cellLengthNumber doubleValue];
      }
      if (cellLength > HLStackLayoutManagerEpsilon) {
        lengthTotalFixed += cellLength;
        finalCellLengths[nodeIndex] = cellLength;
      } else if (cellLength < -HLStackLayoutManagerEpsilon) {
        lengthExpandingRatioSum += cellLength;
        finalCellLengths[nodeIndex] = cellLength;
      } else {
        // note: Leave cellLength zero so subsequent nodes reusing this cellLength
        // get recalculated.
        CGFloat cellLengthAuto = cellLengthAutoFunction(nodes[nodeIndex]);
        lengthTotalFixed += cellLengthAuto;
        finalCellLengths[nodeIndex] = cellLengthAuto;
      }
    }
  }
  CGFloat lengthTotalConstant = _cellSeparator * (nodesCount - 1) + _stackBorder * 2.0f;
  CGFloat lengthTotalExpanding = 0.0f;
  if (lengthExpandingRatioSum < 0.0 && _constrainedLength > (lengthTotalFixed + lengthTotalConstant)) {
    lengthTotalExpanding = _constrainedLength - lengthTotalFixed - lengthTotalConstant;
  }
  _length = lengthTotalFixed + lengthTotalExpanding + lengthTotalConstant;

  // note: s is the absolute position of the edge of the cell closest to the stack start,
  // for example the left edge in a rightwards stack, or the top edge in a downwards
  // stack.
  CGFloat s;
  switch (_stackDirection) {
    case HLStackLayoutManagerStackRight:
      s = _stackPosition.x + _length * -1.0f * _anchorPoint + _stackBorder;
      break;
    case HLStackLayoutManagerStackLeft:
      s = _stackPosition.x + _length * (1.0f - _anchorPoint) - _stackBorder;
      break;
    case HLStackLayoutManagerStackUp:
      s = _stackPosition.y + _length * -1.0f * _anchorPoint + _stackBorder;
      break;
    case HLStackLayoutManagerStackDown:
      s = _stackPosition.y + _length * (1.0f - _anchorPoint) - _stackBorder;
      break;
  }
  CGFloat cellAnchorPoint = 0.5f;
  CGFloat cellOffset = 0.0f;

  for (NSUInteger nodeIndex = 0; nodeIndex < nodesCount; ++nodeIndex) {
    id node = nodes[nodeIndex];

    CGFloat cellLength = finalCellLengths[nodeIndex];
    if (cellLength < -HLStackLayoutManagerEpsilon) {
      cellLength = lengthTotalExpanding / lengthExpandingRatioSum * cellLength;
    }

    if (nodeIndex < cellAnchorPointsCount) {
      NSNumber *cellAnchorPointValue = _cellAnchorPoints[nodeIndex];
      cellAnchorPoint = (CGFloat)[cellAnchorPointValue doubleValue];
    }

    if (nodeIndex < cellOffsetsCount) {
      NSNumber *cellOffsetValue = _cellOffsets[nodeIndex];
      cellOffset = (CGFloat)[cellOffsetValue doubleValue];
    }

    switch (_stackDirection) {
      case HLStackLayoutManagerStackRight:
        if ([node isKindOfClass:[SKNode class]]) {
          [(SKNode *)node setPosition:CGPointMake(s + cellLength * cellAnchorPoint + cellOffset,
                                                  _stackPosition.y)];
        }
        s = s + cellLength + _cellSeparator;
        break;
      case HLStackLayoutManagerStackLeft:
        if ([node isKindOfClass:[SKNode class]]) {
          [(SKNode *)node setPosition:CGPointMake(s - cellLength * (1.0f - cellAnchorPoint) + cellOffset,
                                                  _stackPosition.y)];
        }
        s = s - cellLength - _cellSeparator;
        break;
      case HLStackLayoutManagerStackUp:
        if ([node isKindOfClass:[SKNode class]]) {
          [(SKNode *)node setPosition:CGPointMake(_stackPosition.x,
                                                  s + cellLength * cellAnchorPoint + cellOffset)];
        }
        s = s + cellLength + _cellSeparator;
        break;
      case HLStackLayoutManagerStackDown:
        if ([node isKindOfClass:[SKNode class]]) {
          [(SKNode *)node setPosition:CGPointMake(_stackPosition.x,
                                                  s - cellLength * (1.0f - cellAnchorPoint) + cellOffset)];
        }
        s = s - cellLength - _cellSeparator;
        break;
    }
  }

  free(finalCellLengths);
}

@end
