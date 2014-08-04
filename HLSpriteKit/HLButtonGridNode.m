//
//  HLButtonGridNode.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 7/14/14.
//  Copyright (c) 2014 Hilo. All rights reserved.
//

#import "HLButtonGridNode.h"

typedef struct {
  BOOL enabled;
  BOOL highlight;
} HLButtonGridNodeSquareState;

@implementation HLButtonGridNode
{
  SKSpriteNode *_gridNode;
  HLButtonGridNodeSquareState *_squareState;
  int _selectionSquareIndex;

  // Primary layout-affecting parameters.
  //
  // note: Currently only set at init time to avoid problems with multiple layout (if they
  // are set individually).
  int _gridWidth;
  int _squareCount;
  HLButtonGridNodeLayoutMode _layoutMode;
  CGSize _squareSize;
  CGFloat _backgroundBorderSize;
  CGFloat _squareSeparatorSize;
}

- (id)initWithGridWidth:(int)gridWidth
            squareCount:(int)squareCount
             layoutMode:(HLButtonGridNodeLayoutMode)layoutMode
             squareSize:(CGSize)squareSize
   backgroundBorderSize:(CGFloat)backgroundBorderSize
    squareSeparatorSize:(CGFloat)squareSeparatorSize{
  self = [super init];
  if (self) {

    _gridWidth = gridWidth;
    _squareCount = squareCount;
    _layoutMode = layoutMode;
    _squareSize = squareSize;
    _backgroundBorderSize = backgroundBorderSize;
    _squareSeparatorSize = squareSeparatorSize;

    _gridNode = [SKSpriteNode spriteNodeWithColor:[SKColor colorWithWhite:0.0f alpha:0.5f] size:CGSizeZero];
    [self addChild:_gridNode];

    [self HL_allocateSquareState];
    _selectionSquareIndex = -1;

    _squareColor = [SKColor colorWithWhite:1.0f alpha:0.3f];
    _highlightColor = [SKColor colorWithWhite:1.0f alpha:0.6f];

    [self HL_layoutGrid];
  }
  return self;
}

- (void)dealloc
{
  [self HL_freeSquareState];
}

- (CGSize)size
{
  return _gridNode.size;
}

