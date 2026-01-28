//
//  HLWrapLayoutManager.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 3/12/24.
//  Copyright © 2024 Hilo Games. All rights reserved.
//

#import "HLWrapLayoutManager.h"

#import <TargetConditionals.h>

const CGFloat HLWrapLayoutManagerEpsilon = 0.001f;

@implementation HLWrapLayoutManager

- (instancetype)init
{
  self = [super init];
  if (self) {
    _anchorPoint = CGPointMake(0.5f, 0.5f);
    _cellAnchorPoint = 0.5f;
  }
  return self;
}

- (instancetype)initWithFillMode:(HLWrapLayoutManagerFillMode)fillMode
                   maximumLength:(CGFloat)maximumLength
                   justification:(HLWrapLayoutManagerJustification)justification
                   lineSeparator:(CGFloat)lineSeparator
{
  self = [super init];
  if (self) {
    _fillMode = fillMode;
    _maximumLength = maximumLength;
    _justification = justification;
    _lineSeparator = lineSeparator;
    _anchorPoint = CGPointMake(0.5f, 0.5f);
    _cellAnchorPoint = 0.5f;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super init];
  if (self) {
    _fillMode = [aDecoder decodeIntegerForKey:@"fillMode"];
    _maximumLength = (CGFloat)[aDecoder decodeDoubleForKey:@"maximumLength"];
    _justification = [aDecoder decodeIntegerForKey:@"justification"];
    _lineSeparator = (CGFloat)[aDecoder decodeDoubleForKey:@"lineSeparator"];
#if TARGET_OS_IPHONE
    _anchorPoint = [aDecoder decodeCGPointForKey:@"anchorPoint"];
    _wrapPosition = [aDecoder decodeCGPointForKey:@"wrapPosition"];
#else
    _anchorPoint = [aDecoder decodePointForKey:@"anchorPoint"];
    _wrapPosition = [aDecoder decodePointForKey:@"wrapPosition"];
#endif
    _cellAnchorPoint = (CGFloat)[aDecoder decodeDoubleForKey:@"cellAnchorPoint"];
    _wrapBorder = (CGFloat)[aDecoder decodeDoubleForKey:@"wrapBorder"];
    _cellSeparator = (CGFloat)[aDecoder decodeDoubleForKey:@"cellSeparator"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [aCoder encodeInteger:_fillMode forKey:@"fillMode"];
  [aCoder encodeDouble:_maximumLength forKey:@"maximumLength"];
  [aCoder encodeInteger:_justification forKey:@"justification"];
  [aCoder encodeDouble:_lineSeparator forKey:@"lineSeparator"];
#if TARGET_OS_IPHONE
  [aCoder encodeCGPoint:_anchorPoint forKey:@"anchorPoint"];
  [aCoder encodeCGPoint:_wrapPosition forKey:@"wrapPosition"];
#else
  [aCoder encodePoint:_anchorPoint forKey:@"anchorPoint"];
  [aCoder encodePoint:_wrapPosition forKey:@"wrapPosition"];
#endif
  [aCoder encodeDouble:_cellAnchorPoint forKey:@"cellAnchorPoint"];
  [aCoder encodeDouble:_wrapBorder forKey:@"wrapBorder"];
  [aCoder encodeDouble:_cellSeparator forKey:@"cellSeparator"];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
  HLWrapLayoutManager *copy = [[[self class] allocWithZone:zone] init];
  if (copy) {
    copy->_fillMode = _fillMode;
    copy->_maximumLength = _maximumLength;
    copy->_justification = _justification;
    copy->_lineSeparator = _lineSeparator;
    copy->_anchorPoint = _anchorPoint;
    copy->_wrapPosition = _wrapPosition;
    copy->_cellAnchorPoint = _cellAnchorPoint;
    copy->_wrapBorder = _wrapBorder;
    copy->_cellSeparator = _cellSeparator;
  }
  return copy;
}

- (void)layout:(NSArray *)nodes
{
  NSUInteger nodesCount = (nodes ? [nodes count] : 0);
  if (nodesCount == 0) {
    return;
  }

  CGFloat justificationFactor;
  switch (_justification) {
    case HLWrapLayoutManagerJustificationNear:
      justificationFactor = 0.0f;
      break;
    case HLWrapLayoutManagerJustificationCenter:
      justificationFactor = 0.5f;
      break;
    case HLWrapLayoutManagerJustificationFar:
      justificationFactor = 1.0f;
      break;
  }

  // First pass: Calculate line lengths and overall size.
  CGFloat (*cellLengthFitFunction)(id);
  switch (_fillMode) {
    case HLWrapLayoutManagerFillRightThenDown:
    case HLWrapLayoutManagerFillRightThenUp:
    case HLWrapLayoutManagerFillLeftThenDown:
    case HLWrapLayoutManagerFillLeftThenUp:
      cellLengthFitFunction = &HLLayoutManagerGetNodeWidth;
      break;
    case HLWrapLayoutManagerFillDownThenRight:
    case HLWrapLayoutManagerFillDownThenLeft:
    case HLWrapLayoutManagerFillUpThenRight:
    case HLWrapLayoutManagerFillUpThenLeft:
      cellLengthFitFunction = &HLLayoutManagerGetNodeHeight;
      break;
  }
  // note: Most possible number of lines is the number of nodes (one per line).
  CGFloat *lineLengths = (CGFloat *)malloc(nodesCount * sizeof(CGFloat));
  CGFloat boundsLength = 0.0f;
  CGFloat boundsBreadth = 0.0f;
  // note: Start first line.
  NSUInteger lineIndex = 0;
  CGFloat lineLength = _wrapBorder;
  // note: Get first node information.
  NSEnumerator *nodesEnumerator = [nodes objectEnumerator];
  SKNode *node = [nodesEnumerator nextObject];
  CGFloat cellLength = cellLengthFitFunction(node);
  while (YES) {
    // note: Add node to line.  (A new line always gets at least one node, regardless of
    // length.)
    lineLength += cellLength;
    // note: Get next node information.
    node = [nodesEnumerator nextObject];
    if (!node) {
      lineLength += _wrapBorder;
      lineLengths[lineIndex] = lineLength;
      if (lineLength > boundsLength) {
        boundsLength = lineLength;
      }
      break;
    }
    cellLength = cellLengthFitFunction(node);
    // note: Continue in this line, or start new line.
    if (lineLength + _cellSeparator + cellLength + _wrapBorder <= _maximumLength) {
      lineLength += _cellSeparator;
    } else {
      lineLength += _wrapBorder;
      lineLengths[lineIndex] = lineLength;
      if (lineLength > boundsLength) {
        boundsLength = lineLength;
      }
      ++lineIndex;
      lineLength = _wrapBorder;
      boundsBreadth += _lineSeparator;
    }
  }
  switch (_fillMode) {
    case HLWrapLayoutManagerFillRightThenDown:
    case HLWrapLayoutManagerFillRightThenUp:
    case HLWrapLayoutManagerFillLeftThenDown:
    case HLWrapLayoutManagerFillLeftThenUp:
      _size = CGSizeMake(boundsLength, boundsBreadth);
      break;
    case HLWrapLayoutManagerFillDownThenRight:
    case HLWrapLayoutManagerFillDownThenLeft:
    case HLWrapLayoutManagerFillUpThenRight:
    case HLWrapLayoutManagerFillUpThenLeft:
      _size = CGSizeMake(boundsBreadth, boundsLength);
      break;
  }

  // Second pass: Position nodes.
  switch (_fillMode) {
    case HLWrapLayoutManagerFillRightThenDown: {
      CGFloat boundsLeft = _wrapPosition.x - _anchorPoint.x * boundsLength;
      CGFloat boundsTop = _wrapPosition.y + (1.0f - _anchorPoint.y) * boundsBreadth;
      // note: Start first line.
      NSUInteger lineIndex = 0;
      CGFloat lineLength = _wrapBorder;
      CGFloat lineX = boundsLeft + justificationFactor * (boundsLength - lineLengths[lineIndex]);
      CGFloat lineY = boundsTop;
      // note: Get first node information.
      NSEnumerator *nodesEnumerator = [nodes objectEnumerator];
      SKNode *node = [nodesEnumerator nextObject];
      CGFloat cellLength = HLLayoutManagerGetNodeWidth(node);
      while (YES) {
        // note: Add node to line.  (A new line always gets at least one node, regardless
        // of length.)
        node.position = CGPointMake(lineX + lineLength + _cellAnchorPoint * cellLength, lineY);
        lineLength += cellLength;
        // note: Get next node information.
        node = [nodesEnumerator nextObject];
        if (!node) {
          break;
        }
        cellLength = HLLayoutManagerGetNodeWidth(node);
        // note: Continue in this line, or start new line.
        if (lineLength + _cellSeparator + cellLength + _wrapBorder <= _maximumLength) {
          lineLength += _cellSeparator;
        } else {
          ++lineIndex;
          lineLength = _wrapBorder;
          lineX = boundsLeft + justificationFactor * (boundsLength - lineLengths[lineIndex]);
          lineY -= _lineSeparator;
        }
      }
      break;
    }
    case HLWrapLayoutManagerFillRightThenUp: {
      CGFloat boundsLeft = _wrapPosition.x - _anchorPoint.x * boundsLength;
      CGFloat boundsBottom = _wrapPosition.y - _anchorPoint.y * boundsBreadth;
      // note: Start first line.
      NSUInteger lineIndex = 0;
      CGFloat lineLength = _wrapBorder;
      CGFloat lineX = boundsLeft + justificationFactor * (boundsLength - lineLengths[lineIndex]);
      CGFloat lineY = boundsBottom;
      // note: Get first node information.
      NSEnumerator *nodesEnumerator = [nodes objectEnumerator];
      SKNode *node = [nodesEnumerator nextObject];
      CGFloat cellLength = HLLayoutManagerGetNodeWidth(node);
      while (YES) {
        // note: Add node to line.  (A new line always gets at least one node, regardless
        // of length.)
        node.position = CGPointMake(lineX + lineLength + _cellAnchorPoint * cellLength, lineY);
        lineLength += cellLength;
        // note: Get next node information.
        node = [nodesEnumerator nextObject];
        if (!node) {
          break;
        }
        cellLength = HLLayoutManagerGetNodeWidth(node);
        // note: Continue in this line, or start new line.
        if (lineLength + _cellSeparator + cellLength + _wrapBorder <= _maximumLength) {
          lineLength += _cellSeparator;
        } else {
          ++lineIndex;
          lineLength = _wrapBorder;
          lineX = boundsLeft + justificationFactor * (boundsLength - lineLengths[lineIndex]);
          lineY += _lineSeparator;
        }
      }
      break;
    }
    case HLWrapLayoutManagerFillLeftThenDown: {
      CGFloat boundsRight = _wrapPosition.x + (1.0f - _anchorPoint.x) * boundsLength;
      CGFloat boundsTop = _wrapPosition.y + (1.0f - _anchorPoint.y) * boundsBreadth;
      // note: Start first line.
      NSUInteger lineIndex = 0;
      CGFloat lineLength = _wrapBorder;
      CGFloat lineX = boundsRight - justificationFactor * (boundsLength - lineLengths[lineIndex]);
      CGFloat lineY = boundsTop;
      // note: Get first node information.
      NSEnumerator *nodesEnumerator = [nodes objectEnumerator];
      SKNode *node = [nodesEnumerator nextObject];
      CGFloat cellLength = HLLayoutManagerGetNodeWidth(node);
      while (YES) {
        // note: Add node to line.  (A new line always gets at least one node, regardless
        // of length.)
        node.position = CGPointMake(lineX - lineLength - _cellAnchorPoint * cellLength, lineY);
        lineLength += cellLength;
        // note: Get next node information.
        node = [nodesEnumerator nextObject];
        if (!node) {
          break;
        }
        cellLength = HLLayoutManagerGetNodeWidth(node);
        // note: Continue in this line, or start new line.
        if (lineLength + _cellSeparator + cellLength + _wrapBorder <= _maximumLength) {
          lineLength += _cellSeparator;
        } else {
          ++lineIndex;
          lineLength = _wrapBorder;
          lineX = boundsRight - justificationFactor * (boundsLength - lineLengths[lineIndex]);
          lineY -= _lineSeparator;
        }
      }
      break;
    }
    case HLWrapLayoutManagerFillLeftThenUp: {
      CGFloat boundsRight = _wrapPosition.x + (1.0f - _anchorPoint.x) * boundsLength;
      CGFloat boundsBottom = _wrapPosition.y - _anchorPoint.y * boundsBreadth;
      // note: Start first line.
      NSUInteger lineIndex = 0;
      CGFloat lineLength = _wrapBorder;
      CGFloat lineX = boundsRight - justificationFactor * (boundsLength - lineLengths[lineIndex]);
      CGFloat lineY = boundsBottom;
      // note: Get first node information.
      NSEnumerator *nodesEnumerator = [nodes objectEnumerator];
      SKNode *node = [nodesEnumerator nextObject];
      CGFloat cellLength = HLLayoutManagerGetNodeWidth(node);
      while (YES) {
        // note: Add node to line.  (A new line always gets at least one node, regardless
        // of length.)
        node.position = CGPointMake(lineX - lineLength - _cellAnchorPoint * cellLength, lineY);
        lineLength += cellLength;
        // note: Get next node information.
        node = [nodesEnumerator nextObject];
        if (!node) {
          break;
        }
        cellLength = HLLayoutManagerGetNodeWidth(node);
        // note: Continue in this line, or start new line.
        if (lineLength + _cellSeparator + cellLength + _wrapBorder <= _maximumLength) {
          lineLength += _cellSeparator;
        } else {
          ++lineIndex;
          lineLength = _wrapBorder;
          lineX = boundsRight - justificationFactor * (boundsLength - lineLengths[lineIndex]);
          lineY += _lineSeparator;
        }
      }
      break;
    }
    case HLWrapLayoutManagerFillDownThenRight: {
      CGFloat boundsLeft = _wrapPosition.x - _anchorPoint.x * boundsBreadth;
      CGFloat boundsTop = _wrapPosition.y + (1.0f - _anchorPoint.y) * boundsLength;
      // note: Start first line.
      NSUInteger lineIndex = 0;
      CGFloat lineLength = _wrapBorder;
      CGFloat lineX = boundsLeft;
      CGFloat lineY = boundsTop - justificationFactor * (boundsLength - lineLengths[lineIndex]);
      // note: Get first node information.
      NSEnumerator *nodesEnumerator = [nodes objectEnumerator];
      SKNode *node = [nodesEnumerator nextObject];
      CGFloat cellLength = HLLayoutManagerGetNodeHeight(node);
      while (YES) {
        // note: Add node to line.  (A new line always gets at least one node, regardless
        // of length.)
        node.position = CGPointMake(lineX, lineY - lineLength - _cellAnchorPoint * cellLength);
        lineLength += cellLength;
        // note: Get next node information.
        node = [nodesEnumerator nextObject];
        if (!node) {
          break;
        }
        cellLength = HLLayoutManagerGetNodeHeight(node);
        // note: Continue in this line, or start new line.
        if (lineLength + _cellSeparator + cellLength + _wrapBorder <= _maximumLength) {
          lineLength += _cellSeparator;
        } else {
          ++lineIndex;
          lineLength = _wrapBorder;
          lineX += _lineSeparator;
          lineY = boundsTop - justificationFactor * (boundsLength - lineLengths[lineIndex]);
        }
      }
      break;
    }
    case HLWrapLayoutManagerFillDownThenLeft: {
      CGFloat boundsRight = _wrapPosition.x + (1.0f - _anchorPoint.x) * boundsBreadth;
      CGFloat boundsTop = _wrapPosition.y + (1.0f - _anchorPoint.y) * boundsLength;
      // note: Start first line.
      NSUInteger lineIndex = 0;
      CGFloat lineLength = _wrapBorder;
      CGFloat lineX = boundsRight;
      CGFloat lineY = boundsTop - justificationFactor * (boundsLength - lineLengths[lineIndex]);
      // note: Get first node information.
      NSEnumerator *nodesEnumerator = [nodes objectEnumerator];
      SKNode *node = [nodesEnumerator nextObject];
      CGFloat cellLength = HLLayoutManagerGetNodeHeight(node);
      while (YES) {
        // note: Add node to line.  (A new line always gets at least one node, regardless
        // of length.)
        node.position = CGPointMake(lineX, lineY - lineLength - _cellAnchorPoint * cellLength);
        lineLength += cellLength;
        // note: Get next node information.
        node = [nodesEnumerator nextObject];
        if (!node) {
          break;
        }
        cellLength = HLLayoutManagerGetNodeHeight(node);
        // note: Continue in this line, or start new line.
        if (lineLength + _cellSeparator + cellLength + _wrapBorder <= _maximumLength) {
          lineLength += _cellSeparator;
        } else {
          ++lineIndex;
          lineLength = _wrapBorder;
          lineX -= _lineSeparator;
          lineY = boundsTop - justificationFactor * (boundsLength - lineLengths[lineIndex]);
        }
      }
      break;
    }
    case HLWrapLayoutManagerFillUpThenRight: {
      CGFloat boundsLeft = _wrapPosition.x - _anchorPoint.x * boundsBreadth;
      CGFloat boundsBottom = _wrapPosition.y - _anchorPoint.y * boundsLength;
      // note: Start first line.
      NSUInteger lineIndex = 0;
      CGFloat lineLength = _wrapBorder;
      CGFloat lineX = boundsLeft;
      CGFloat lineY = boundsBottom + justificationFactor * (boundsLength - lineLengths[lineIndex]);
      // note: Get first node information.
      NSEnumerator *nodesEnumerator = [nodes objectEnumerator];
      SKNode *node = [nodesEnumerator nextObject];
      CGFloat cellLength = HLLayoutManagerGetNodeHeight(node);
      while (YES) {
        // note: Add node to line.  (A new line always gets at least one node, regardless
        // of length.)
        node.position = CGPointMake(lineX, lineY + lineLength + _cellAnchorPoint * cellLength);
        lineLength += cellLength;
        // note: Get next node information.
        node = [nodesEnumerator nextObject];
        if (!node) {
          break;
        }
        cellLength = HLLayoutManagerGetNodeHeight(node);
        // note: Continue in this line, or start new line.
        if (lineLength + _cellSeparator + cellLength + _wrapBorder <= _maximumLength) {
          lineLength += _cellSeparator;
        } else {
          ++lineIndex;
          lineLength = _wrapBorder;
          lineX += _lineSeparator;
          lineY = boundsBottom + justificationFactor * (boundsLength - lineLengths[lineIndex]);
        }
      }
      break;
    }
    case HLWrapLayoutManagerFillUpThenLeft: {
      CGFloat boundsRight = _wrapPosition.x + (1.0f - _anchorPoint.x) * boundsBreadth;
      CGFloat boundsBottom = _wrapPosition.y - _anchorPoint.y * boundsLength;
      // note: Start first line.
      NSUInteger lineIndex = 0;
      CGFloat lineLength = _wrapBorder;
      CGFloat lineX = boundsRight;
      CGFloat lineY = boundsBottom + justificationFactor * (boundsLength - lineLengths[lineIndex]);
      // note: Get first node information.
      NSEnumerator *nodesEnumerator = [nodes objectEnumerator];
      SKNode *node = [nodesEnumerator nextObject];
      CGFloat cellLength = HLLayoutManagerGetNodeHeight(node);
      while (YES) {
        // note: Add node to line.  (A new line always gets at least one node, regardless
        // of length.)
        node.position = CGPointMake(lineX, lineY + lineLength + _cellAnchorPoint * cellLength);
        lineLength += cellLength;
        // note: Get next node information.
        node = [nodesEnumerator nextObject];
        if (!node) {
          break;
        }
        cellLength = HLLayoutManagerGetNodeHeight(node);
        // note: Continue in this line, or start new line.
        if (lineLength + _cellSeparator + cellLength + _wrapBorder <= _maximumLength) {
          lineLength += _cellSeparator;
        } else {
          ++lineIndex;
          lineLength = _wrapBorder;
          lineX -= _lineSeparator;
          lineY = boundsBottom + justificationFactor * (boundsLength - lineLengths[lineIndex]);
        }
      }
      break;
    }
  }

  free(lineLengths);
}

@end
