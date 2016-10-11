//
//  HLGridLayoutManager.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 10/11/16.
//  Copyright (c) 2016 Hilo Games. All rights reserved.
//

#import "HLGridLayoutManager.h"

#import <TargetConditionals.h>

@implementation HLGridLayoutManager

- (instancetype)init
{
  self = [super init];
  if (self) {
    _anchorPoint = CGPointMake(0.5f, 0.5f);
    _squareAnchorPoint = CGPointMake(0.5f, 0.5f);
    _fillMode = HLGridLayoutManagerFillRightThenDown;
  }
  return self;
}

- (instancetype)initWithColumnCount:(NSUInteger)columnCount
                         squareSize:(CGSize)squareSize
{
  self = [super init];
  if (self) {
    _columnCount = columnCount;
    _squareSize = squareSize;
    _anchorPoint = CGPointMake(0.5f, 0.5f);
    _squareAnchorPoint = CGPointMake(0.5f, 0.5f);
    _fillMode = HLGridLayoutManagerFillRightThenDown;
  }
  return self;
}

- (instancetype)initWithRowCount:(NSUInteger)rowCount
                      squareSize:(CGSize)squareSize
{
  self = [super init];
  if (self) {
    _rowCount = rowCount;
    _squareSize = squareSize;
    _anchorPoint = CGPointMake(0.5f, 0.5f);
    _squareAnchorPoint = CGPointMake(0.5f, 0.5f);
    _fillMode = HLGridLayoutManagerFillRightThenDown;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super init];
  if (self) {
#if TARGET_OS_IPHONE
    _anchorPoint = [aDecoder decodeCGPointForKey:@"anchorPoint"];
    _gridOffset = [aDecoder decodeCGPointForKey:@"gridOffset"];
#else
    _anchorPoint = [aDecoder decodePointForKey:@"anchorPoint"];
    _gridOffset = [aDecoder decodePointForKey:@"gridOffset"];
#endif
    _columnCount = (NSUInteger)[aDecoder decodeIntegerForKey:@"columnCount"];
    _rowCount = (NSUInteger)[aDecoder decodeIntegerForKey:@"rowCount"];
#if TARGET_OS_IPHONE
    _squareSize = [aDecoder decodeCGSizeForKey:@"squareSize"];
    _squareAnchorPoint = [aDecoder decodeCGPointForKey:@"squareAnchorPoint"];
#else
    _squareSize = [aDecoder decodeSizeForKey:@"squareSize"];
    _squareAnchorPoint = [aDecoder decodePointForKey:@"squareAnchorPoint"];
#endif
    _fillMode = [aDecoder decodeIntegerForKey:@"fillMode"];
    _gridBorder = (CGFloat)[aDecoder decodeDoubleForKey:@"gridBorder"];
    _squareSeparator = (CGFloat)[aDecoder decodeDoubleForKey:@"squareSeparator"];
#if TARGET_OS_IPHONE
    _size = [aDecoder decodeCGSizeForKey:@"size"];
#else
    _size = [aDecoder decodeSizeForKey:@"size"];
#endif
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
#if TARGET_OS_IPHONE
  [aCoder encodeCGPoint:_anchorPoint forKey:@"anchorPoint"];
  [aCoder encodeCGPoint:_gridOffset forKey:@"gridOffset"];
#else
  [aCoder encodePoint:_anchorPoint forKey:@"anchorPoint"];
  [aCoder encodePoint:_gridOffset forKey:@"gridOffset"];
#endif
  [aCoder encodeInteger:(NSInteger)_columnCount forKey:@"columnCount"];
  [aCoder encodeInteger:(NSInteger)_rowCount forKey:@"rowCount"];
#if TARGET_OS_IPHONE
  [aCoder encodeCGSize:_squareSize forKey:@"squareSize"];
  [aCoder encodeCGPoint:_squareAnchorPoint forKey:@"squareAnchorPoint"];
#else
  [aCoder encodeSize:_squareSize forKey:@"squareSize"];
  [aCoder encodePoint:_squareAnchorPoint forKey:@"squareAnchorPoint"];
#endif
  [aCoder encodeInteger:_fillMode forKey:@"fillMode"];
  [aCoder encodeDouble:_gridBorder forKey:@"gridBorder"];
  [aCoder encodeDouble:_squareSeparator forKey:@"squareSeparator"];
#if TARGET_OS_IPHONE
  [aCoder encodeCGSize:_size forKey:@"size"];
#else
  [aCoder encodeSize:_size forKey:@"size"];
#endif
}

- (instancetype)copyWithZone:(NSZone *)zone
{
  HLGridLayoutManager *copy = [[[self class] allocWithZone:zone] init];
  if (copy) {
    copy->_anchorPoint = _anchorPoint;
    copy->_gridOffset = _gridOffset;
    copy->_columnCount = _columnCount;
    copy->_rowCount = _rowCount;
    copy->_squareSize = _squareSize;
    copy->_squareAnchorPoint = _squareAnchorPoint;
    copy->_fillMode = _fillMode;
    copy->_gridBorder = _gridBorder;
    copy->_squareSeparator = _squareSeparator;
    copy->_size = _size;
  }
  return copy;
}

- (void)setColumnCount:(NSUInteger)columnCount
{
  _columnCount = columnCount;
  _rowCount = 0;
}

- (void)setRowCount:(NSUInteger)rowCount
{
  _rowCount = rowCount;
  _columnCount = 0;
}

- (void)layout:(NSArray *)nodes
{
  NSUInteger nodesCount = [nodes count];
  if (nodesCount == 0) {
    _size = CGSizeZero;
    return;
  }
  if (_columnCount == 0 && _rowCount == 0) {
    _size = CGSizeZero;
    return;
  }

  if (_columnCount > 0) {
    _rowCount = (nodesCount - 1) / _columnCount + 1;
  } else {
    _columnCount = (nodesCount - 1) / _rowCount + 1;
  }

  _size = CGSizeMake(_squareSize.width * _columnCount + _squareSeparator * (_columnCount - 1) + _gridBorder * 2.0f,
                     _squareSize.height * _rowCount + _squareSeparator * (_rowCount - 1) + _gridBorder * 2.0f);

  // note: Calculate row and column indexes so that the origin is in the lower left,
  // corresponding to the origin used in the SpriteKit coordinate system.

  CGFloat lowerLeftSquareX = _size.width * -1.0f * _anchorPoint.x
    + _gridBorder + _gridOffset.x
    + _squareSize.width * _squareAnchorPoint.x;
  CGFloat lowerLeftSquareY = _size.height * -1.0f * _anchorPoint.y
    + _gridBorder + _gridOffset.y
    + _squareSize.height * _squareAnchorPoint.y;
  CGFloat squareOffsetX = _squareSize.width + _squareSeparator;
  CGFloat squareOffsetY = _squareSize.height + _squareSeparator;

  switch (_fillMode) {
    case HLGridLayoutManagerFillRightThenDown: {
      NSEnumerator *nodesEnumerator = [nodes objectEnumerator];
      for (int row = (int)_rowCount - 1; row >= 0; --row) {
        for (int column = 0; column < (int)_columnCount; ++column) {
          id node = [nodesEnumerator nextObject];
          if (!node) {
            break;
          }
          if ([node isKindOfClass:[SKNode class]]) {
            [(SKNode *)node setPosition:CGPointMake(lowerLeftSquareX + column * squareOffsetX,
                                                    lowerLeftSquareY + row * squareOffsetY)];
          }
        }
      }
      break;
    }
    case HLGridLayoutManagerFillRightThenUp: {
      NSEnumerator *nodesEnumerator = [nodes objectEnumerator];
      for (int row = 0; row < (int)_rowCount; ++row) {
        for (int column = 0; column < (int)_columnCount; ++column) {
          id node = [nodesEnumerator nextObject];
          if (!node) {
            break;
          }
          if ([node isKindOfClass:[SKNode class]]) {
            [(SKNode *)node setPosition:CGPointMake(lowerLeftSquareX + column * squareOffsetX,
                                                    lowerLeftSquareY + row * squareOffsetY)];
          }
        }
      }
      break;
    }
    case HLGridLayoutManagerFillLeftThenDown: {
      NSEnumerator *nodesEnumerator = [nodes objectEnumerator];
      for (int row = (int)_rowCount - 1; row >= 0; --row) {
        for (int column = (int)_columnCount - 1; column >= 0; --column) {
          id node = [nodesEnumerator nextObject];
          if (!node) {
            break;
          }
          if ([node isKindOfClass:[SKNode class]]) {
            [(SKNode *)node setPosition:CGPointMake(lowerLeftSquareX + column * squareOffsetX,
                                                    lowerLeftSquareY + row * squareOffsetY)];
          }
        }
      }
      break;
    }
    case HLGridLayoutManagerFillLeftThenUp: {
      NSEnumerator *nodesEnumerator = [nodes objectEnumerator];
      for (int row = 0; row < (int)_rowCount; ++row) {
        for (int column = (int)_columnCount - 1; column >= 0; --column) {
          id node = [nodesEnumerator nextObject];
          if (!node) {
            break;
          }
          if ([node isKindOfClass:[SKNode class]]) {
            [(SKNode *)node setPosition:CGPointMake(lowerLeftSquareX + column * squareOffsetX,
                                                    lowerLeftSquareY + row * squareOffsetY)];
          }
        }
      }
      break;
    }
    case HLGridLayoutManagerFillDownThenRight: {
      NSEnumerator *nodesEnumerator = [nodes objectEnumerator];
      for (int column = 0; column < (int)_columnCount; ++column) {
        for (int row = (int)_rowCount - 1; row >= 0; --row) {
          id node = [nodesEnumerator nextObject];
          if (!node) {
            break;
          }
          if ([node isKindOfClass:[SKNode class]]) {
            [(SKNode *)node setPosition:CGPointMake(lowerLeftSquareX + column * squareOffsetX,
                                                    lowerLeftSquareY + row * squareOffsetY)];
          }
        }
      }
      break;
    }
    case HLGridLayoutManagerFillDownThenLeft: {
      NSEnumerator *nodesEnumerator = [nodes objectEnumerator];
      for (int column = (int)_columnCount - 1; column >= 0; --column) {
        for (int row = (int)_rowCount - 1; row >= 0; --row) {
          id node = [nodesEnumerator nextObject];
          if (!node) {
            break;
          }
          if ([node isKindOfClass:[SKNode class]]) {
            [(SKNode *)node setPosition:CGPointMake(lowerLeftSquareX + column * squareOffsetX,
                                                    lowerLeftSquareY + row * squareOffsetY)];
          }
        }
      }
      break;
    }
    case HLGridLayoutManagerFillUpThenRight: {
      NSEnumerator *nodesEnumerator = [nodes objectEnumerator];
      for (int column = 0; column < (int)_columnCount; ++column) {
        for (int row = 0; row < (int)_rowCount; ++row) {
          id node = [nodesEnumerator nextObject];
          if (!node) {
            break;
          }
          if ([node isKindOfClass:[SKNode class]]) {
            [(SKNode *)node setPosition:CGPointMake(lowerLeftSquareX + column * squareOffsetX,
                                                    lowerLeftSquareY + row * squareOffsetY)];
          }
        }
      }
      break;
    }
  case HLGridLayoutManagerFillUpThenLeft: {
      NSEnumerator *nodesEnumerator = [nodes objectEnumerator];
      for (int column = (int)_columnCount - 1; column >= 0; --column) {
        for (int row = 0; row < (int)_rowCount; ++row) {
          id node = [nodesEnumerator nextObject];
          if (!node) {
            break;
          }
          if ([node isKindOfClass:[SKNode class]]) {
            [(SKNode *)node setPosition:CGPointMake(lowerLeftSquareX + column * squareOffsetX,
                                                    lowerLeftSquareY + row * squareOffsetY)];
          }
        }
      }
      break;
    }
  }
}

NSUInteger
HLGridLayoutManagerNodeContainingPoint(CGPoint location)
{
  return 0;
}

@end
