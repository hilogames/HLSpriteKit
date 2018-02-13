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
  }
  return self;
}

- (instancetype)initWithColumnCount:(NSUInteger)columnCount
{
  self = [super init];
  if (self) {
    _anchorPoint = CGPointMake(0.5f, 0.5f);
    _columnCount = columnCount;
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
    _tablePosition = [aDecoder decodeCGPointForKey:@"tablePosition"];
#else
    _anchorPoint = [aDecoder decodePointForKey:@"anchorPoint"];
    _tablePosition = [aDecoder decodePointForKey:@"tablePosition"];
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
    _rowLabelOffsetYs = [aDecoder decodeObjectForKey:@"rowLabelOffsetYs"];
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
  [aCoder encodeCGPoint:_tablePosition forKey:@"tablePosition"];
#else
  [aCoder encodePoint:_anchorPoint forKey:@"anchorPoint"];
  [aCoder encodePoint:_tablePosition forKey:@"tablePosition"];
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
  [aCoder encodeObject:_rowLabelOffsetYs forKey:@"rowLabelOffsetYs"];
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
    copy->_tablePosition = _tablePosition;
    copy->_columnCount = _columnCount;
    copy->_rowCount = _rowCount;
    copy->_constrainedSize = _constrainedSize;
    copy->_columnWidths = [_columnWidths copyWithZone:zone];
    copy->_columnAnchorPoints = [_columnAnchorPoints copyWithZone:zone];
    copy->_rowHeights = [_rowHeights copyWithZone:zone];
    copy->_rowLabelOffsetYs = [_rowLabelOffsetYs copyWithZone:zone];
    copy->_tableBorder = _tableBorder;
    copy->_columnSeparator = _columnSeparator;
    copy->_rowSeparator = _rowSeparator;
    copy->_size = _size;
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
  NSUInteger nodesCount = [nodes count];
  if (nodesCount == 0) {
    return;
  }
  NSUInteger columnCount = _columnCount;
  if (columnCount == 0) {
    columnCount = nodesCount;
  }
  NSUInteger columnWidthsCount = [_columnWidths count];
  NSUInteger columnAnchorPointsCount = [_columnAnchorPoints count];
  NSUInteger rowHeightsCount = [_rowHeights count];
  NSUInteger rowLabelOffsetYsCount = [_rowLabelOffsetYs count];

  _rowCount = (nodesCount - 1) / columnCount + 1;
  // note: Analytically this is always false.  But the check is here for the sake of the
  // static analyzer, which otherwise complains about the malloc below.
  if (_rowCount == 0) {
    return;
  }

  // First pass (columns): Calculate fixed-size column widths, and sum fill-column ratios.
  CGFloat *columnWidths = (CGFloat *)malloc(columnCount * sizeof(CGFloat));
  CGFloat widthTotalFixed = 0.0f;
  CGFloat widthFillColumnRatioSum = 0.0f;
  {
    CGFloat columnWidth = 0.0f;
    for (NSUInteger column = 0; column < columnCount; ++column) {
      if (column < columnWidthsCount) {
        NSNumber *columnWidthNumber = _columnWidths[column];
        columnWidth = (CGFloat)[columnWidthNumber doubleValue];
      }
      if (columnWidth > HLTableLayoutManagerEpsilon) {
        widthTotalFixed += columnWidth;
        columnWidths[column] = columnWidth;
      } else if (columnWidth < -HLTableLayoutManagerEpsilon) {
        widthFillColumnRatioSum += columnWidth;
        columnWidths[column] = columnWidth;
      } else {
        CGFloat cellWidthMax = 0.0f;
        for (NSUInteger row = 0; row < _rowCount; ++row) {
          NSUInteger nodeIndex = row * columnCount + column;
          if (nodeIndex >= nodesCount) {
            break;
          }
          id node = nodes[nodeIndex];
          CGFloat nodeWidth = HLLayoutManagerGetNodeWidth(node);
          if (nodeWidth > cellWidthMax) {
            cellWidthMax = nodeWidth;
          }
        }
        widthTotalFixed += cellWidthMax;
        columnWidths[column] = cellWidthMax;
      }
    }
  }
  CGFloat widthTotalConstant = _columnSeparator * (columnCount - 1) + _tableBorder * 2.0f;
  CGFloat widthTotalFill = 0.0f;
  if (widthFillColumnRatioSum < 0.0 && _constrainedSize.width > (widthTotalFixed + widthTotalConstant)) {
    widthTotalFill = _constrainedSize.width - widthTotalFixed - widthTotalConstant;
  }

  // Second pass (columns): Calculate fill column widths.
  for (NSUInteger column = 0; column < columnCount; ++column) {
    CGFloat columnWidth = columnWidths[column];
    if (columnWidth < -HLTableLayoutManagerEpsilon) {
      columnWidths[column] = widthTotalFill / widthFillColumnRatioSum * columnWidth;
    }
  }

  // First pass (rows): Calculate fixed-size row heights, and sum fill row ratios.
  CGFloat *rowHeights = (CGFloat *)malloc(_rowCount * sizeof(CGFloat));
  CGFloat heightTotalFixed = 0.0f;
  CGFloat heightFillRowRatioSum = 0.0f;
  {
    CGFloat rowHeight = 0.0f;
    for (NSUInteger row = 0; row < _rowCount; ++row) {
      if (row < rowHeightsCount) {
        NSNumber *rowHeightNumber = _rowHeights[row];
        rowHeight = (CGFloat)[rowHeightNumber doubleValue];
      }
      if (rowHeight > HLTableLayoutManagerEpsilon) {
        heightTotalFixed += rowHeight;
        rowHeights[row] = rowHeight;
      } else if (rowHeight < -HLTableLayoutManagerEpsilon) {
        heightFillRowRatioSum += rowHeight;
        rowHeights[row] = rowHeight;
      } else {
        CGFloat cellHeightMax = 0.0f;
        for (NSUInteger column = 0; column < columnCount; ++column) {
          NSUInteger nodeIndex = row * columnCount + column;
          if (nodeIndex >= nodesCount) {
            break;
          }
          id node = nodes[nodeIndex];
          CGFloat nodeHeight = HLLayoutManagerGetNodeHeight(node);
          if (nodeHeight > cellHeightMax) {
            cellHeightMax = nodeHeight;
          }
        }
        heightTotalFixed += cellHeightMax;
        rowHeights[row] = cellHeightMax;
      }
    }
  }
  CGFloat heightTotalConstant = _rowSeparator * (_rowCount - 1) + _tableBorder * 2.0f;
  CGFloat heightTotalFill = 0.0f;
  if (heightFillRowRatioSum < 0.0f && _constrainedSize.height > (heightTotalFixed + heightTotalConstant)) {
    heightTotalFill = _constrainedSize.height - heightTotalFixed - heightTotalConstant;
  }

  // Second pass (rows): Calculate fill row heights.
  for (NSUInteger row = 0; row < _rowCount; ++row) {
    CGFloat rowHeight = rowHeights[row];
    if (rowHeight < -HLTableLayoutManagerEpsilon) {
      rowHeights[row] = heightTotalFill / heightFillRowRatioSum * rowHeight;
    }
  }

  _size = CGSizeMake(widthTotalFixed + widthTotalFill + widthTotalConstant,
                     heightTotalFixed + heightTotalFill + heightTotalConstant);

  if (returnColumnWidths) {
    NSMutableArray *rcw = [NSMutableArray array];
    for (NSUInteger column = 0; column < columnCount; ++column) {
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
  CGFloat cellY = _size.height * (1.0f - _anchorPoint.y) - _tableBorder + _tablePosition.y;
  CGFloat startCellX = _size.width * -1.0f * _anchorPoint.x + _tableBorder + _tablePosition.x;
  CGFloat labelOffsetY = 0.0f;
  id node = nil;
  for (NSUInteger row = 0; row < _rowCount; ++row) {

    CGFloat cellHeight = rowHeights[row];

    if (row < rowLabelOffsetYsCount) {
      NSNumber *labelOffsetYNumber = _rowLabelOffsetYs[row];
      labelOffsetY = (CGFloat)[labelOffsetYNumber doubleValue];
    }

    CGFloat cellX = startCellX;
    CGPoint cellAnchorPoint = CGPointMake(0.5f, 0.5f);
    for (NSUInteger column = 0; column < columnCount; ++column) {

      node = [nodesEnumerator nextObject];
      if (!node) {
        break;
      }

      CGFloat cellWidth = columnWidths[column];

      if (column < columnAnchorPointsCount) {
        NSValue *anchorPointValue = _columnAnchorPoints[column];
#if TARGET_OS_IPHONE
        cellAnchorPoint = [anchorPointValue CGPointValue];
#else
        cellAnchorPoint = [anchorPointValue pointValue];
#endif
      }

      if ([node isKindOfClass:[SKNode class]]) {
        if ([node isKindOfClass:[SKLabelNode class]]) {
          [(SKNode *)node setPosition:CGPointMake(cellX + cellWidth * cellAnchorPoint.x,
                                                  cellY - cellHeight * (1.0f - cellAnchorPoint.y) + labelOffsetY)];
        } else {
          [(SKNode *)node setPosition:CGPointMake(cellX + cellWidth * cellAnchorPoint.x,
                                                  cellY - cellHeight * (1.0f - cellAnchorPoint.y))];
        }
      }

      cellX = cellX + cellWidth + _columnSeparator;
    }

    if (!node) {
      break;
    }
    cellY = cellY - cellHeight - _rowSeparator;
  }

  free(columnWidths);
  free(rowHeights);
}

@end
