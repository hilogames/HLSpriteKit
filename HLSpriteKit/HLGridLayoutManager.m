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

- (instancetype)initWithSquareSize:(CGSize)squareSize
{
  self = [super init];
  if (self) {
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
    _gridPosition = [aDecoder decodeCGPointForKey:@"gridPosition"];
#else
    _anchorPoint = [aDecoder decodePointForKey:@"anchorPoint"];
    _gridPosition = [aDecoder decodePointForKey:@"gridPosition"];
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
  [aCoder encodeCGPoint:_gridPosition forKey:@"gridPosition"];
#else
  [aCoder encodePoint:_anchorPoint forKey:@"anchorPoint"];
  [aCoder encodePoint:_gridPosition forKey:@"gridPosition"];
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
    copy->_gridPosition = _gridPosition;
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
    + _gridBorder + _gridPosition.x
    + _squareSize.width * _squareAnchorPoint.x;
  CGFloat lowerLeftSquareY = _size.height * -1.0f * _anchorPoint.y
    + _gridBorder + _gridPosition.y
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

- (void)layoutWith2DArray:(NSArray *)nodeArrays
{
  NSUInteger subarraysCount = [nodeArrays count];
  if (subarraysCount == 0) {
    _size = CGSizeZero;
    return;
  }
  NSUInteger maxNodeCount = 0;
  for (NSArray *subarray in nodeArrays) {
    NSUInteger nodeCount = [subarray count];
    if (nodeCount > maxNodeCount) {
      maxNodeCount = nodeCount;
    }
  }
  if (maxNodeCount == 0) {
    _size = CGSizeZero;
    return;
  }

  switch (_fillMode) {
    case HLGridLayoutManagerFillRightThenDown:
      _columnCount = maxNodeCount;
      _rowCount = subarraysCount;
      break;
    case HLGridLayoutManagerFillRightThenUp:
      _columnCount = maxNodeCount;
      _rowCount = subarraysCount;
      break;
    case HLGridLayoutManagerFillLeftThenDown:
      _columnCount = maxNodeCount;
      _rowCount = subarraysCount;
      break;
    case HLGridLayoutManagerFillLeftThenUp:
      _columnCount = maxNodeCount;
      _rowCount = subarraysCount;
      break;
    case HLGridLayoutManagerFillDownThenRight:
      _columnCount = subarraysCount;
      _rowCount = maxNodeCount;
      break;
    case HLGridLayoutManagerFillDownThenLeft:
      _columnCount = subarraysCount;
      _rowCount = maxNodeCount;
      break;
    case HLGridLayoutManagerFillUpThenRight:
      _columnCount = subarraysCount;
      _rowCount = maxNodeCount;
      break;
    case HLGridLayoutManagerFillUpThenLeft:
      _columnCount = subarraysCount;
      _rowCount = maxNodeCount;
      break;
  }

  _size = CGSizeMake(_squareSize.width * _columnCount + _squareSeparator * (_columnCount - 1) + _gridBorder * 2.0f,
                     _squareSize.height * _rowCount + _squareSeparator * (_rowCount - 1) + _gridBorder * 2.0f);

  // note: Calculate row and column indexes so that the origin is in the lower left,
  // corresponding to the origin used in the SpriteKit coordinate system.

  CGFloat lowerLeftSquareX = _size.width * -1.0f * _anchorPoint.x
    + _gridBorder + _gridPosition.x
    + _squareSize.width * _squareAnchorPoint.x;
  CGFloat lowerLeftSquareY = _size.height * -1.0f * _anchorPoint.y
    + _gridBorder + _gridPosition.y
    + _squareSize.height * _squareAnchorPoint.y;
  CGFloat squareOffsetX = _squareSize.width + _squareSeparator;
  CGFloat squareOffsetY = _squareSize.height + _squareSeparator;

  switch (_fillMode) {
    case HLGridLayoutManagerFillRightThenDown: {
      NSEnumerator *subarraysEnumerator = [nodeArrays objectEnumerator];
      for (int row = (int)_rowCount - 1; row >= 0; --row) {
        NSArray *subarray = [subarraysEnumerator nextObject];
        if (!subarray) {
          break;
        }
        NSEnumerator *nodesEnumerator = [subarray objectEnumerator];
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
      NSEnumerator *subarraysEnumerator = [nodeArrays objectEnumerator];
      for (int row = 0; row < (int)_rowCount; ++row) {
        NSArray *subarray = [subarraysEnumerator nextObject];
        if (!subarray) {
          break;
        }
        NSEnumerator *nodesEnumerator = [subarray objectEnumerator];
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
      NSEnumerator *subarraysEnumerator = [nodeArrays objectEnumerator];
      for (int row = (int)_rowCount - 1; row >= 0; --row) {
        NSArray *subarray = [subarraysEnumerator nextObject];
        if (!subarray) {
          break;
        }
        NSEnumerator *nodesEnumerator = [subarray objectEnumerator];
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
      NSEnumerator *subarraysEnumerator = [nodeArrays objectEnumerator];
      for (int row = 0; row < (int)_rowCount; ++row) {
        NSArray *subarray = [subarraysEnumerator nextObject];
        if (!subarray) {
          break;
        }
        NSEnumerator *nodesEnumerator = [subarray objectEnumerator];
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
      NSEnumerator *subarraysEnumerator = [nodeArrays objectEnumerator];
      for (int column = 0; column < (int)_columnCount; ++column) {
        NSArray *subarray = [subarraysEnumerator nextObject];
        if (!subarray) {
          break;
        }
        NSEnumerator *nodesEnumerator = [subarray objectEnumerator];
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
      NSEnumerator *subarraysEnumerator = [nodeArrays objectEnumerator];
      for (int column = (int)_columnCount - 1; column >= 0; --column) {
        NSArray *subarray = [subarraysEnumerator nextObject];
        if (!subarray) {
          break;
        }
        NSEnumerator *nodesEnumerator = [subarray objectEnumerator];
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
      NSEnumerator *subarraysEnumerator = [nodeArrays objectEnumerator];
      for (int column = 0; column < (int)_columnCount; ++column) {
        NSArray *subarray = [subarraysEnumerator nextObject];
        if (!subarray) {
          break;
        }
        NSEnumerator *nodesEnumerator = [subarray objectEnumerator];
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
      NSEnumerator *subarraysEnumerator = [nodeArrays objectEnumerator];
      for (int column = (int)_columnCount - 1; column >= 0; --column) {
        NSArray *subarray = [subarraysEnumerator nextObject];
        if (!subarray) {
          break;
        }
        NSEnumerator *nodesEnumerator = [subarray objectEnumerator];
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

- (NSUInteger)nodeContainingPoint:(CGPoint)location
{
  // note: Row and column indexes have origin in lower left.
  int row;
  int column;
  if (![self HL_getRowAndColumnForLocation:location row:&row column:&column]) {
    return NSNotFound;
  }

  switch (_fillMode) {
    case HLGridLayoutManagerFillRightThenDown:
      return (_rowCount - 1 - row) * _columnCount + column;
    case HLGridLayoutManagerFillRightThenUp:
      return row * _columnCount + column;
    case HLGridLayoutManagerFillLeftThenDown:
      return (_rowCount - 1 - row) * _columnCount + (_columnCount - 1 - column);
    case HLGridLayoutManagerFillLeftThenUp:
      return row * _columnCount + (_columnCount - 1 - column);
    case HLGridLayoutManagerFillDownThenRight:
      return column * _rowCount + (_rowCount - 1 - row);
    case HLGridLayoutManagerFillDownThenLeft:
      return (_columnCount - 1 - column) * _rowCount + (_rowCount - 1 - row);
    case HLGridLayoutManagerFillUpThenRight:
      return column * _rowCount + row;
    case HLGridLayoutManagerFillUpThenLeft:
      return (_columnCount - 1 - column) * _rowCount + row;
  }

  return NSNotFound;
}

- (BOOL)nodeContainingPoint:(CGPoint)location
               primaryIndex:(NSUInteger *)primaryIndex
             secondaryIndex:(NSUInteger *)secondaryIndex
{
  *primaryIndex = NSNotFound;
  *secondaryIndex = NSNotFound;

  // note: Row and column indexes have origin in lower left.
  int row;
  int column;
  if (![self HL_getRowAndColumnForLocation:location row:&row column:&column]) {
    return NO;
  }

  switch (_fillMode) {
    case HLGridLayoutManagerFillRightThenDown:
      *primaryIndex = (_rowCount - 1 - row);
      *secondaryIndex = column;
      break;
    case HLGridLayoutManagerFillRightThenUp:
      *primaryIndex = row;
      *secondaryIndex = column;
      break;
    case HLGridLayoutManagerFillLeftThenDown:
      *primaryIndex = (_rowCount - 1 - row);
      *secondaryIndex = (_columnCount - 1 - column);
      break;
    case HLGridLayoutManagerFillLeftThenUp:
      *primaryIndex = row;
      *secondaryIndex = (_columnCount - 1 - column);
      break;
    case HLGridLayoutManagerFillDownThenRight:
      *primaryIndex = column;
      *secondaryIndex = (_rowCount - 1 - row);
      break;
    case HLGridLayoutManagerFillDownThenLeft:
      *primaryIndex = (_columnCount - 1 - column);
      *secondaryIndex = (_rowCount - 1 - row);
      break;
    case HLGridLayoutManagerFillUpThenRight:
      *primaryIndex = column;
      *secondaryIndex = row;
      break;
    case HLGridLayoutManagerFillUpThenLeft:
      *primaryIndex = (_columnCount - 1 - column);
      *secondaryIndex = row;
      break;
  }

  return YES;
}

- (BOOL)HL_getRowAndColumnForLocation:(CGPoint)location row:(int *)row column:(int *)column
{
  // note: Calculate row and column indexes so that the origin is in the lower left,
  // corresponding to the origin used in the SpriteKit coordinate system.

  CGFloat lowerLeftSquareLeftX = _size.width * -1.0f * _anchorPoint.x + _gridBorder + _gridPosition.x;
  CGFloat lowerLeftSquareBottomY = _size.height * -1.0f * _anchorPoint.y + _gridBorder + _gridPosition.y;
  CGFloat squareOffsetX = _squareSize.width + _squareSeparator;
  CGFloat squareOffsetY = _squareSize.height + _squareSeparator;

  CGFloat lowerLeftSquareLocationX = location.x - lowerLeftSquareLeftX;

  int c = (int)floor(lowerLeftSquareLocationX / squareOffsetX);
  if (c < 0 || c >= _columnCount) {
    return NO;
  }
  if (lowerLeftSquareLocationX - c * squareOffsetX > _squareSize.width) {
    return NO;
  }
  CGFloat lowerLeftSquareLocationY = location.y - lowerLeftSquareBottomY;

  int r = (int)floor(lowerLeftSquareLocationY / squareOffsetY);
  if (r < 0 || r >= _rowCount) {
    return NO;
  }
  if (lowerLeftSquareLocationY - r * squareOffsetY > _squareSize.height) {
    return NO;
  }

  *column = c;
  *row = r;
  return YES;
}

@end
