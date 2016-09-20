//
//  HLTableLayoutManager.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 10/27/14.
//  Copyright (c) 2014 Hilo Games. All rights reserved.
//

#import "HLTableLayoutManager.h"

#import <TargetConditionals.h>

const CGFloat HLTableLayoutManagerEpsilon = 0.001f;

@implementation HLTableLayoutManager

- (instancetype)init
{
  self = [super init];
  if (self) {
    _anchorPoint = CGPointMake(0.5f, 0.5f);
    _tableOffset = CGPointZero;
  }
  return self;
}

- (instancetype)initWithColumnCount:(NSUInteger)columnCount
                       columnWidths:(NSArray *)columnWidths
                 columnAnchorPoints:(NSArray *)columnAnchorPoints
                         rowHeights:(NSArray *)rowHeights
{
  self = [super init];
  if (self) {
    _anchorPoint = CGPointMake(0.5f, 0.5f);
    _tableOffset = CGPointZero;
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
#if TARGET_OS_IPHONE
    _anchorPoint = [aDecoder decodeCGPointForKey:@"anchorPoint"];
    _tableOffset = [aDecoder decodeCGPointForKey:@"tableOffset"];
#else
    _anchorPoint = [aDecoder decodePointForKey:@"anchorPoint"];
    _tableOffset = [aDecoder decodePointForKey:@"tableOffset"];
#endif
    _columnCount = (NSUInteger)[aDecoder decodeIntegerForKey:@"columnCount"];
    _rowCount = (NSUInteger)[aDecoder decodeIntegerForKey:@"rowCount"];
#if TARGET_OS_IPHONE
    _constrainedSize = [aDecoder decodeCGSizeForKey:@"constrainedSize"];
#else
    _constrainedSize = [aDecoder decodeSizeForKey:@"constrainedSize"];
#endif
    _columnWidths = [aDecoder decodeObjectForKey:@"columnWidths"];
    _columnAnchorPoints = [aDecoder decodeObjectForKey:@"columnAnchorPoints"];
    _rowHeights = [aDecoder decodeObjectForKey:@"rowHeight"];
    _tableBorder = (CGFloat)[aDecoder decodeDoubleForKey:@"tableBorder"];
    _columnSeparator = (CGFloat)[aDecoder decodeDoubleForKey:@"columnSeparator"];
    _rowSeparator = (CGFloat)[aDecoder decodeDoubleForKey:@"rowSeparator"];
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
  [aCoder encodeCGPoint:_tableOffset forKey:@"tableOffset"];
#else
  [aCoder encodePoint:_anchorPoint forKey:@"anchorPoint"];
  [aCoder encodePoint:_tableOffset forKey:@"tableOffset"];
#endif
  [aCoder encodeInteger:(NSInteger)_columnCount forKey:@"columnCount"];
  // noob: rowCount and size could be recalculated, but since they are
  // typically not recalculated after layout, it makes sense to me to encode them.
  [aCoder encodeInteger:(NSInteger)_rowCount forKey:@"rowCount"];
#if TARGET_OS_IPHONE
  [aCoder encodeCGSize:_constrainedSize forKey:@"constrainedSize"];
#else
  [aCoder encodeSize:_constrainedSize forKey:@"constrainedSize"];
#endif
  [aCoder encodeObject:_columnWidths forKey:@"columnWidths"];
  [aCoder encodeObject:_columnAnchorPoints forKey:@"columnAnchorPoints"];
  [aCoder encodeObject:_rowHeights forKey:@"rowHeights"];
  [aCoder encodeDouble:_tableBorder forKey:@"tableBorder"];
  [aCoder encodeDouble:_columnSeparator forKey:@"columnSeparator"];
  [aCoder encodeDouble:_rowSeparator forKey:@"rowSeparator"];
#if TARGET_OS_IPHONE
  [aCoder encodeCGSize:_size forKey:@"size"];
#else
  [aCoder encodeSize:_size forKey:@"size"];
#endif
}

- (instancetype)copyWithZone:(NSZone *)zone
{
  HLTableLayoutManager *copy = [[[self class] allocWithZone:zone] init];
  if (copy) {
    copy->_anchorPoint = _anchorPoint;
    copy->_tableOffset = _tableOffset;
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
  [self GL_layout:nodes getColumnWidths:nil rowHeights:nil];
}

- (void)layout:(NSArray *)nodes getColumnWidths:(NSArray *__strong *)columnWidths rowHeights:(NSArray *__strong *)rowHeights
{
  [self GL_layout:nodes getColumnWidths:columnWidths rowHeights:rowHeights];
}

- (void)GL_layout:(NSArray *)nodes getColumnWidths:(NSArray *__strong *)returnColumnWidths rowHeights:(NSArray *__strong *)returnRowHeights
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
  // note: Analytically this is always true.  But the check is here for the sake of the
  // static analyzer, which otherwise complains about the malloc below.
  if (_rowCount == 0) {
    return;
  }

  // First pass (columns): Calculate fixed-size column widths, and sum expanding-column ratios.
  CGFloat *columnWidths = (CGFloat *)malloc(_columnCount * sizeof(CGFloat));
  CGFloat widthTotalFixed = 0.0f;
  CGFloat widthExpandingColumnRatioSum = 0.0f;
  {
    CGFloat widthColumn = 0.0f;
    for (NSUInteger column = 0; column < _columnCount; ++column) {
      if (column < columnWidthsCount) {
        NSNumber *widthColumnNumber = _columnWidths[column];
        widthColumn = (CGFloat)[widthColumnNumber doubleValue];
      }
      if (widthColumn > HLTableLayoutManagerEpsilon) {
        widthTotalFixed += widthColumn;
        columnWidths[column] = widthColumn;
      } else if (widthColumn < -HLTableLayoutManagerEpsilon) {
        widthExpandingColumnRatioSum += widthColumn;
        columnWidths[column] = widthColumn;
      } else {
        CGFloat widthCellMax = 0.0f;
        for (NSUInteger row = 0; row < _rowCount; ++row) {
          NSUInteger nodeIndex = row * _columnCount + column;
          if (nodeIndex >= nodesCount) {
            break;
          }
          id node = nodes[nodeIndex];
          CGFloat nodeWidth = HLLayoutManagerGetNodeWidth(node);
          if (nodeWidth > widthCellMax) {
            widthCellMax = nodeWidth;
          }
        }
        widthTotalFixed += widthCellMax;
        columnWidths[column] = widthCellMax;
      }
    }
  }
  CGFloat widthTotalConstant = _columnSeparator * (_columnCount - 1) + _tableBorder * 2.0f;
  CGFloat widthTotalExpanding = _constrainedSize.width - widthTotalFixed - widthTotalConstant;
  if (widthTotalExpanding <= 0.0f) {
    widthTotalExpanding = 0.0f;
  }

  // Second pass (columns): Calculate expanding column widths.
  for (NSUInteger column = 0; column < _columnCount; ++column) {
    CGFloat widthColumn = columnWidths[column];
    if (widthColumn < -HLTableLayoutManagerEpsilon) {
      columnWidths[column] = widthTotalExpanding / widthExpandingColumnRatioSum * widthColumn;
    }
  }

  // First pass (rows): Calculate fixed-size row heights, and sum expanding row ratios.
  CGFloat *rowHeights = (CGFloat *)malloc(_rowCount * sizeof(CGFloat));
  CGFloat heightTotalFixed = 0.0f;
  CGFloat heightExpandingRowRatioSum = 0.0f;
  {
    CGFloat heightRow = 0.0f;
    for (NSUInteger row = 0; row < _rowCount; ++row) {
      if (row < rowHeightsCount) {
        NSNumber *heightRowNumber = _rowHeights[row];
        heightRow = (CGFloat)[heightRowNumber doubleValue];
      }
      if (heightRow > HLTableLayoutManagerEpsilon) {
        heightTotalFixed += heightRow;
        rowHeights[row] = heightRow;
      } else if (heightRow < -HLTableLayoutManagerEpsilon) {
        heightExpandingRowRatioSum += heightRow;
        rowHeights[row] = heightRow;
      } else {
        CGFloat heightCellMax = 0.0f;
        for (NSUInteger column = 0; column < _columnCount; ++column) {
          NSUInteger nodeIndex = row * _columnCount + column;
          if (nodeIndex >= nodesCount) {
            break;
          }
          id node = nodes[nodeIndex];
          CGFloat nodeHeight = HLLayoutManagerGetNodeHeight(node);
          if (nodeHeight > heightCellMax) {
            heightCellMax = nodeHeight;
          }
        }
        heightTotalFixed += heightCellMax;
        rowHeights[row] = heightCellMax;
      }
    }
  }
  CGFloat heightTotalConstant = _rowSeparator * (_rowCount - 1) + _tableBorder * 2.0f;
  CGFloat heightTotalExpanding = _constrainedSize.height - heightTotalFixed - heightTotalConstant;
  if (heightTotalExpanding <= 0.0f) {
    heightTotalExpanding = 0.0f;
  }

  // Second pass (rows): Calculate expanding row heights.
  for (NSUInteger row = 0; row < _rowCount; ++row) {
    CGFloat heightRow = rowHeights[row];
    if (heightRow < -HLTableLayoutManagerEpsilon) {
      rowHeights[row] = heightTotalExpanding / heightExpandingRowRatioSum * heightRow;
    }
  }

  _size = CGSizeMake(widthTotalFixed + widthTotalExpanding + widthTotalConstant,
                     heightTotalFixed + heightTotalExpanding + heightTotalConstant);

  if (returnColumnWidths) {
    NSMutableArray *rcw = [NSMutableArray array];
    for (NSUInteger column = 0; column < _columnCount; ++column) {
      [rcw addObject:[NSNumber numberWithDouble:columnWidths[column]]];
    }
    *returnColumnWidths = rcw;
  }
  if (returnRowHeights) {
    NSMutableArray *rrh = [NSMutableArray array];
    for (NSUInteger row = 0; row < _rowCount; ++row) {
      [rrh addObject:[NSNumber numberWithDouble:rowHeights[row]]];
    }
    *returnRowHeights = rrh;
  }

  // note: x and y track the upper left corner of each cell.
  NSEnumerator *nodesEnumerator = [nodes objectEnumerator];
  CGFloat yCell = _size.height * (1.0f - _anchorPoint.y) - _tableBorder + _tableOffset.y;
  CGFloat startXCell = _size.width * -1.0f * _anchorPoint.x + _tableBorder + _tableOffset.x;
  id node = nil;
  for (NSUInteger row = 0; row < _rowCount; ++row) {

    CGFloat heightCell = rowHeights[row];
    
    CGFloat xCell = startXCell;
    CGPoint anchorPointCell = CGPointZero;
    for (NSUInteger column = 0; column < _columnCount; ++column) {

      node = [nodesEnumerator nextObject];
      if (!node) {
        break;
      }

      CGFloat widthCell = columnWidths[column];

      if (column < columnAnchorPointsCount) {
        NSValue *anchorPointValue = _columnAnchorPoints[column];
#if TARGET_OS_IPHONE
        anchorPointCell = [anchorPointValue CGPointValue];
#else
        anchorPointCell = [anchorPointValue pointValue];
#endif
      }

      if ([node isKindOfClass:[SKNode class]]) {
        [(SKNode *)node setPosition:CGPointMake(xCell + widthCell * anchorPointCell.x,
                                                yCell - heightCell * (1.0f - anchorPointCell.y))];
      }
    
      xCell = xCell + widthCell + _columnSeparator;
    }
    
    if (!node) {
      break;
    }
    yCell = yCell - heightCell - _rowSeparator;
  }

  free(columnWidths);
  free(rowHeights);
}

@end
