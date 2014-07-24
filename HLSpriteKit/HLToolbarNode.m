//
//  HLToolbarNode.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 12/12/13.
//  Copyright (c) 2013 Hilo. All rights reserved.
//

// noob: See notes in notes/objective-c.txt.  I spent time thinking about how this
// SKNode subclass should detect and respond to gestures from gesture recognizers.
// The result is a bit awkward and tightly-coupled.

#import "HLToolbarNode.h"

#import "HLMath.h"
#import "HLTextureStore.h"

typedef struct {
  BOOL enabled;
  BOOL highlight;
} HLToolbarNodeSquareState;

@implementation HLToolbarNode
{
  SKSpriteNode *_toolbarNode;
  SKCropNode *_cropNode;
  SKNode *_squaresNode;
  CGPoint _lastOrigin;
  HLToolbarNodeSquareState *_squareState;
}

- (id)init
{
  self = [super init];
  if (self) {

    _squareColor = [SKColor colorWithWhite:0.7f alpha:0.5f];
    _highlightColor = [SKColor colorWithWhite:1.0f alpha:0.8f];
    _enabledAlpha = 1.0f;
    _disabledAlpha = 0.4f;
    _automaticWidth = NO;
    _automaticHeight = NO;
    _justification = HLToolbarNodeJustificationCenter;
    _backgroundBorderSize = 4.0f;
    _squareSeparatorSize = 4.0f;
    _toolPad = 0.0f;

    _toolbarNode = [SKSpriteNode spriteNodeWithColor:[SKColor colorWithWhite:0.0f alpha:0.5f] size:CGSizeZero];
    [self addChild:_toolbarNode];

    // note: All animations happen within a cropped area, currently.
    _cropNode = [SKCropNode node];
    _cropNode.maskNode = [SKSpriteNode spriteNodeWithColor:[UIColor colorWithWhite:1.0f alpha:1.0f] size:CGSizeZero];
    [self addChild:_cropNode];

    _squareState = NULL;
  }
  return self;
}

- (void)dealloc
{
  [self HL_freeSquareState];
}

- (void)setBackgroundColor:(SKColor *)backgroundColor
{
  _toolbarNode.color = backgroundColor;
}

- (SKColor *)backgroundColor
{
  return _toolbarNode.color;
}

- (void)setSize:(CGSize)size
{
  _toolbarNode.size = size;
  [(SKSpriteNode *)_cropNode.maskNode setSize:size];
}

- (CGSize)size
{
  return _toolbarNode.size;
}

- (void)setAnchorPoint:(CGPoint)anchorPoint
{
  _toolbarNode.anchorPoint = anchorPoint;
  [(SKSpriteNode *)_cropNode.maskNode setAnchorPoint:anchorPoint];
}

- (CGPoint)anchorPoint
{
  return _toolbarNode.anchorPoint;
}

