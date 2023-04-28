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
    _cellLabelOffsetY = (CGFloat)[aDecoder decodeDoubleForKey:@"cellLabelOffsetY"];
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
  [aCoder encodeDouble:_cellLabelOffsetY forKey:@"cellLabelOffsetY"];
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
    copy->_cellLabelOffsetY = _cellLabelOffsetY;
    copy->_stackBorder = _stackBorder;
    copy->_cellSeparator = _cellSeparator;
    copy->_length = _length;
  }
  return copy;
}

- (void)layout:(NSArray *)nodes
{
  [self GL_layout:nodes getCellLengths:nil];
}

- (void)layout:(NSArray *)nodes getCellLengths:(NSArray * __autoreleasing *)cellLengths
{
  [self GL_layout:nodes getCellLengths:cellLengths];
}

- (void)GL_layout:(NSArray *)nodes getCellLengths:(NSArray * __autoreleasing *)returnCellLengths
{
  NSUInteger nodesCount = (nodes ? [nodes count] : 0);
  if (nodesCount == 0) {
    return;
  }
  NSUInteger cellLengthsCount = (_cellLengths ? [_cellLengths count] : 0);
  NSUInteger cellAnchorPointsCount = (_cellAnchorPoints ? [_cellAnchorPoints count] : 0);

  CGFloat (*cellLengthFitFunction)(id);
  switch (_stackDirection) {
    case HLStackLayoutManagerStackRight:
    case HLStackLayoutManagerStackLeft:
      cellLengthFitFunction = &HLLayoutManagerGetNodeWidth;
      break;
    case HLStackLayoutManagerStackUp:
    case HLStackLayoutManagerStackDown:
      cellLengthFitFunction = &HLLayoutManagerGetNodeHeight;
      break;
  }

  // First pass: Calculate fixed-size lengths, and sum fill-length ratios.
  CGFloat *finalCellLengths = (CGFloat *)malloc(nodesCount * sizeof(CGFloat));
  CGFloat lengthTotalFixed = 0.0f;
  CGFloat lengthFillRatioSum = 0.0f;
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
        lengthFillRatioSum += cellLength;
        finalCellLengths[nodeIndex] = cellLength;
      } else {
        // note: Leave cellLength zero so subsequent nodes reusing this cellLength
        // get recalculated.
        CGFloat cellLengthFit = cellLengthFitFunction(nodes[nodeIndex]);
        lengthTotalFixed += cellLengthFit;
        finalCellLengths[nodeIndex] = cellLengthFit;
      }
    }
  }
  CGFloat lengthTotalConstant = _cellSeparator * (nodesCount - 1) + _stackBorder * 2.0f;
  CGFloat lengthTotalFill = 0.0f;
  if (lengthFillRatioSum < 0.0 && _constrainedLength > (lengthTotalFixed + lengthTotalConstant)) {
    lengthTotalFill = _constrainedLength - lengthTotalFixed - lengthTotalConstant;
  }
  _length = lengthTotalFixed + lengthTotalFill + lengthTotalConstant;
  if (returnCellLengths) {
    NSMutableArray *rcl = [NSMutableArray array];
    for (NSUInteger nodeIndex = 0; nodeIndex < nodesCount; ++nodeIndex) {
      [rcl addObject:[NSNumber numberWithDouble:finalCellLengths[nodeIndex]]];
    }
    *returnCellLengths = rcl;
  }

  // note: s is the absolute position of the edge of the cell closest to the stack start,
  // for example the left edge in a rightwards stack, or the top edge in a downwards
  // stack.
  CGFloat s;
  switch (_stackDirection) {
    case HLStackLayoutManagerStackRight:
      s = _stackPosition.x - _length * _anchorPoint + _stackBorder;
      break;
    case HLStackLayoutManagerStackLeft:
      s = _stackPosition.x + _length * (1.0f - _anchorPoint) - _stackBorder;
      break;
    case HLStackLayoutManagerStackUp:
      s = _stackPosition.y - _length * _anchorPoint + _stackBorder;
      break;
    case HLStackLayoutManagerStackDown:
      s = _stackPosition.y + _length * (1.0f - _anchorPoint) - _stackBorder;
      break;
  }
  CGFloat cellAnchorPoint = 0.5f;

  for (NSUInteger nodeIndex = 0; nodeIndex < nodesCount; ++nodeIndex) {
    id node = nodes[nodeIndex];

    CGFloat cellLength = finalCellLengths[nodeIndex];
    if (cellLength < -HLStackLayoutManagerEpsilon) {
      cellLength = lengthTotalFill / lengthFillRatioSum * cellLength;
    }

    if (nodeIndex < cellAnchorPointsCount) {
      NSNumber *cellAnchorPointValue = _cellAnchorPoints[nodeIndex];
      cellAnchorPoint = (CGFloat)[cellAnchorPointValue doubleValue];
    }

    CGFloat cellOffsetY = 0.0f;
    if ([node isKindOfClass:[SKLabelNode class]]) {
      cellOffsetY = _cellLabelOffsetY;
    }

    switch (_stackDirection) {
      case HLStackLayoutManagerStackRight:
        if ([node isKindOfClass:[SKNode class]]) {
          [(SKNode *)node setPosition:CGPointMake(s + cellLength * cellAnchorPoint,
                                                  _stackPosition.y + cellOffsetY)];
        }
        s = s + cellLength + _cellSeparator;
        break;
      case HLStackLayoutManagerStackLeft:
        if ([node isKindOfClass:[SKNode class]]) {
          [(SKNode *)node setPosition:CGPointMake(s - cellLength * (1.0f - cellAnchorPoint),
                                                  _stackPosition.y + cellOffsetY)];
        }
        s = s - cellLength - _cellSeparator;
        break;
      case HLStackLayoutManagerStackUp:
        if ([node isKindOfClass:[SKNode class]]) {
          [(SKNode *)node setPosition:CGPointMake(_stackPosition.x,
                                                  s + cellLength * cellAnchorPoint + cellOffsetY)];
        }
        s = s + cellLength + _cellSeparator;
        break;
      case HLStackLayoutManagerStackDown:
        if ([node isKindOfClass:[SKNode class]]) {
          [(SKNode *)node setPosition:CGPointMake(_stackPosition.x,
                                                  s - cellLength * (1.0f - cellAnchorPoint) + cellOffsetY)];
        }
        s = s - cellLength - _cellSeparator;
        break;
    }
  }

  free(finalCellLengths);
}

