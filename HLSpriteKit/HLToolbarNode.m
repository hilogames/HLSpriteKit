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

#include <tgmath.h>

#import "HLTextureStore.h"

static UIColor *HLToolbarColorBackground;
static UIColor *HLToolbarColorButtonNormal;
static UIColor *HLToolbarColorButtonHighlighted;

@implementation HLToolbarNode
{
  SKCropNode *_cropNode;
  SKNode *_toolsNode;
  NSMutableArray *_toolButtonNodes;
  CGPoint _lastOrigin;
}

+ (void)initialize
{
  HLToolbarColorBackground = [UIColor colorWithWhite:0.0f alpha:0.5f];
  HLToolbarColorButtonNormal = [UIColor colorWithWhite:0.7f alpha:0.5f];
  HLToolbarColorButtonHighlighted = [UIColor colorWithWhite:1.0f alpha:0.8f];
}

- (id)init
{
  return [self initWithSize:CGSizeZero];
}

- (id)initWithSize:(CGSize)size
{
  self = [super initWithColor:HLToolbarColorBackground size:size];
  if (self) {
    _toolPad = 0.0f;
    _automaticHeight = NO;
    _automaticWidth = NO;
    _justification = HLToolbarNodeJustificationCenter;
    _borderSize = 4.0f;
    _toolSeparatorSize = 4.0f;
    
    // note: All animations happen within a cropped area, currently.
    _cropNode = [SKCropNode node];
    _cropNode.maskNode = [SKSpriteNode spriteNodeWithColor:[UIColor colorWithWhite:1.0f alpha:1.0f] size:size];
    _cropNode.maskNode.position = CGPointMake((0.5f - self.anchorPoint.x) * size.width, (0.5f - self.anchorPoint.y) * size.height);
    [self addChild:_cropNode];
  }
  return self;
}

- (void)setSize:(CGSize)size
{
  [super setSize:size];
  [(SKSpriteNode *)_cropNode.maskNode setSize:size];
  _cropNode.maskNode.position = CGPointMake((0.5f - self.anchorPoint.x) * self.size.width, (0.5f - self.anchorPoint.y) * self.size.height);
}

- (void)setAnchorPoint:(CGPoint)anchorPoint
{
  [super setAnchorPoint:anchorPoint];
  _cropNode.maskNode.position = CGPointMake((0.5f - self.anchorPoint.x) * self.size.width, (0.5f - self.anchorPoint.y) * self.size.height);
}