- (void)setTools:(NSArray *)toolNodes tags:(NSArray *)toolTags animation:(HLToolbarNodeAnimation)animation
{
  const NSTimeInterval HLToolbarResizeDuration = 0.15f;
  const NSTimeInterval HLToolbarSlideDuration = 0.15f;

  SKNode *squaresNode = [SKNode node];

  // Find natural tool sizes.
  NSUInteger toolCount = [toolNodes count];
  CGSize naturalToolsSize = CGSizeZero;
  for (SKNode *toolNode in toolNodes) {
    // note: The tool's frame.size only includes what is visible.  Instead, require that the
    // tool implement a size method.  Assume that the reported size, however, does not yet
    // account for rotation.
    CGSize naturalToolSize = HLGetBoundsForTransformation([(id)toolNode size], toolNode.zRotation);
    naturalToolsSize.width += naturalToolSize.width;
    if (naturalToolSize.height > naturalToolsSize.height) {
      naturalToolsSize.height = naturalToolSize.height;
    }
  }

  // TODO: Some pretty ugly quantization of border sizes and/or tool locations when scaling sizes.
  // I think it's only when the toolbar node itself is scaled (by the owner), but it might also
  // result from any fractional pixel sizes when scaling internally.  Most obvious: As the toolbar
  // increases in size by one full pixel, the extra row of pixels will appear to be allocated to
  // either the top border, or the bottom border, or the tools; the border sizes will look off-by-one.
  // So, clearly, if the owner is scaling us then our only solution would be to keep pad/border
  // sizes constant regardless of scale.  Better, but perhaps mathy, would be to solve the tool scaling
  // so that the pad/border sizes are always integer and symmetrical.  Or can we blame the resampling/aliasing
  // of sprite nodes during scaling -- shouldn't the darker border appear to blend better with it children,
  // even if it jumps from 2 pixels wide down to 1 pixel?  Okay, so then we're left with problems that
  // might be our own fault -- perhaps it's because we're calculating fractional pixel widths for our
  // components, and instead we should always calculate integer pixel widths.  (Also, that way we could
  // choose where to remove a row of pixels, and/or only resize in increments so that all components
  // lose a line of pixels at the same time.)  One note: The rotation code leaves size values with
  // floating point error; maybe that's the problem.  I guess overall I can't decide if this is a simple
  // problem or a complicated one; need to look further.
  //
  // TODO: There is also some ugly scaling going on for the segment tools because they are usually
  // larger than the toolbar size, but their texture filtering mode is usually set to "nearest"
  // (for intentionally-pixellated upscaling).  But that's different.  As a tangent, though, I seem
  // to get strange behavior when I mess with this: For instance, if I copy the texture from the
  // texture store and force it here to use linear filtering, then it looks nice in the toolbar...
  // but then all my segment textures dragged into the track seem to take on the same filtering.
  // And testing the value of texture.filteringMode gives unexpected results.

  // Calculate tool scale.
  //
  // note: If caller would like to prevent tools from growing past their natural size,
  // even when a large toolbar size is specified, we could add an option to limit
  // finalToolsScale to 1.0f.
  CGSize toolbarConstantSize = CGSizeMake(_squareSeparatorSize * (toolCount - 1) + _toolPad * (toolCount * 2) + _backgroundBorderSize * 2,
                                          _toolPad * 2 + _backgroundBorderSize * 2);
  CGFloat finalToolsScale;
  CGSize finalToolbarSize;
  BOOL shouldSetToolbarSize = NO;
  if (_automaticWidth && _automaticHeight) {
    finalToolsScale = 1.0f;
    finalToolbarSize = CGSizeMake(naturalToolsSize.width + toolbarConstantSize.width,
                                  naturalToolsSize.height + toolbarConstantSize.height);
    shouldSetToolbarSize = YES;
  } else if (_automaticWidth) {
    finalToolsScale = (_toolbarNode.size.height - toolbarConstantSize.height) / naturalToolsSize.height;
    finalToolbarSize = CGSizeMake(naturalToolsSize.width * finalToolsScale + toolbarConstantSize.width,
                                  _toolbarNode.size.height);
    shouldSetToolbarSize = YES;
  } else if (_automaticHeight) {
    finalToolsScale = (_toolbarNode.size.width - toolbarConstantSize.width) / naturalToolsSize.width;
    finalToolbarSize = CGSizeMake(_toolbarNode.size.width,
                                  naturalToolsSize.height * finalToolsScale + toolbarConstantSize.height);
    shouldSetToolbarSize = YES;
  } else {
    finalToolsScale = MIN((_toolbarNode.size.width - toolbarConstantSize.width) / naturalToolsSize.width,
                          (_toolbarNode.size.height - toolbarConstantSize.height) / naturalToolsSize.height);
    finalToolbarSize = _toolbarNode.size;
  }

  // Set toolbar size.
  if (shouldSetToolbarSize) {
    if (animation == HLToolbarNodeAnimationNone) {
      _toolbarNode.size = finalToolbarSize;
      [(SKSpriteNode *)_cropNode.maskNode setSize:finalToolbarSize];
    } else {
      SKAction *resize = [SKAction resizeToWidth:finalToolbarSize.width height:finalToolbarSize.height duration:HLToolbarResizeDuration];
      resize.timingMode = SKActionTimingEaseOut;
      [_toolbarNode runAction:resize];
      // noob: The cropNode mask must be resized along with the toolbar size.  Or am I missing something?
      SKAction *resizeMaskNode = [SKAction customActionWithDuration:HLToolbarResizeDuration actionBlock:^(SKNode *node, CGFloat elapsedTime){
        SKSpriteNode *maskNode = (SKSpriteNode *)node;
        maskNode.size = self->_toolbarNode.size;
      }];
      resizeMaskNode.timingMode = resize.timingMode;
      [_cropNode.maskNode runAction:resizeMaskNode];
    }
  }

  // Calculate justification offset.
  CGFloat justificationOffset = 0.0f;
  if (_justification == HLToolbarNodeJustificationLeft) {
    justificationOffset = 0.0f;
  } else {
    CGFloat remainingToolsWidth = finalToolbarSize.width - toolbarConstantSize.width - naturalToolsSize.width * finalToolsScale;
    if (_justification == HLToolbarNodeJustificationCenter) {
      justificationOffset = remainingToolsWidth / 2.0f;
    } else {
      justificationOffset = remainingToolsWidth;
    }
  }

  // Set tools (scaled and positioned appropriately).
  CGFloat x = _toolbarNode.anchorPoint.x * -finalToolbarSize.width + _backgroundBorderSize + justificationOffset;
  CGFloat y = _toolbarNode.anchorPoint.y * -finalToolbarSize.height + finalToolbarSize.height / 2.0f;
  for (NSUInteger i = 0; i < toolCount; ++i) {
    SKNode *toolNode = [toolNodes objectAtIndex:i];
    NSString *toolTag = [toolTags objectAtIndex:i];

    CGSize naturalToolSize = HLGetBoundsForTransformation([(id)toolNode size], toolNode.zRotation);
    // note: Can multiply toolNode.scale by finalToolsScale, directly.  But that's messing
    // with the properties of the nodes passed in to us.  Instead, set the scale of the
    // square, which will then be inherited (multiplied) automatically.
    CGSize finalToolSize = CGSizeMake(naturalToolSize.width * finalToolsScale,
                                      naturalToolSize.height * finalToolsScale);
    CGSize squareSize = CGSizeMake(finalToolSize.width + _toolPad * 2.0f,
                                   finalToolSize.height + _toolPad * 2.0f);
    SKSpriteNode *squareNode = [SKSpriteNode spriteNodeWithColor:_squareColor size:CGSizeMake(squareSize.width / finalToolsScale,
                                                                                              squareSize.height / finalToolsScale)];
    squareNode.name = toolTag;
    squareNode.xScale = finalToolsScale;
    squareNode.yScale = finalToolsScale;
    squareNode.alpha = _enabledAlpha;
    squareNode.zPosition = 0.1f;
    squareNode.position = CGPointMake(x + finalToolSize.width / 2.0f + _toolPad, y);
    [squaresNode addChild:squareNode];

    //toolNode.xScale *= finalToolsScale;
    //toolNode.yScale *= finalToolsScale;
    toolNode.zPosition = 0.1f;
    [squareNode addChild:toolNode];

    x += finalToolSize.width + _toolPad * 2 + _squareSeparatorSize;
  }
  // note: Allocate square state; note that it will be initalized as enabled and unhighlighted,
  // as in code above.
  [self HL_allocateSquareState];

  SKNode *oldSquaresNode = _squaresNode;
  _squaresNode = squaresNode;
  [_cropNode addChild:squaresNode];
  if (animation == HLToolbarNodeAnimationNone) {
    if (oldSquaresNode) {
      [oldSquaresNode removeFromParent];
    }
  } else {
    // note: If toolbar is not animated to change size, then we don't need the MAXs below.
    CGPoint delta;
    switch (animation) {
      case HLToolbarNodeAnimationSlideUp:
        delta = CGPointMake(0.0f, MAX(finalToolbarSize.height, _toolbarNode.size.height));
        break;
      case HLToolbarNodeAnimationSlideDown:
        delta = CGPointMake(0.0f, -1.0f * MAX(finalToolbarSize.height, _toolbarNode.size.height));
        break;
      case HLToolbarNodeAnimationSlideLeft:
        delta = CGPointMake(-1.0f * MAX(finalToolbarSize.width, _toolbarNode.size.width), 0.0f);
        break;
      case HLToolbarNodeAnimationSlideRight:
        delta = CGPointMake(MAX(finalToolbarSize.width, _toolbarNode.size.width), 0.0f);
        break;
      default:
        [NSException raise:@"HLToolbarNodeUnhandledAnimation" format:@"Unhandled animation %d.", animation];
        break;
    }
    squaresNode.position = CGPointMake(-delta.x, -delta.y);
    [squaresNode runAction:[SKAction moveByX:delta.x y:delta.y duration:HLToolbarSlideDuration]];
    if (oldSquaresNode) {
      [oldSquaresNode runAction:[SKAction sequence:@[ [SKAction moveByX:delta.x y:delta.y duration:HLToolbarSlideDuration],
                                                      [SKAction removeFromParent] ]]];
    }
  }
}