@end

NSUInteger
HLStackLayoutManagerCellContainingPoint(NSArray *nodes,
                                        CGFloat point,
                                        HLStackLayoutManagerStackDirection stackDirection,
                                        NSArray *cellLengths,
                                        NSArray *cellAnchorPoints,
                                        CGFloat cellLabelOffsetY)
{
  NSUInteger nodesCount = [nodes count];

  NSUInteger cellLengthsCount = (cellLengths ? [cellLengths count] : 0);
  NSUInteger cellAnchorPointsCount = (cellAnchorPoints ? [cellAnchorPoints count] : 0);

  SKNode *pointNode = [SKNode node];
  pointNode.position = CGPointMake(point, point);

  // note: Could do the binary search by copying position data from the nodes into an
  // array, but that would introduce an order-N operation, so in principle it seems
  // wrongheaded.

  // note: NSArray considers "ascending" direction to be from the first element of the
  // sorted array to the last element of the sorted array, so for left and down, the
  // descending numerical position is considered "ascending".
  NSComparisonResult (^comparator)(SKNode *node1, SKNode *node2) = nil;
  switch (stackDirection) {
    case HLStackLayoutManagerStackRight:
      comparator = ^NSComparisonResult(SKNode *node1, SKNode *node2){
        if (node1.position.x < node2.position.x) {
          return NSOrderedAscending;
        } else if (node1.position.x > node2.position.x) {
          return NSOrderedDescending;
        } else {
          return NSOrderedSame;
        }
      };
      break;
    case HLStackLayoutManagerStackLeft:
      comparator = ^NSComparisonResult(SKNode *node1, SKNode *node2){
        if (node1.position.x > node2.position.x) {
          return NSOrderedAscending;
        } else if (node1.position.x < node2.position.x) {
          return NSOrderedDescending;
        } else {
          return NSOrderedSame;
        }
      };
      break;
    case HLStackLayoutManagerStackUp:
      comparator = ^NSComparisonResult(SKNode *node1, SKNode *node2){
        if (node1.position.y < node2.position.y) {
          return NSOrderedAscending;
        } else if (node1.position.y > node2.position.y) {
          return NSOrderedDescending;
        } else {
          return NSOrderedSame;
        }
      };
      break;
    case HLStackLayoutManagerStackDown:
      comparator = ^NSComparisonResult(SKNode *node1, SKNode *node2){
        if (node1.position.y > node2.position.y) {
          return NSOrderedAscending;
        } else if (node1.position.y < node2.position.y) {
          return NSOrderedDescending;
        } else {
          return NSOrderedSame;
        }
      };
      break;
  }

  NSUInteger nextNodeIndex = [nodes indexOfObject:pointNode
                                    inSortedRange:NSMakeRange(0, nodesCount)
                                          options:NSBinarySearchingInsertionIndex
                                  usingComparator:comparator];

  // note: nextNodeIndex is the node with array position greater than pointNode; for right
  // and up, the next-node position will be greater, and for left and down the next-node
  // position will be smaller.  The node that contains the point is either that node or
  // the previous one (in the array).  Using [begin, end) range terminology.
  NSUInteger checkNodeIndexBegin = (nextNodeIndex > 0 ? nextNodeIndex - 1 : nextNodeIndex);
  NSUInteger checkNodeIndexEnd = (nextNodeIndex < nodesCount ? nextNodeIndex + 1 : nextNodeIndex);
  for (NSUInteger nodeIndex = checkNodeIndexBegin; nodeIndex < checkNodeIndexEnd; ++nodeIndex) {

    SKNode *node = nodes[nodeIndex];

    CGFloat cellLength = 0.0f;
    if (nodeIndex < cellLengthsCount) {
      cellLength = [cellLengths[nodeIndex] doubleValue];
    } else if (cellLengthsCount > 0) {
      cellLength = [cellLengths[cellLengthsCount - 1] doubleValue];
    }
    if (cellLength < HLStackLayoutManagerEpsilon) {
      cellLength = HLLayoutManagerGetNodeHeight(node);
    }

    CGFloat anchorPoint = 0.5f;
    if (nodeIndex < cellAnchorPointsCount) {
      anchorPoint = [cellAnchorPoints[nodeIndex] doubleValue];
    } else if (cellAnchorPointsCount > 0) {
      anchorPoint = [cellAnchorPoints[cellAnchorPointsCount - 1] doubleValue];
    }

    switch (stackDirection) {
      case HLStackLayoutManagerStackRight:
      case HLStackLayoutManagerStackLeft: {
        CGFloat nodePosition = node.position.x;
        if (point <= nodePosition + cellLength * (1.0f - anchorPoint)
            && point >= nodePosition - cellLength * anchorPoint) {
          return nodeIndex;
        }
        break;
      }
      case HLStackLayoutManagerStackUp:
      case HLStackLayoutManagerStackDown: {
        CGFloat nodePosition = node.position.y;
        if ([node isKindOfClass:[SKLabelNode class]]) {
          if (point <= nodePosition - cellLabelOffsetY + cellLength * (1.0f - anchorPoint)
              && point >= nodePosition - cellLabelOffsetY - cellLength * anchorPoint) {
            return nodeIndex;
          }
        } else {
          if (point <= nodePosition + cellLength * (1.0f - anchorPoint)
              && point >= nodePosition - cellLength * anchorPoint) {
            return nodeIndex;
          }
        }
        break;
      }
    }

  }

  return NSNotFound;
}
