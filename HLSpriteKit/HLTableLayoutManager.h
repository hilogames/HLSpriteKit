//
//  HLTableLayoutManager.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 10/27/14.
//  Copyright (c) 2014 Hilo Games. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

#import "HLLayoutManager.h"

FOUNDATION_EXPORT const CGFloat HLTableLayoutManagerEpsilon;

/**
 * Provides functionality to layout (i.e. set positions of) nodes in a table.
 * This manager may be attached to an SKNode via the SKNode+HLLayoutManager
 * category, using hlSetLayoutManager.
 *
 * note: The number of layout parameters could be greatly reduced if, for example,
 * the owner was required to specify the positions of columns and rows rather than
 * the widths and heights.  (In that case, then no anchor points would need to
 * be specified.)  The whole idea of this layout class, though, is that this
 * particular parameterization captures a common layout concept.
 */
@interface HLTableLayoutManager : NSObject <HLLayoutManager, NSCopying, NSCoding>

/**
 * The anchor point used for the table during layout.  For example, if the
 * anchorPoint is (0.5,0.5), the table will be centered on position CGPointZero.
 * Default value is (0.5,0.5).
 */
@property (nonatomic, assign) CGPoint anchorPoint;

/**
 * The number of columns in the table.  This property, and not columnWidths,
 * determines the number of columns for layout purposes.
 */
@property (nonatomic, assign) NSUInteger columnCount;

/**
 * Returns the number of rows in the table at the last layout; it is derived from
 * the columnCount and the number of children (at the last layout).
 */
@property (nonatomic, readonly) NSUInteger rowCount;

/**
 * Returns the calculated size of the table at the last layout; it is derived from
 * the layout-affecting parameters.
 */
@property (nonatomic, readonly) CGSize size;

/**
 * Specifies the total width and height of the table when it contains expanding
 * columns and rows; see notes on columnWidths and rowHeights properties.  If
 * there are no expanding columns or rows, this size will be ignored.  If the
 * constrained size (in a particular dimension) is not large enough to hold all
 * the non-expanding rows or columns, plus the tableBorder and cell separators,
 * the width or height of the expanding rows will be set to zero, and the total
 * size of the table (see size property) will be larger than the constrained size.
 */
@property (nonatomic, assign) CGSize constrainedSize;

/**
 * An array of CGFloats specifying the widths of table columns.  Columns in the table
 * without corresponding widths in the array will be sized according to the last
 * column width in the array.
 *
 * Special sizes may be specified as followed:
 *
 *  . A size of 0.0f (that is, a value that has a difference from 0.0f less than
 *    HLTableLayoutNodeEpsilon) means the layout manager should attempt to size
 *    the column to fit the largest node in the column.  This is a little messy:
 *    If a node responds to @selector(size), then that size will be used;
 *    otherwise if the node is a kind of SKLabelNode, then frame.size will be
 *    used; otherwise, the node is considered to have zero size.
 *
 *  . A size less than zero (actually, less than -HLTableLayoutEpsilon) will
 *    expand the column to share the available constrained width of the table.
 *    Furthermore, the extra space can be shared unequally: it will be allocated
 *    according to the ratio of the expanding columns' sizes.  For example, say
 *    the constrained width of the table is 100 for three columns.  If the tableBorder
 *    is 1 and the columnSeparator is 2, that leaves 95 for the columns.  The
 *    first column is specified with a fixed size of 35, leaving 60 for the two
 *    remaining columns, which have sizes specified as -1.0 and -2.0, resulting in
 *    actual column sizes of 20 and 40, respectively.
 */
@property (nonatomic, strong) NSArray *columnWidths;

/**
 * An array of CGFloats specifying the heights of table rows.  Rows in the table
 * without corresponding heights in the array will be sized according to the last
 * row height in the array.
 *
 * Special sizes may be specified the same way as columnWidths; see notes there.
 */
@property (nonatomic, strong) NSArray *rowHeights;

/**
 * The anchor points used for cell position calculations during layout; this can
 * be used to set vertical and horizontal justification for cells in each column.
 * (Note: The nodes being laid out may or may not have their own anchorPoint
 * properties; if they do, they will be ignored by this layout manager, though
 * in most cases the corresponding column anchor point should be set to the same
 * value.)  Columns in the table without corresponding anchor points in the array
 * will be anchored according to the last anchor point in the array.
 *
 * An example: Say a table layout manager is laying out rows that contain an
 * icon, a line of text, and a few number values.  The icon is a SKSpriteNode with
 * default anchorPoint (0.5, 0.5).  The line of text is an SKLabelNode with
 * left horizontal alignment and baseline vertical alignment; a good anchor point
 * would be (0.0f, 0.25f) to put the label on the left side of the cell and a bit
 * up from the bottom (to leave room for the font descender below the baseline).
 * The number values are also SKLabelNodes with the same baseline alignment, but
 * with right alignment, and so they should go at anchor point (1.0f, 0.25f).  All
 * together, a good setting for columnAnchorPoints would be:
 *
 *         @[ [NSValue valueWithCGPoint:CGPointMake(0.5f, 0.5f)],
 *            [NSValue valueWithCGPoint:CGPointMake(0.0f, 0.25f)],
 *            [NSValue valueWithCGPoint:CGPointMake(1.0f, 0.25f)] ]
 */
@property (nonatomic, strong) NSArray *columnAnchorPoints;

/**
 * The distance (reserved by layout) between each edge of the table and the nearest
 * cell edge.
 */
@property (nonatomic, assign) CGFloat tableBorder;

/**
 * The distance (reserved by layout) between adjacent columns.
 */
@property (nonatomic, assign) CGFloat columnSeparator;

/**
 * The distance (reserved by layout) between adjacent rows.
 */
@property (nonatomic, assign) CGFloat rowSeparator;

- (instancetype)init NS_DESIGNATED_INITIALIZER;

/**
 * Initializes the object with all parameters necessary for a basic table layout
 * of nodes.
 */
- (instancetype)initWithColumnCount:(NSUInteger)columnCount
                       columnWidths:(NSArray *)columnWidths
                 columnAnchorPoints:(NSArray *)columnAnchorPoints
                         rowHeights:(NSArray *)rowHeights NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;

/**
 * Set the positions of all passed nodes according to the layout-affecting parameters.
 * For layout to have an effect: columnCount must be non-zero, and columnWidths and
 * columnAnchorPoints and rowHeights must have at least one element each.
 *
 * The order of the passed nodes determines position in the table: rows are filled
 * left to right starting with the top row.  A cell is skipped if the corresponding
 * element in the array is not a kind of SKNode class.  (It is suggested to pass
 * [NSNull null] to intentionally leave cells empty.)
 *
 * This method must always be called explicitly to realize layout changes.  On one
 * hand, it's annoying to have to remember to call it; on the other hand, it allows
 * the owner efficiently to make multiple changes (e.g. remove a node, insert another
 * node, change the constrainedSize, etc) and re-layout only exactly once.
 */
- (void)layout:(NSArray *)nodes;

@end