- (void)setButtons:(NSArray *)buttonNodes
{
  NSArray *squareNodes = [_gridNode children];
  for (SKSpriteNode *squareNode in squareNodes) {
    [squareNode removeAllChildren];
  }

  NSUInteger buttonCount = [buttonNodes count];
  NSUInteger i = 0;
  while (i < buttonCount && i < (NSUInteger)_squareCount) {
    SKNode *buttonNode = (SKNode *)[buttonNodes objectAtIndex:i];
    SKSpriteNode *squareNode = (SKSpriteNode *)[squareNodes objectAtIndex:i];
    // note: Could let caller worry about zPosition.
    buttonNode.zPosition = 0.1f;
    [squareNode addChild:buttonNode];
    ++i;
  }
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
    if (_layoutMode == HLButtonGridNodeLayoutModeFill) {
      squareWidthInRow = (_gridNode.size.width - 2.0f * _backgroundBorderSize - (squaresInRow - 1) * _squareSeparatorSize) / squaresInRow;
    } else {
      squareWidthInRow = _squareSize.width;
    }

    x = (int)((location.x - lowerLeftPoint.x + _squareSeparatorSize) / (squareWidthInRow + _squareSeparatorSize));
    if (_layoutMode == HLButtonGridNodeLayoutModeAlignLeft && x >= squaresInRow) {
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

- (void)setEnabled:(BOOL)enabled forSquare:(int)squareIndex
{
  if (squareIndex > _squareCount) {
    [NSException raise:@"HLButtonGridInvalidIndex" format:@"Square index %d out of range.", squareIndex];
  }
  NSArray *squareNodes = _gridNode.children;
  SKSpriteNode *squareNode = [squareNodes objectAtIndex:(NSUInteger)squareIndex];

  _squareState[squareIndex].enabled = enabled;
  if (enabled) {
    squareNode.alpha = _enabledAlpha;
  } else {
    squareNode.alpha = _disabledAlpha;
  }
}

- (void)setHighlight:(BOOL)highlight forSquare:(int)squareIndex
{
  if (squareIndex > _squareCount) {
    [NSException raise:@"HLButtonGridInvalidIndex" format:@"Square index %d out of range.", squareIndex];
  }
  NSArray *squareNodes = _gridNode.children;
  SKSpriteNode *squareNode = [squareNodes objectAtIndex:(NSUInteger)squareIndex];

  _squareState[squareIndex].highlight = highlight;
  if (highlight) {
    squareNode.color = _highlightColor;
  } else {
    squareNode.color = _squareColor;
  }
}

- (void)animateHighlight:(BOOL)finalHighlight
              blinkCount:(int)blinkCount
       halfCycleDuration:(NSTimeInterval)halfCycleDuration
               forSquare:(int)squareIndex
              completion:(void(^)(void))completion
{
  if (squareIndex > _squareCount) {
    [NSException raise:@"HLButtonGridInvalidIndex" format:@"Square index %d out of range.", squareIndex];
  }
  NSArray *squareNodes = _gridNode.children;
  SKSpriteNode *squareNode = [squareNodes objectAtIndex:(NSUInteger)squareIndex];

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

- (void)setSelectionForSquare:(int)squareIndex
{
  if (_selectionSquareIndex >= 0) {
    [self setHighlight:NO forSquare:_selectionSquareIndex];
  }
  [self setHighlight:YES forSquare:squareIndex];
  _selectionSquareIndex = squareIndex;
}

- (void)animateSelectionBlinkCount:(int)blinkCount
                 halfCycleDuration:(NSTimeInterval)halfCycleDuration
                         forSquare:(int)squareIndex
                        completion:(void (^)(void))completion
{
  if (_selectionSquareIndex >= 0) {
    [self setHighlight:NO forSquare:_selectionSquareIndex];
  }
  [self animateHighlight:YES blinkCount:blinkCount halfCycleDuration:halfCycleDuration forSquare:squareIndex completion:completion];
  _selectionSquareIndex = squareIndex;
}

- (void)clearSelection
{
  if (_selectionSquareIndex >= 0) {
    [self setHighlight:NO forSquare:_selectionSquareIndex];
  }
}

#pragma mark -
#pragma mark HLGestureTarget

- (BOOL)addsToTapGestureRecognizer
{
  return YES;
}

- (BOOL)addsToDoubleTapGestureRecognizer
{
  return NO;
}

- (BOOL)addsToLongPressGestureRecognizer
{
  return NO;
}

- (BOOL)addsToPanGestureRecognizer
{
  return NO;
}

- (BOOL)addsToPinchGestureRecognizer
{
  return NO;
}

- (BOOL)addToGesture:(UIGestureRecognizer *)gestureRecognizer firstTouch:(UITouch *)touch isInside:(BOOL *)isInside
{
  *isInside = YES;
  [gestureRecognizer addTarget:self action:@selector(handleTap:)];
  return YES;
}

- (void)handleTap:(UIGestureRecognizer *)gestureRecognizer
{
  if (!self.squareTappedBlock) {
    return;
  }

  CGPoint viewLocation = [gestureRecognizer locationInView:self.scene.view];
  CGPoint sceneLocation = [self.scene convertPointFromView:viewLocation];
  CGPoint location = [self convertPoint:sceneLocation fromNode:self.scene];

  int squareIndex = [self squareAtLocation:location];
  if (squareIndex >= 0) {
    self.squareTappedBlock(squareIndex);
  }
}

#pragma mark -
#pragma mark Private

- (void)HL_allocateSquareState
{
  _squareState = (HLButtonGridNodeSquareState *)malloc(sizeof(HLButtonGridNodeSquareState) * (size_t)_squareCount);
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
                                       _gridNode.anchorPoint.y * gridNodeSize.height - _backgroundBorderSize);

  // Arrange square nodes in grid.
  //
  // note: Add to parent _gridNode in the display order of buttons property; currently,
  // that's documented as starting upper-left and filling rows before columns.
  for (int y = 0; y < gridHeight; ++y) {

    int squaresInRow;
    CGSize squareSizeInRow;
    if (y + 1 < gridHeight) {
      squaresInRow = _gridWidth;
      squareSizeInRow = _squareSize;
    } else {
      squaresInRow = (_squareCount - 1) % _gridWidth + 1;
      squareSizeInRow = _squareSize;
      if (_layoutMode == HLButtonGridNodeLayoutModeFill) {
        squareSizeInRow.width = (squaresArea.width - (squaresInRow - 1) * _squareSeparatorSize) / squaresInRow;
      }
    }

    for (int x = 0; x < squaresInRow; ++x) {
      SKSpriteNode *squareNode = [SKSpriteNode spriteNodeWithColor:_squareColor size:squareSizeInRow];
      squareNode.zPosition = 0.1f;
      squareNode.position = CGPointMake(upperLeftPoint.x + squareSizeInRow.width / 2.0f + x * (squareSizeInRow.width + _squareSeparatorSize),
                                        upperLeftPoint.y - squareSizeInRow.height / 2.0f - y * (squareSizeInRow.height + _squareSeparatorSize));
      [_gridNode addChild:squareNode];
    }
  }
}

@end
