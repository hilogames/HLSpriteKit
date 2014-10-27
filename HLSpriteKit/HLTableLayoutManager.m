//
//  HLTableLayoutManager.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 10/27/14.
//  Copyright (c) 2014 Hilo. All rights reserved.
//

#import "HLTableLayoutManager.h"

const CGFloat HLTableLayoutManagerEpsilon = 0.1f;

@implementation HLTableLayoutManager

- (instancetype)init
{
  return [super init];
}

- (instancetype)initWithColumnCount:(NSUInteger)columnCount
                       columnWidths:(NSArray *)columnWidths
                 columnAnchorPoints:(NSArray *)columnAnchorPoints
                         rowHeights:(NSArray *)rowHeights
{
  self = [super init];
  if (self) {
    _anchorPoint = CGPointMake(0.5f, 0.5f);
    _columnCount = columnCount;
    _columnWidths = columnWidths;
    _columnAnchorPoints = columnAnchorPoints;
    _rowHeights = rowHeights;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super init];
  if (self) {
    _anchorPoint = [aDecoder decodeCGPointForKey:@"anchorPoint"];
    _columnCount = (NSUInteger)[aDecoder decodeIntegerForKey:@"columnCount"];
    _rowCount = (NSUInteger)[aDecoder decodeIntegerForKey:@"rowCount"];
    _size = [aDecoder decodeCGSizeForKey:@"size"];
    _constrainedSize = [aDecoder decodeCGSizeForKey:@"constrainedSize"];
    _columnWidths = [aDecoder decodeObjectForKey:@"columnWidths"];
    _columnAnchorPoints = [aDecoder decodeObjectForKey:@"columnAnchorPoints"];
    _rowHeights = [aDecoder decodeObjectForKey:@"rowHeight"];
    _tableBorder = (CGFloat)[aDecoder decodeDoubleForKey:@"tableBorder"];
    _columnSeparator = (CGFloat)[aDecoder decodeDoubleForKey:@"columnSeparator"];
    _rowSeparator = (CGFloat)[aDecoder decodeDoubleForKey:@"rowSeparator"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [aCoder encodeCGPoint:_anchorPoint forKey:@"anchorPoint"];
  [aCoder encodeInteger:(NSInteger)_columnCount forKey:@"columnCount"];
  // noob: rowCount and size could be recalculated, but since they are
  // typically not recalculated after layout, it makes sense to me to encode them.
  [aCoder encodeInteger:(NSInteger)_rowCount forKey:@"rowCount"];
  [aCoder encodeCGSize:_size forKey:@"size"];
  [aCoder encodeCGSize:_constrainedSize forKey:@"constrainedSize"];
  [aCoder encodeObject:_columnWidths forKey:@"columnWidths"];
  [aCoder encodeObject:_columnAnchorPoints forKey:@"columnAnchorPoints"];
  [aCoder encodeObject:_rowHeights forKey:@"rowHeights"];
  [aCoder encodeDouble:_tableBorder forKey:@"tableBorder"];
  [aCoder encodeDouble:_columnSeparator forKey:@"columnSeparator"];
  [aCoder encodeDouble:_rowSeparator forKey:@"rowSeparator"];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
  HLTableLayoutManager *copy = [[[self class] allocWithZone:zone] init];
  if (copy) {
    copy->_anchorPoint = _anchorPoint;
    copy->_columnCount = _columnCount;
    copy->_rowCount = _rowCount;
    copy->_constrainedSize = _constrainedSize;
    copy->_columnWidths = [_columnWidths copyWithZone:zone];
    copy->_columnAnchorPoints = [_columnAnchorPoints copyWithZone:zone];
    copy->_rowHeights = [_rowHeights copyWithZone:zone];
    copy->_tableBorder = _tableBorder;
    copy->_columnSeparator = _columnSeparator;
    copy->_rowSeparator = _rowSeparator;
  }
  return copy;
}

- (void)layout:(NSArray *)nodes
{
  if (_columnCount == 0) {
    return;
  }
  NSUInteger nodesCount = [nodes count];
  if (nodesCount == 0) {
    return;
  }
  if (!_columnWidths || !_rowHeights) {
    return;
  }
  NSUInteger columnWidthsCount = [_columnWidths count];
  NSUInteger columnAnchorPointsCount = [_columnAnchorPoints count];
  NSUInteger rowHeightsCount = [_rowHeights count];
  if (columnWidthsCount == 0 || columnAnchorPointsCount == 0 || rowHeightsCount == 0) {
    return;
  }

  _rowCount = (nodesCount - 1) / _columnCount + 1;

  CGFloat widthTotalFixed = 0.0f;
  NSUInteger widthExpandingColumnCount = 0;
  {
    CGFloat width = 0.0f;
    for (NSNumber *widthNumber in _columnWidths) {
      width = (CGFloat)[widthNumber doubleValue];
      if (width < HLTableLayoutManagerEpsilon) {
        ++widthExpandingColumnCount;
      } else {
        widthTotalFixed += width;
      }
    }
    if (_columnCount > columnWidthsCount) {
      if (width < HLTableLayoutManagerEpsilon) {
        widthExpandingColumnCount += (_columnCount - columnWidthsCount);
      } else {
        widthTotalFixed += width * (_columnCount - columnWidthsCount);
      }
    }
  }
  CGFloat widthTotalConstant = _columnSeparator * (_columnCount - 1) + _tableBorder * 2.0f;
  CGFloat widthTotalExpanding = _constrainedSize.width - widthTotalFixed - widthTotalConstant;
  CGFloat widthColumnExpanding;
  if (widthTotalExpanding <= 0.0f) {
    widthTotalExpanding = 0.0f;
    widthColumnExpanding = 0.0f;
  } else {
    widthColumnExpanding = widthTotalExpanding / widthExpandingColumnCount;
  }

  CGFloat heightTotalFixed = 0.0f;
  NSUInteger heightExpandingRowCount = 0;
  {
    CGFloat height = 0.0f;
    for (NSNumber *heightNumber in _rowHeights) {
      height = (CGFloat)[heightNumber doubleValue];
      if (height < HLTableLayoutManagerEpsilon) {
        ++heightExpandingRowCount;
      } else {
        heightTotalFixed += height;
      }
    }
    if (_rowCount > rowHeightsCount) {
      if (height < HLTableLayoutManagerEpsilon) {
        heightExpandingRowCount += (_rowCount - rowHeightsCount);
      } else {
        heightTotalFixed += height * (_rowCount - rowHeightsCount);
      }
    }
  }
  CGFloat heightTotalConstant = _rowSeparator * (_rowCount - 1) + _tableBorder * 2.0f;
  CGFloat heightTotalExpanding = _constrainedSize.height - heightTotalFixed - heightTotalConstant;
  CGFloat heightRowExpanding;
  if (heightTotalExpanding <= 0.0f) {
    heightTotalExpanding = 0.0f;
    heightRowExpanding = 0.0f;
  } else {
    heightRowExpanding = heightTotalExpanding / heightExpandingRowCount;
  }

  _size = CGSizeMake(widthTotalFixed + widthTotalExpanding + widthTotalConstant,
                     heightTotalFixed + heightTotalExpanding + heightTotalConstant);

  // note: x and y track the upper left corner of each cell.
  NSEnumerator *nodesEnumerator = [nodes objectEnumerator];
  CGFloat yCell = _size.height * (1.0f - _anchorPoint.y) - _tableBorder;
  CGFloat heightCell = 0.0f;
  for (NSUInteger row = 0; row < _rowCount; ++row) {

    if (row < rowHeightsCount) {
      NSNumber *heightNumber = _rowHeights[row];
      heightCell = (CGFloat)[heightNumber doubleValue];
      if (heightCell < HLTableLayoutManagerEpsilon) {
        heightCell = heightRowExpanding;
      }
    }
    
    CGFloat xCell = _size.width * -1.0f * _anchorPoint.x + _tableBorder;
    CGFloat widthCell = 0.0f;
    CGPoint anchorPointCell = CGPointZero;
    for (NSUInteger column = 0; column < _columnCount; ++column) {

      id node = [nodesEnumerator nextObject];
      if (!node) {
        return;
      }

      if (column < columnWidthsCount) {
        NSNumber *widthNumber = _columnWidths[column];
        widthCell = (CGFloat)[widthNumber doubleValue];
        if (widthCell < HLTableLayoutManagerEpsilon) {
          widthCell = widthColumnExpanding;
        }
      }

      if (column < columnAnchorPointsCount) {
        NSValue *anchorPointValue = _columnAnchorPoints[column];
        anchorPointCell = [anchorPointValue CGPointValue];
      }

      if ([node isKindOfClass:[SKNode class]]) {
        [(SKNode *)node setPosition:CGPointMake(xCell + widthCell * anchorPointCell.x,
                                                yCell - heightCell * (1.0f - anchorPointCell.y))];
      }
    
      xCell = xCell + widthCell + _columnSeparator;
    }
    
    yCell = yCell - heightCell - _rowSeparator;
  }
}

@end
