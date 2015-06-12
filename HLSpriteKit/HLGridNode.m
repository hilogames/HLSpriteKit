//
//  HLGridNode.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 7/14/14.
//  Copyright (c) 2014 Hilo Games. All rights reserved.
//

#import "HLGridNode.h"

#import "HLItemNode.h"
#import "HLItemsNode.h"

enum {
  HLGridNodeZPositionLayerBackground = 0,
  HLGridNodeZPositionLayerSquares,
  HLGridNodeZPositionLayerCount
};

@implementation HLGridNode
{
  SKSpriteNode *_backgroundNode;
  HLItemsNode *_squaresNode;

  // Primary layout-affecting parameters.
  //
  // note: Currently only set at init time to avoid problems with multiple layout (if they
  // are set individually).
  int _gridWidth;
  int _squareCount;
  HLGridNodeLayoutMode _layoutMode;
  CGSize _squareSize;
  CGFloat _backgroundBorderSize;
  CGFloat _squareSeparatorSize;
}

- (instancetype)init
{
  return [self initWithGridWidth:3
                     squareCount:9
                     anchorPoint:CGPointMake(0.5f, 0.5f)
                      layoutMode:HLGridNodeLayoutModeAlignLeft
                      squareSize:CGSizeMake(10.0f, 10.0f)
            backgroundBorderSize:3.0f
             squareSeparatorSize:1.0f];
}