- (NSUInteger)toolCount
{
  return [_squaresNode.children count];
}

- (NSString *)toolAtLocation:(CGPoint)location
{
  for (SKSpriteNode *squareNode in _squaresNode.children) {
    if ([squareNode containsPoint:location]) {
      return squareNode.name;
    }
  }
  return nil;
}

- (CGRect)frameForTool:(NSString *)toolTag
{
  for (SKSpriteNode *squareNode in _squaresNode.children) {
    if ([squareNode.name isEqualToString:toolTag]) {
      return squareNode.frame;
    }
  }
  return CGRectZero;
}

- (void)setHighlight:(BOOL)highlight forTool:(NSString *)toolTag
{
  int s = 0;
  for (SKSpriteNode *squareNode in _squaresNode.children) {
    if ([squareNode.name isEqualToString:toolTag]) {
      _squareState[s].highlight = highlight;
      if (highlight) {
        squareNode.color = _highlightColor;
      } else {
        squareNode.color = _squareColor;
      }
      break;
    }
    ++s;
  }
}

- (void)animateHighlight:(BOOL)finalHighlight count:(int)blinkCount halfCycleDuration:(NSTimeInterval)halfCycleDuration forTool:(NSString *)toolTag
{
  int s = 0;
  SKSpriteNode *squareNode = nil;
  for (squareNode in _squaresNode.children) {
    if ([squareNode.name isEqualToString:toolTag]) {
      break;
    }
    ++s;
  }
  if (!squareNode) {
    return;
  }
  
  BOOL startingHighlight = _squareState[s].highlight;
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

  [squareNode runAction:[SKAction sequence:blinkActions]];
}