- (void)setToolsWithTextureKeys:(NSArray *)keys store:(HLTextureStore *)textureStore rotations:(NSArray *)rotations offsets:(NSArray *)offsets animation:(HLToolbarNodeAnimation)animation
{
  const NSTimeInterval HLToolbarResizeDuration = 0.15f;
  const NSTimeInterval HLToolbarSlideDuration = 0.15f;

  // noob: If we can assume properties of the toolbar node, like anchorPoint and zPosition,
  // then we could use simpler calculations here.  But no, for now assume those properties
  // should be determined by the owner, and we should always set our children relative.
  
  _toolButtonNodes = [NSMutableArray array];
  SKNode *toolsNode = [SKNode node];

  // noob: Calculate sizes in an unscaled environment, and then re-apply scale once finished.
  // I'm pretty sure this is a hack, but I'm too lazy to prove it (and fix it).  The self.size
  // and self.frame.size both account for current scale.  Doing the math without changing the
  // current scale should just mean multiplying all the non-scaled values (texture natural size,
  // pads and borders) by self.scale, or, alternately, dividing self.size by self.scale for
  // calculation and then multiplying/dividing right before actually setting dimensions in the
  // scaled world (?).  But a quick attempt to do so didn't give the exact right results, and
  // so I gave up; this is easier, and immediately worked.  Like I said: probably a hack.
  CGFloat oldXScale = self.xScale;
  CGFloat oldYScale = self.yScale;
  self.xScale = 1.0f;
  self.yScale = 1.0f;
  
  // Find natural tool sizes (based on sizes of textures).
  NSUInteger toolsCount = [keys count];
  CGSize naturalToolsSize = CGSizeZero;
  for (NSUInteger i = 0; i < toolsCount; ++i) {
    NSString *key = [keys objectAtIndex:i];
    SKTexture *toolTexture = [textureStore textureForKey:key];
    if (!toolTexture) {
      [NSException raise:@"HLToolbarNodeMissingTexture" format:@"Missing texture for key '%@'.", key];
    }
    CGFloat rotation = (CGFloat)M_PI_2;
    if (rotations) {
      rotation = [[rotations objectAtIndex:i] floatValue];
    }
    CGSize naturalToolSize = HL_rotatedSizeBounds(toolTexture.size, rotation);
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
  CGSize toolbarConstantSize = CGSizeMake(_toolSeparatorSize * (toolsCount - 1) + _toolPad * (toolsCount * 2) + _borderSize * 2,
                                          _toolPad * 2 + _borderSize * 2);
  CGFloat finalToolsScale;
  CGSize finalToolbarSize;
  BOOL shouldSetToolbarSize = NO;
  if (_automaticWidth && _automaticHeight) {
    finalToolsScale = 1.0f;
    finalToolbarSize = CGSizeMake(naturalToolsSize.width + toolbarConstantSize.width,
                                  naturalToolsSize.height + toolbarConstantSize.height);
    shouldSetToolbarSize = YES;
  } else if (_automaticWidth) {
    finalToolsScale = (self.size.height - toolbarConstantSize.height) / naturalToolsSize.height;
    finalToolbarSize = CGSizeMake(naturalToolsSize.width * finalToolsScale + toolbarConstantSize.width,
                                  self.size.height);
    shouldSetToolbarSize = YES;
  } else if (_automaticHeight) {
    finalToolsScale = (self.size.width - toolbarConstantSize.width) / naturalToolsSize.width;
    finalToolbarSize = CGSizeMake(self.size.width,
                                  naturalToolsSize.height * finalToolsScale + toolbarConstantSize.height);
    shouldSetToolbarSize = YES;
  } else {
    finalToolsScale = MIN((self.size.width - toolbarConstantSize.width) / naturalToolsSize.width,
                          (self.size.height - toolbarConstantSize.height) / naturalToolsSize.height);
    finalToolbarSize = self.size;
  }
  
  // Set toolbar size.
  if (shouldSetToolbarSize) {
    if (animation == HLToolbarNodeAnimationNone) {
      self.size = finalToolbarSize;
    } else {
      SKAction *resize = [SKAction resizeToWidth:finalToolbarSize.width height:finalToolbarSize.height duration:HLToolbarResizeDuration];
      resize.timingMode = SKActionTimingEaseOut;
      [self runAction:resize];
      // noob: The cropNode mask must be resized (and maybe repositioned) along with the toolbar size.  The property mutator
      // of the toolbar (setSize, above) is not called by the animation, so we must explicitly update during the animation.
      SKAction *resizeMaskNode = [SKAction customActionWithDuration:HLToolbarResizeDuration actionBlock:^(SKNode *node, CGFloat elapsedTime){
        SKSpriteNode *maskNode = (SKSpriteNode *)node;
        maskNode.size = self.size;
        maskNode.position = CGPointMake((0.5f - self.anchorPoint.x) * self.size.width, (0.5f - self.anchorPoint.y) * self.size.height);
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
  CGFloat x = self.anchorPoint.x * finalToolbarSize.width * -1.0f + _borderSize + justificationOffset;
  CGFloat y = self.anchorPoint.y * finalToolbarSize.height * -1.0f + finalToolbarSize.height / 2.0f;
  for (NSUInteger i = 0; i < toolsCount; ++i) {

    NSString *key = [keys objectAtIndex:i];
    CGFloat rotation = (CGFloat)M_PI_2;
    if (rotations) {
      rotation = [[rotations objectAtIndex:i] floatValue];
    }
    CGPoint offset = CGPointZero;
    if (offsets) {
      [[offsets objectAtIndex:i] getValue:&offset];
    }

    // note: Here the "tool" refers to the rectangular button area created in which
    // to draw the tool texture.
    SKTexture *toolTexture = [textureStore textureForKey:key];
    CGSize naturalToolSize = HL_rotatedSizeBounds(toolTexture.size, rotation);
    CGSize finalToolSize = CGSizeMake(naturalToolSize.width * finalToolsScale,
                                      naturalToolSize.height * finalToolsScale);

    SKSpriteNode *toolButtonNode = [SKSpriteNode spriteNodeWithColor:HLToolbarColorButtonNormal
                                                                size:CGSizeMake(finalToolSize.width + _toolPad * 2,
                                                                                finalToolSize.height + _toolPad * 2)];
    toolButtonNode.name = key;
    toolButtonNode.zPosition = 0.1f;
    toolButtonNode.anchorPoint = CGPointMake(0.0f, 0.5f);
    toolButtonNode.position = CGPointMake(x, y);
    [toolsNode addChild:toolButtonNode];
    [_toolButtonNodes addObject:toolButtonNode];

    SKSpriteNode *toolNode = [SKSpriteNode spriteNodeWithTexture:toolTexture size:finalToolSize];
    toolNode.zPosition = 0.1f;
    toolNode.anchorPoint = CGPointMake(0.5f, 0.5f);
    toolNode.position = CGPointMake(offset.x * finalToolsScale + finalToolSize.width / 2.0f + _toolPad,
                                    offset.y * finalToolsScale);
    toolNode.zRotation = rotation;
    [toolButtonNode addChild:toolNode];

    x += finalToolSize.width + _toolPad * 2 + _toolSeparatorSize;
  }
  
  SKNode *oldToolsNode = _toolsNode;
  _toolsNode = toolsNode;
  [_cropNode addChild:toolsNode];
  if (animation == HLToolbarNodeAnimationNone) {
    if (oldToolsNode) {
      [oldToolsNode removeFromParent];
    }
  } else {
    // note: If toolbar is not animated to change size, then we don't need the MAXs below.
    CGPoint delta;
    switch (animation) {
      case HLToolbarNodeAnimationSlideUp:
        delta = CGPointMake(0.0f, MAX(finalToolbarSize.height, self.size.height));
        break;
      case HLToolbarNodeAnimationSlideDown:
        delta = CGPointMake(0.0f, -1.0f * MAX(finalToolbarSize.height, self.size.height));
        break;
      case HLToolbarNodeAnimationSlideLeft:
        delta = CGPointMake(-1.0f * MAX(finalToolbarSize.width, self.size.width), 0.0f);
        break;
      case HLToolbarNodeAnimationSlideRight:
        delta = CGPointMake(MAX(finalToolbarSize.width, self.size.width), 0.0f);
        break;
      default:
        [NSException raise:@"HLToolbarNodeUnhandledAnimation" format:@"Unhandled animation %d.", animation];
        break;
    }
    toolsNode.position = CGPointMake(-delta.x, -delta.y);
    [toolsNode runAction:[SKAction moveByX:delta.x y:delta.y duration:HLToolbarSlideDuration]];
    if (oldToolsNode) {
      [oldToolsNode runAction:[SKAction sequence:@[ [SKAction moveByX:delta.x y:delta.y duration:HLToolbarSlideDuration],
                                                    [SKAction removeFromParent] ]]];
    }
  }
  
  self.xScale = oldXScale;
  self.yScale = oldYScale;
}

- (NSUInteger)toolCount
{
  return [_toolButtonNodes count];
}

- (NSString *)toolAtLocation:(CGPoint)location
{
  for (SKSpriteNode *toolButtonNode in _toolButtonNodes) {
    if ([toolButtonNode containsPoint:location]) {
      return toolButtonNode.name;
    }
  }
  return nil;
}

- (CGRect)toolFrame:(NSString *)key
{
  for (SKSpriteNode *toolButtonNode in _toolButtonNodes) {
    if ([toolButtonNode.name isEqualToString:key]) {
      return toolButtonNode.frame;
    }
  }
  return CGRectZero;
}

- (void)setHighlight:(BOOL)highlight forTool:(NSString *)key
{
  SKSpriteNode *toolButtonNode = nil;
  for (toolButtonNode in _toolButtonNodes) {
    if ([toolButtonNode.name isEqualToString:key]) {
      if (highlight) {
        toolButtonNode.color = HLToolbarColorButtonHighlighted;
      } else {
        toolButtonNode.color = HLToolbarColorButtonNormal;
      }
    }
  }
}

- (void)animateHighlight:(BOOL)finalHighlight count:(int)blinkCount halfCycleDuration:(NSTimeInterval)halfCycleDuration forTool:(NSString *)key
{
  SKSpriteNode *toolButtonNode = nil;
  for (toolButtonNode in _toolButtonNodes) {
    if ([toolButtonNode.name isEqualToString:key]) {
      break;
    }
  }
  if (!toolButtonNode) {
    return;
  }

  BOOL startingHighlight = (toolButtonNode.color == HLToolbarColorButtonHighlighted);
  SKAction *blinkIn = [SKAction colorizeWithColor:(startingHighlight ? HLToolbarColorButtonNormal : HLToolbarColorButtonHighlighted) colorBlendFactor:1.0f duration:halfCycleDuration];
  blinkIn.timingMode = SKActionTimingEaseIn;
  SKAction *blinkOut = [SKAction colorizeWithColor:(startingHighlight ? HLToolbarColorButtonHighlighted : HLToolbarColorButtonNormal) colorBlendFactor:1.0f duration:halfCycleDuration];
  blinkOut.timingMode = SKActionTimingEaseOut;
  NSMutableArray *blinkActions = [NSMutableArray array];
  for (int b = 0; b < blinkCount; ++b) {
    [blinkActions addObject:blinkIn];
    [blinkActions addObject:blinkOut];
  }
  if (startingHighlight != finalHighlight) {
    [blinkActions addObject:blinkIn];
  }

  [toolButtonNode runAction:[SKAction sequence:blinkActions]];
}

- (void)setEnabled:(BOOL)enabled forTool:(NSString *)key
{
  for (SKSpriteNode *toolButtonNode in _toolButtonNodes) {
    if ([toolButtonNode.name isEqualToString:key]) {
      if (enabled) {
        toolButtonNode.alpha = 1.0f;
      } else {
        toolButtonNode.alpha = 0.4f;
      }
      break;
    }
  }
}

- (BOOL)enabledForTool:(NSString *)key
{
  for (SKSpriteNode *toolButtonNode in _toolButtonNodes) {
    if ([toolButtonNode.name isEqualToString:key]) {
      return (toolButtonNode.alpha > 0.5f);
    }
  }
  return NO;
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

CGSize HL_rotatedSizeBounds(CGSize size, CGFloat theta)
{
  // note: These casts back to CGFloat are supposed to be unnecessary because of
  // the type-generic cos() macro defined in tgmath.h.  But I get loss-of-precision
  // warnings when compiling for 32-bit simulator without the casts; I'm not sure who
  // is to blame.
  CGFloat widthRotatedWidth = size.width * (CGFloat)cos(theta);
  CGFloat widthRotatedHeight = size.width * (CGFloat)sin(theta);
  CGFloat heightRotatedWidth = size.height * (CGFloat)sin(theta);
  CGFloat heightRotatedHeight = size.height * (CGFloat)cos(theta);
  return CGSizeMake(widthRotatedWidth + heightRotatedWidth,
                    widthRotatedHeight + heightRotatedHeight);
}

@end
