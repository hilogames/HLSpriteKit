//
//  HLGridNode.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 7/14/14.
//  Copyright (c) 2014 Hilo Games. All rights reserved.
//

#import "HLGridNode.h"

typedef struct {
  BOOL enabled;
  BOOL highlight;
} HLGridNodeSquareState;

enum {
  HLGridNodeZPositionLayerBackground = 0,
  HLGridNodeZPositionLayerSquares,
  HLGridNodeZPositionLayerContent,
  HLGridNodeZPositionLayerCount
};

@implementation HLGridNode
{
  SKSpriteNode *_gridNode;
  HLGridNodeSquareState *_squareState;
  int _selectionSquareIndex;

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

    _gridNode = [SKSpriteNode spriteNodeWithColor:[SKColor colorWithWhite:0.0f alpha:0.5f] size:CGSizeZero];
    _gridNode.anchorPoint = anchorPoint;
    [self addChild:_gridNode];

    [self HL_allocateSquareState];
    _selectionSquareIndex = -1;

    _squareColor = [SKColor colorWithWhite:1.0f alpha:0.3f];
    _highlightColor = [SKColor colorWithWhite:1.0f alpha:0.6f];
    _enabledAlpha = 1.0f;
    _disabledAlpha = 0.4f;

    [self HL_layoutGrid];
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

- (void)dealloc
{
  [self HL_freeSquareState];
}

- (CGSize)size
{
  return _gridNode.size;
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
  CGFloat zPositionLayerIncrement = zPositionScale / HLGridNodeZPositionLayerCount;
  CGFloat squareNodeZPosition = HLGridNodeZPositionLayerSquares * zPositionLayerIncrement;
  CGFloat contentNodeZPosition = (HLGridNodeZPositionLayerContent - HLGridNodeZPositionLayerSquares) * zPositionLayerIncrement;
  NSArray *squareNodes = _gridNode.children;
  for (SKSpriteNode *squareNode in squareNodes) {
    squareNode.zPosition = squareNodeZPosition;
    NSArray *squareNodeChildren = squareNode.children;
    if ([squareNodeChildren count] > 0) {
      ((SKNode *)(squareNodeChildren.firstObject)).zPosition = contentNodeZPosition;
    }
  }
}

- (void)setContent:(NSArray *)contentNodes
{
  NSArray *squareNodes = _gridNode.children;
  for (SKSpriteNode *squareNode in squareNodes) {
    [squareNode removeAllChildren];
  }

  NSUInteger contentCount = [contentNodes count];
  NSUInteger i = 0;
  CGFloat zPositionLayerIncrement = self.zPositionScale / HLGridNodeZPositionLayerCount;
  CGFloat contentNodeZPosition = (HLGridNodeZPositionLayerSquares - HLGridNodeZPositionLayerContent) * zPositionLayerIncrement;
  while (i < contentCount && i < (NSUInteger)_squareCount) {
    if (contentNodes[i] != [NSNull null]) {
      SKNode *contentNode = (SKNode *)contentNodes[i];
      SKSpriteNode *squareNode = (SKSpriteNode *)squareNodes[i];
      contentNode.zPosition = contentNodeZPosition;
      [squareNode addChild:contentNode];
      ++i;
    }
  }
}

- (void)setContent:(SKNode *)contentNode forSquare:(int)squareIndex
{
  if (squareIndex < 0 || squareIndex >= _squareCount) {
    [NSException raise:@"HLGridNodeInvalidIndex" format:@"Square index %d out of range.", squareIndex];
  }
  NSArray *squareNodes = _gridNode.children;
  SKSpriteNode *squareNode = squareNodes[(NSUInteger)squareIndex];
  [squareNode removeAllChildren];
  if (contentNode) {
    contentNode.zPosition = (HLGridNodeZPositionLayerSquares - HLGridNodeZPositionLayerContent) * self.zPositionScale / HLGridNodeZPositionLayerCount;
    [squareNode addChild:contentNode];
  }
}

- (SKNode *)contentForSquare:(int)squareIndex
{
  if (squareIndex < 0 || squareIndex >= _squareCount) {
    [NSException raise:@"HLGridNodeInvalidIndex" format:@"Square index %d out of range.", squareIndex];
  }
  NSArray *squareNodes = _gridNode.children;
  SKSpriteNode *squareNode = squareNodes[(NSUInteger)squareIndex];
  NSArray *squareNodeChildren = squareNode.children;
  if ([squareNodeChildren count] == 0) {
    return nil;
  }
  return (SKNode *)(squareNodeChildren.firstObject);
}

- (SKSpriteNode *)squareNodeForSquare:(int)squareIndex
{
  if (squareIndex < 0 || squareIndex >= _squareCount) {
    [NSException raise:@"HLGridNodeInvalidIndex" format:@"Square index %d out of range.", squareIndex];
  }
  NSArray *squareNodes = _gridNode.children;
  return squareNodes[(NSUInteger)squareIndex];
}

- (int)squareAtLocation:(CGPoint)location
{
  CGPoint lowerLeftPoint = CGPointMake(-_gridNode.anchorPoint.x * _gridNode.size.width,
                                       -_gridNode.anchorPoint.y * _gridNode.size.height);
  int gridHeight = (_squareCount - 1) / _gridWidth + 1;
  int y = gridHeight - 1 - (int)((location.y - lowerLeftPoint.y + _squareSeparatorSize) / (_squareSize.height + _squareSeparatorSize));
  int x;

  if (y + 1 < gridHeight) {
    x = (int)((location.x - lowerLeftPoint.x + _squareSeparatorSize) / (_squareSize.width + _squareSeparatorSize));
  } else {
    int squaresInRow = (_squareCount - 1) % _gridWidth + 1;
    CGFloat squareWidthInRow;
    if (_layoutMode == HLGridNodeLayoutModeFill) {
      squareWidthInRow = (_gridNode.size.width - 2.0f * _backgroundBorderSize - (squaresInRow - 1) * _squareSeparatorSize) / squaresInRow;
    } else {
      squareWidthInRow = _squareSize.width;
    }

    x = (int)((location.x - lowerLeftPoint.x + _squareSeparatorSize) / (squareWidthInRow + _squareSeparatorSize));
    if (_layoutMode == HLGridNodeLayoutModeAlignLeft && x >= squaresInRow) {
      return -1;
    }
  }

  return y * _gridWidth + x;
}

- (void)setBackgroundColor:(SKColor *)backgroundColor
{
  _gridNode.color = backgroundColor;
}

- (SKColor *)backgroundColor
{
  return _gridNode.color;
}

- (void)setEnabledAlpha:(CGFloat)enabledAlpha
{
  _enabledAlpha = enabledAlpha;
  NSArray *squareNodes = _gridNode.children;
  int s = 0;
  for (SKSpriteNode *squareNode in squareNodes) {
    if (_squareState[s].enabled) {
      squareNode.alpha = enabledAlpha;
    }
    ++s;
  }
}

- (void)setDisabledAlpha:(CGFloat)disabledAlpha
{
  _disabledAlpha = disabledAlpha;
  NSArray *squareNodes = _gridNode.children;
  int s = 0;
  for (SKSpriteNode *squareNode in squareNodes) {
    if (!_squareState[s].enabled) {
      squareNode.alpha = disabledAlpha;
    }
    ++s;
  }
}

- (void)setSquareColor:(SKColor *)squareColor
{
  _squareColor = squareColor;
  NSArray *squareNodes = _gridNode.children;
  int s = 0;
  for (SKSpriteNode *squareNode in squareNodes) {
    if (!_squareState[s].highlight) {
      squareNode.color = squareColor;
    }
    ++s;
  }
}

- (void)setHighlightColor:(SKColor *)highlightColor
{
  _highlightColor = highlightColor;
  NSArray *squareNodes = _gridNode.children;
  int s = 0;
  for (SKSpriteNode *squareNode in squareNodes) {
    if (_squareState[s].highlight) {
      squareNode.color = highlightColor;
    }
    ++s;
  }
}

- (BOOL)enabledForSquare:(int)squareIndex
{
  if (squareIndex < 0 || squareIndex >= _squareCount) {
    [NSException raise:@"HLGridNodeInvalidIndex" format:@"Square index %d out of range.", squareIndex];
  }
  return _squareState[squareIndex].enabled;
}

- (void)setEnabled:(BOOL)enabled forSquare:(int)squareIndex
{
  if (squareIndex < 0 || squareIndex >= _squareCount) {
    [NSException raise:@"HLGridNodeInvalidIndex" format:@"Square index %d out of range.", squareIndex];
  }
  NSArray *squareNodes = _gridNode.children;
  SKSpriteNode *squareNode = squareNodes[(NSUInteger)squareIndex];

  _squareState[squareIndex].enabled = enabled;
  if (enabled) {
    squareNode.alpha = _enabledAlpha;
  } else {
    squareNode.alpha = _disabledAlpha;
  }
}

- (BOOL)highlightForSquare:(int)squareIndex
{
  if (squareIndex < 0 || squareIndex >= _squareCount) {
    [NSException raise:@"HLGridNodeInvalidIndex" format:@"Square index %d out of range.", squareIndex];
  }
  return _squareState[squareIndex].highlight;
}

- (void)setHighlight:(BOOL)highlight forSquare:(int)squareIndex
{
  if (squareIndex < 0 || squareIndex >= _squareCount) {
    [NSException raise:@"HLGridNodeInvalidIndex" format:@"Square index %d out of range.", squareIndex];
  }
  NSArray *squareNodes = _gridNode.children;
  SKSpriteNode *squareNode = squareNodes[(NSUInteger)squareIndex];

  _squareState[squareIndex].highlight = highlight;
  if (highlight) {
    squareNode.color = _highlightColor;
  } else {
    squareNode.color = _squareColor;
  }
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
  NSArray *squareNodes = _gridNode.children;
  SKSpriteNode *squareNode = squareNodes[(NSUInteger)squareIndex];

  BOOL startingHighlight = _squareState[squareIndex].highlight;
  SKAction *blinkIn = [SKAction colorizeWithColor:(startingHighlight ? _squareColor : _highlightColor) colorBlendFactor:1.0f duration:halfCycleDuration];
  blinkIn.timingMode = SKActionTimingEaseIn;
  SKAction *blinkOut = [SKAction colorizeWithColor:(startingHighlight ? _highlightColor : _squareColor) colorBlendFactor:1.0f duration:halfCycleDuration];
  blinkOut.timingMode = SKActionTimingEaseOut;
  NSMutableArray *blinkActions = [NSMutableArray array];
  for (int b = 0; b < blinkCount; ++b) {
    [blinkActions addObject:blinkIn];
    [blinkActions addObject:blinkOut];
  }
  if (startingHighlight != finalHighlight) {
    [blinkActions addObject:blinkIn];
  }

  _squareState[squareIndex].highlight = finalHighlight;
  [squareNode runAction:[SKAction sequence:blinkActions] completion:completion];
}

- (int)selectionSquare
{
  return _selectionSquareIndex;
}

- (void)setSelectionForSquare:(int)squareIndex
{
  if (_selectionSquareIndex >= 0) {
    [self setHighlight:NO forSquare:_selectionSquareIndex];
  }
  [self setHighlight:YES forSquare:squareIndex];
  _selectionSquareIndex = squareIndex;
}

- (void)setSelectionForSquare:(int)squareIndex
                   blinkCount:(int)blinkCount
            halfCycleDuration:(NSTimeInterval)halfCycleDuration
                   completion:(void (^)(void))completion
{
  if (_selectionSquareIndex >= 0) {
    [self setHighlight:NO forSquare:_selectionSquareIndex];
  }
  [self setHighlight:YES forSquare:squareIndex blinkCount:blinkCount halfCycleDuration:halfCycleDuration completion:completion];
  _selectionSquareIndex = squareIndex;
}

- (void)clearSelection
{
  if (_selectionSquareIndex >= 0) {
    [self setHighlight:NO forSquare:_selectionSquareIndex];
    _selectionSquareIndex = -1;
  }
}

- (void)clearSelectionBlinkCount:(int)blinkCount
               halfCycleDuration:(NSTimeInterval)halfCycleDuration
                      completion:(void (^)(void))completion
{
  if (_selectionSquareIndex >= 0) {
    [self setHighlight:NO forSquare:_selectionSquareIndex blinkCount:blinkCount halfCycleDuration:halfCycleDuration completion:completion];
    _selectionSquareIndex = -1;
  }
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

  int squareIndex = [self squareAtLocation:location];
  if (squareIndex < 0) {
    return;
  }

  if (self.squareTappedBlock) {
    self.squareTappedBlock(squareIndex);
  }

  id <HLGridNodeDelegate> delegate = _delegate;
  if (delegate) {
    [delegate gridNode:self didTapSquare:squareIndex];
  }
}

#pragma mark -
#pragma mark Private

- (void)HL_allocateSquareState
{
  _squareState = (HLGridNodeSquareState *)malloc(sizeof(HLGridNodeSquareState) * (size_t)_squareCount);
  for (int s = 0; s < _squareCount; ++s) {
    _squareState[s].enabled = NO;
    _squareState[s].highlight = NO;
  }
}

- (void)HL_freeSquareState
{
  free(_squareState);
}

- (void)HL_layoutGrid
{
  [_gridNode removeAllChildren];

  // Calculate grid geometry.
  int gridHeight = (_squareCount - 1) / _gridWidth + 1;
  CGSize squaresArea = CGSizeMake(_gridWidth * _squareSize.width + (_gridWidth - 1) * _squareSeparatorSize,
                                  gridHeight * _squareSize.height + (gridHeight - 1) * _squareSeparatorSize);
  CGSize gridNodeSize = CGSizeMake(squaresArea.width + 2.0f * _backgroundBorderSize,
                                   squaresArea.height + 2.0f * _backgroundBorderSize);
  _gridNode.size = gridNodeSize;
  CGPoint upperLeftPoint = CGPointMake(-_gridNode.anchorPoint.x * gridNodeSize.width + _backgroundBorderSize,
                                       (1.0f - _gridNode.anchorPoint.y) * gridNodeSize.height - _backgroundBorderSize);

  // Arrange square nodes in grid.
  CGFloat zPositionLayerIncrement = self.zPositionScale / HLGridNodeZPositionLayerCount;
  CGFloat squareNodeZPosition = HLGridNodeZPositionLayerSquares * zPositionLayerIncrement;
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
      SKSpriteNode *squareNode = [SKSpriteNode spriteNodeWithColor:_squareColor size:squareSizeInRow];
      squareNode.zPosition = squareNodeZPosition;
      squareNode.position = CGPointMake(upperLeftPoint.x + squareSizeInRow.width / 2.0f + x * (squareSizeInRow.width + _squareSeparatorSize),
                                        upperLeftPoint.y - squareSizeInRow.height / 2.0f - y * (squareSizeInRow.height + _squareSeparatorSize));
      [_gridNode addChild:squareNode];
    }
  }
}

@end