- (void)setEnabled:(BOOL)enabled forTool:(NSString *)toolTag
{
  int s = 0;
  for (SKSpriteNode *squareNode in _squaresNode.children) {
    if ([squareNode.name isEqualToString:toolTag]) {
      _squareState[s].enabled = enabled;
      if (enabled) {
        squareNode.alpha = _enabledAlpha;
      } else {
        squareNode.alpha = _disabledAlpha;
      }
      break;
    }
    ++s;
  }
}

- (BOOL)enabledForTool:(NSString *)toolTag
{
  int s = 0;
  for (SKSpriteNode *squareNode in _squaresNode.children) {
    if ([squareNode.name isEqualToString:toolTag]) {
      return _squareState[s].enabled;
    }
    ++s;
  }
  return YES;
}

- (void)showWithOrigin:(CGPoint)origin finalPosition:(CGPoint)finalPosition fullScale:(CGFloat)fullScale animated:(BOOL)animated
{
  // noob: I'm encapsulating this animation within the toolbar, since the toolbar knows cool ways to make itself
  // appear, and can track some useful state.  But the owner of this toolbar knows the anchor, position, size, and
  // scale of this toolbar, which then all needs to be communicated to this animation method.  Kind of a pain.

  // noob: I assume this will always take effect before we are removed from parent (at the end of the hide).
  [self removeActionForKey:@"hide"];

  if (animated) {
    const NSTimeInterval HLToolbarNodeShowDuration = 0.15;
    self.xScale = 0.0f;
    self.yScale = 0.0f;
    SKAction *grow = [SKAction scaleTo:fullScale duration:HLToolbarNodeShowDuration];
    self.position = origin;
    SKAction *move = [SKAction moveTo:finalPosition duration:HLToolbarNodeShowDuration];
    SKAction *showGroup = [SKAction group:@[ grow, move ]];
    showGroup.timingMode = SKActionTimingEaseOut;
    [self runAction:showGroup];
  } else {
    self.position = finalPosition;
    self.xScale = fullScale;
    self.yScale = fullScale;
  }
  _lastOrigin = origin;
}

- (void)hideAnimated:(BOOL)animated
{
  if (animated) {
    const NSTimeInterval HLToolbarNodeHideDuration = 0.15;
    SKAction *shrink = [SKAction scaleTo:0.0f duration:HLToolbarNodeHideDuration];
    SKAction *move = [SKAction moveTo:_lastOrigin duration:HLToolbarNodeHideDuration];
    SKAction *hideGroup = [SKAction group:@[ shrink, move]];
    hideGroup.timingMode = SKActionTimingEaseIn;
    SKAction *remove = [SKAction removeFromParent];
    SKAction *hideSequence = [SKAction sequence:@[ hideGroup, remove ]];
    [self runAction:hideSequence withKey:@"hide"];
  } else {
    [self removeFromParent];
  }
}

#pragma mark -
#pragma mark Private

- (void)HL_allocateSquareState
{
  int squareCount = (int)[_toolbarNode.children count];
  _squareState = (HLToolbarNodeSquareState *)malloc(sizeof(HLToolbarNodeSquareState) * (size_t)squareCount);
  for (int s = 0; s < squareCount; ++s) {
    _squareState[s].enabled = NO;
    _squareState[s].highlight = NO;
  }
}

- (void)HL_freeSquareState
{
  free(_squareState);
}

@end