- (instancetype)initWithGridWidth:(int)gridWidth
                      squareCount:(int)squareCount
                      anchorPoint:(CGPoint)anchorPoint
                       layoutMode:(HLGridNodeLayoutMode)layoutMode
                       squareSize:(CGSize)squareSize
             backgroundBorderSize:(CGFloat)backgroundBorderSize
              squareSeparatorSize:(CGFloat)squareSeparatorSize
{
  self = [super init];
  if (self) {

    _gridWidth = gridWidth;
    _squareCount = squareCount;
    _layoutMode = layoutMode;
    _squareSize = squareSize;
    _backgroundBorderSize = backgroundBorderSize;
    _squareSeparatorSize = squareSeparatorSize;

    _backgroundNode = [SKSpriteNode spriteNodeWithColor:[SKColor colorWithWhite:0.0f alpha:0.5f] size:CGSizeZero];
    _backgroundNode.anchorPoint = anchorPoint;
    [self addChild:_backgroundNode];

    _squareColor = [SKColor colorWithWhite:1.0f alpha:0.3f];
    _highlightColor = [SKColor colorWithWhite:1.0f alpha:0.6f];
    _enabledAlpha = 1.0f;
    _disabledAlpha = 0.4f;

    HLBackdropItemNode *itemPrototypeNode = [[HLBackdropItemNode alloc] initWithSize:_squareSize];
    itemPrototypeNode.normalColor = _squareColor;
    itemPrototypeNode.highlightColor = _highlightColor;
    itemPrototypeNode.enabledAlpha = _enabledAlpha;
    itemPrototypeNode.disabledAlpha = _disabledAlpha;
    _squaresNode = [[HLItemsNode alloc] initWithItemCount:squareCount itemPrototype:itemPrototypeNode];
    [self addChild:_squaresNode];

    [self HL_layoutXY];
    [self HL_layoutZ];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  [NSException raise:@"HLCodingNotImplemented" format:@"Coding not implemented for this descendant of an NSCoding parent."];
  // note: Call [init] for the sake of the compiler trying to detect problems with designated initializers.
  return [self init];
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [NSException raise:@"HLCodingNotImplemented" format:@"Coding not implemented for this descendant of an NSCoding parent."];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
  [NSException raise:@"HLCopyingNotImplemented" format:@"Copying not implemented for this descendant of an NSCopying parent."];
  return nil;
}

#pragma mark -
#pragma mark Configuring Layout and Geometry

- (CGSize)size
{
  return _backgroundNode.size;
}

- (int)gridWidth
{
  return _gridWidth;
}

- (int)gridHeight
{
  return (_squareCount - 1) / _gridWidth + 1;
}

- (void)setZPositionScale:(CGFloat)zPositionScale
{
  [super setZPositionScale:zPositionScale];
  [self HL_layoutZ];
}

#pragma mark -
#pragma mark Getting and Setting Content

- (void)setContent:(NSArray *)contentNodes
{
  [_squaresNode setContent:contentNodes];
}

- (void)setContent:(SKNode *)contentNode forSquare:(int)squareIndex
{
  if (squareIndex < 0 || squareIndex >= _squareCount) {
    [NSException raise:@"HLGridNodeInvalidIndex" format:@"Square index %d out of range.", squareIndex];
  }
  NSArray *squareNodes = _squaresNode.itemNodes;
  HLBackdropItemNode *squareNode = squareNodes[(NSUInteger)squareIndex];
  squareNode.content = contentNode;
}

- (SKNode *)contentForSquare:(int)squareIndex
{
  if (squareIndex < 0 || squareIndex >= _squareCount) {
    [NSException raise:@"HLGridNodeInvalidIndex" format:@"Square index %d out of range.", squareIndex];
  }
  NSArray *squareNodes = _squaresNode.itemNodes;
  HLBackdropItemNode *squareNode = squareNodes[(NSUInteger)squareIndex];
  return squareNode.content;
}

- (SKNode *)squareNodeForSquare:(int)squareIndex
{
  if (squareIndex < 0 || squareIndex >= _squareCount) {
    [NSException raise:@"HLGridNodeInvalidIndex" format:@"Square index %d out of range.", squareIndex];
  }
  NSArray *squareNodes = _squaresNode.itemNodes;
  HLBackdropItemNode *squareNode = squareNodes[(NSUInteger)squareIndex];
  return squareNode;
}

- (int)squareAtPoint:(CGPoint)location
{
  CGPoint anchorPoint = _backgroundNode.anchorPoint;
  CGSize size = _backgroundNode.size;

  CGFloat firstSquareBottom = -anchorPoint.y * size.height + _backgroundBorderSize;
  if (location.y < firstSquareBottom) {
    return -1;
  }
  CGFloat gridY = location.y - firstSquareBottom;
  CGFloat squareY = (CGFloat)fmod(gridY, _squareSize.height + _squareSeparatorSize);
  if (squareY > _squareSize.height) {
    return -1;
  }
  int gridHeight = (_squareCount - 1) / _gridWidth + 1;
  int row = gridHeight - 1 - (int)(gridY / (_squareSize.height + _squareSeparatorSize));
  if (row >= gridHeight) {
    return -1;
  }

  CGFloat firstSquareLeft = -anchorPoint.x * size.width + _backgroundBorderSize;
  if (location.x < firstSquareLeft) {
    return -1;
  }
  CGFloat gridX = location.x - firstSquareLeft;
  int column;
  CGFloat squareWidthInRow;
  int squaresInRow;
  if (row + 1 < gridHeight) {
    squaresInRow = _gridWidth;
    squareWidthInRow = _squareSize.width;
  } else if (_layoutMode == HLGridNodeLayoutModeFill) {
    squaresInRow = ((_squareCount - 1) % _gridWidth) + 1;
    squareWidthInRow = (size.width - 2.0f * _backgroundBorderSize - (squaresInRow - 1) * _squareSeparatorSize) / squaresInRow;
  } else {
    squaresInRow = _gridWidth;
    squareWidthInRow = _squareSize.width;
  }
  CGFloat squareX = (CGFloat)fmod(gridX, squareWidthInRow + _squareSeparatorSize);
  if (squareX > squareWidthInRow) {
    return -1;
  }
  column = (int)(gridX / (squareWidthInRow + _squareSeparatorSize));
  if (column >= squaresInRow) {
    return -1;
  }

  return row * _gridWidth + column;
}

#pragma mark -
#pragma mark Configuring Appearance

- (void)setBackgroundColor:(SKColor *)backgroundColor
{
  _backgroundNode.color = backgroundColor;
}

- (SKColor *)backgroundColor
{
  return _backgroundNode.color;
}

- (void)setSquareColor:(SKColor *)squareColor
{
  _squareColor = squareColor;
  NSArray *squareNodes = _squaresNode.itemNodes;
  for (HLBackdropItemNode *squareNode in squareNodes) {
    squareNode.normalColor = _squareColor;
  }
}

- (void)setHighlightColor:(SKColor *)highlightColor
{
  _highlightColor = highlightColor;
  NSArray *squareNodes = _squaresNode.itemNodes;
  for (HLBackdropItemNode *squareNode in squareNodes) {
    squareNode.highlightColor = _highlightColor;
  }
}

- (void)setEnabledAlpha:(CGFloat)enabledAlpha
{
  _enabledAlpha = enabledAlpha;
  NSArray *squareNodes = _squaresNode.itemNodes;
  for (HLBackdropItemNode *squareNode in squareNodes) {
    squareNode.enabledAlpha = _enabledAlpha;
  }
}

- (void)setDisabledAlpha:(CGFloat)disabledAlpha
{
  _disabledAlpha = disabledAlpha;
  NSArray *squareNodes = _squaresNode.itemNodes;
  for (HLBackdropItemNode *squareNode in squareNodes) {
    squareNode.disabledAlpha = _disabledAlpha;
  }
}

#pragma mark -
#pragma mark Managing Grid Square State

- (BOOL)enabledForSquare:(int)squareIndex
{
  if (squareIndex < 0 || squareIndex >= _squareCount) {
    [NSException raise:@"HLGridNodeInvalidIndex" format:@"Square index %d out of range.", squareIndex];
  }
  return ((HLBackdropItemNode *)_squaresNode.itemNodes[squareIndex]).enabled;
}

- (void)setEnabled:(BOOL)enabled forSquare:(int)squareIndex
{
  if (squareIndex < 0 || squareIndex >= _squareCount) {
    [NSException raise:@"HLGridNodeInvalidIndex" format:@"Square index %d out of range.", squareIndex];
  }
  ((HLBackdropItemNode *)_squaresNode.itemNodes[squareIndex]).enabled = enabled;
}

- (BOOL)highlightForSquare:(int)squareIndex
{
  if (squareIndex < 0 || squareIndex >= _squareCount) {
    [NSException raise:@"HLGridNodeInvalidIndex" format:@"Square index %d out of range.", squareIndex];
  }
  return ((HLBackdropItemNode *)_squaresNode.itemNodes[squareIndex]).highlight;
}

- (void)setHighlight:(BOOL)highlight forSquare:(int)squareIndex
{
  if (squareIndex < 0 || squareIndex >= _squareCount) {
    [NSException raise:@"HLGridNodeInvalidIndex" format:@"Square index %d out of range.", squareIndex];
  }
  ((HLBackdropItemNode *)_squaresNode.itemNodes[squareIndex]).highlight = highlight;
}

- (void)setHighlight:(BOOL)finalHighlight
           forSquare:(int)squareIndex
          blinkCount:(int)blinkCount
   halfCycleDuration:(NSTimeInterval)halfCycleDuration
          completion:(void(^)(void))completion
{
  if (squareIndex < 0 || squareIndex >= _squareCount) {
    [NSException raise:@"HLGridNodeInvalidIndex" format:@"Square index %d out of range.", squareIndex];
  }
  [(HLBackdropItemNode *)_squaresNode.itemNodes[squareIndex] setHighlight:finalHighlight
                                                               blinkCount:blinkCount
                                                        halfCycleDuration:halfCycleDuration
                                                               completion:completion];
}

- (int)selectionSquare
{
  return _squaresNode.selectionItem;
}

- (void)setSelectionForSquare:(int)squareIndex
{
  [_squaresNode setSelectionForItem:squareIndex];
}

- (void)setSelectionForSquare:(int)squareIndex
                   blinkCount:(int)blinkCount
            halfCycleDuration:(NSTimeInterval)halfCycleDuration
                   completion:(void (^)(void))completion
{
  [_squaresNode setSelectionForItem:squareIndex
                         blinkCount:blinkCount
                  halfCycleDuration:halfCycleDuration
                         completion:completion];
}

- (void)clearSelection
{
  [_squaresNode clearSelection];
}

- (void)clearSelectionBlinkCount:(int)blinkCount
               halfCycleDuration:(NSTimeInterval)halfCycleDuration
                      completion:(void (^)(void))completion
{
  [_squaresNode clearSelectionBlinkCount:blinkCount
                       halfCycleDuration:halfCycleDuration
                              completion:completion];
}

#pragma mark -
#pragma mark HLGestureTarget

- (NSArray *)addsToGestureRecognizers
{
  return @[ [[UITapGestureRecognizer alloc] init] ];
}

- (BOOL)addToGesture:(UIGestureRecognizer *)gestureRecognizer firstTouch:(UITouch *)touch isInside:(BOOL *)isInside
{
  *isInside = YES;
  if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
    // note: Require only one tap and one touch, same as our gesture recognizer returned
    // from addsToGestureRecognizers?  I think it's okay to be non-strict.
    [gestureRecognizer addTarget:self action:@selector(handleTap:)];
    return YES;
  }
  return NO;
}

- (void)handleTap:(UIGestureRecognizer *)gestureRecognizer
{
  CGPoint viewLocation = [gestureRecognizer locationInView:self.scene.view];
  CGPoint sceneLocation = [self.scene convertPointFromView:viewLocation];
  CGPoint location = [self convertPoint:sceneLocation fromNode:self.scene];

  int squareIndex = [self squareAtPoint:location];
  if (squareIndex < 0) {
    return;
  }

  if (_squareTappedBlock) {
    _squareTappedBlock(squareIndex);
  }

  id <HLGridNodeDelegate> delegate = _delegate;
  if (delegate) {
    [delegate gridNode:self didTapSquare:squareIndex];
  }
}

#pragma mark -
#pragma mark Private

- (void)HL_layoutXY
{
  CGPoint anchorPoint = _backgroundNode.anchorPoint;

  int gridHeight = (_squareCount - 1) / _gridWidth + 1;
  CGSize squaresArea = CGSizeMake(_gridWidth * _squareSize.width + (_gridWidth - 1) * _squareSeparatorSize,
                                  gridHeight * _squareSize.height + (gridHeight - 1) * _squareSeparatorSize);
  CGSize size = CGSizeMake(squaresArea.width + 2.0f * _backgroundBorderSize,
                           squaresArea.height + 2.0f * _backgroundBorderSize);
  CGPoint upperLeftPoint = CGPointMake(-anchorPoint.x * size.width + _backgroundBorderSize,
                                       (1.0f - anchorPoint.y) * size.height - _backgroundBorderSize);

  // Arrange square nodes in grid.
  NSArray *squareNodes = _squaresNode.itemNodes;
  for (int y = 0; y < gridHeight; ++y) {

    int squaresInRow;
    CGSize squareSizeInRow;
    if (y + 1 < gridHeight) {
      squaresInRow = _gridWidth;
      squareSizeInRow = _squareSize;
    } else {
      squaresInRow = (_squareCount - 1) % _gridWidth + 1;
      squareSizeInRow = _squareSize;
      if (_layoutMode == HLGridNodeLayoutModeFill) {
        squareSizeInRow.width = (squaresArea.width - (squaresInRow - 1) * _squareSeparatorSize) / squaresInRow;
      }
    }

    for (int x = 0; x < squaresInRow; ++x) {
      HLBackdropItemNode *squareNode = squareNodes[y * _gridWidth + x];
      squareNode.position = CGPointMake(upperLeftPoint.x + squareSizeInRow.width / 2.0f + x * (squareSizeInRow.width + _squareSeparatorSize),
                                        upperLeftPoint.y - squareSizeInRow.height / 2.0f - y * (squareSizeInRow.height + _squareSeparatorSize));
      squareNode.size = squareSizeInRow;
    }
  }

  _backgroundNode.size = size;
}

- (void)HL_layoutZ
{
  CGFloat zPositionLayerIncrement = self.zPositionScale / HLGridNodeZPositionLayerCount;
  _backgroundNode.zPosition = HLGridNodeZPositionLayerBackground * zPositionLayerIncrement;
  _squaresNode.zPosition = HLGridNodeZPositionLayerSquares * zPositionLayerIncrement;
  _squaresNode.zPositionScale = zPositionLayerIncrement;
}

@end
