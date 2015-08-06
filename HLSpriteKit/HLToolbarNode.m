//
//  HLToolbarNode.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 12/12/13.
//  Copyright (c) 2013 Hilo Games. All rights reserved.
//

#import "HLToolbarNode.h"

#import "HLMath.h"
#import "HLItemNode.h"
#import "HLItemsNode.h"

enum {
  HLToolbarNodeZPositionLayerBackground = 0,
  HLToolbarNodeZPositionLayerSquares,
  HLToolbarNodeZPositionLayerCount
};

static const NSTimeInterval HLToolbarResizeDuration = 0.15f;
static const NSTimeInterval HLToolbarSlideDuration = 0.15f;

@implementation HLToolbarNode
{
  SKSpriteNode *_backgroundNode;
  SKCropNode *_cropNode;
  HLItemsNode *_squaresNode;
  CGPoint _lastOrigin;
}

- (instancetype)init
{
  self = [super init];
  if (self) {

    _squareColor = [SKColor colorWithWhite:0.7f alpha:0.5f];
    _highlightColor = [SKColor colorWithWhite:1.0f alpha:0.8f];
    _enabledAlpha = 1.0f;
    _disabledAlpha = 0.4f;
    _automaticWidth = NO;
    _automaticHeight = NO;
    _automaticToolsScaleLimit = NO;
    _anchorPoint = CGPointMake(0.5f, 0.5f);
    _justification = HLToolbarNodeJustificationCenter;
    _backgroundBorderSize = 4.0f;
    _squareSeparatorSize = 4.0f;
    _toolPad = 0.0f;

    _backgroundNode = [SKSpriteNode spriteNodeWithColor:[SKColor colorWithWhite:0.0f alpha:0.5f] size:CGSizeZero];
    [self addChild:_backgroundNode];

    // note: All animations happen within a cropped area, currently.
    _cropNode = [SKCropNode node];
    _cropNode.maskNode = [SKSpriteNode spriteNodeWithColor:[SKColor colorWithWhite:1.0f alpha:1.0f] size:CGSizeZero];
    [self addChild:_cropNode];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  [NSException raise:@"HLCodingNotImplemented" format:@"Coding not implemented for this descendant of an NSCoding parent."];
  // note: Call [init] for the sake of the compiler trying to detect problems with designated initializers.
  return [self init];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
  [NSException raise:@"HLCopyingNotImplemented" format:@"Copying not implemented for this descendant of an NSCopying parent."];
  return nil;
}

- (void)setBackgroundColor:(SKColor *)backgroundColor
{
  _backgroundNode.color = backgroundColor;
}

- (SKColor *)backgroundColor
{
  return _backgroundNode.color;
}

- (void)setSquareColor:(UIColor *)squareColor
{
  _squareColor = squareColor;
  NSArray *squareNodes = _squaresNode.itemNodes;
  for (HLBackdropItemNode *squareNode in squareNodes) {
    squareNode.normalColor = _squareColor;
  }
}

- (void)setHighlightColor:(UIColor *)highlightColor
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

- (BOOL)containsPoint:(CGPoint)p
{
  // note: A bug, I think, in SpriteKit and SKCropNode: When the toolbar is animated to change tools,
  // the old squares node has a position animation within its parent (the crop node), and then the
  // old squares node is removed.  But even after it is removed, the crop node will still report it
  // as part of its accumulated frame.
  //
  // noob: Not sure if I'm correcting a bug here or causing more problems.  This could be seen as
  // mostly impacting the HLGestureTarget stuff, in which case a possible solution would be to
  // have HLGestureTargets define their custom hit test methods (with default implementation of
  // containsPoint).  But if I'm really correcting a bug here, then this is bigger than just
  // HLGestureTarget and should apply to all callers.  (Well, and all callers of calculateAccumulatedFrame,
  // too.)
  return [_backgroundNode containsPoint:[self convertPoint:p fromNode:self.parent]];
}

- (void)setZPositionScale:(CGFloat)zPositionScale
{
  [super setZPositionScale:zPositionScale];
  [self HL_layoutZ];
}

- (void)setTools:(NSArray *)toolNodes tags:(NSArray *)toolTags animation:(HLToolbarNodeAnimation)animation
{
  NSUInteger toolCount = [toolNodes count];
  if ([toolTags count] < toolCount) {
    [NSException raise:@"HLToolbarNodeInvalidArgument" format:@"Every tool must have a tag."];
  }

  HLBackdropItemNode *itemPrototypeNode = [[HLBackdropItemNode alloc] initWithSize:CGSizeZero];
  itemPrototypeNode.normalColor = _squareColor;
  itemPrototypeNode.highlightColor = _highlightColor;
  itemPrototypeNode.enabledAlpha = _enabledAlpha;
  itemPrototypeNode.disabledAlpha = _disabledAlpha;
  HLItemsNode *squaresNode = [[HLItemsNode alloc] initWithItemCount:(int)toolCount itemPrototype:itemPrototypeNode];
  NSArray *squareNodes = squaresNode.itemNodes;
  for (NSUInteger i = 0; i < toolCount; ++i) {
    HLBackdropItemNode *squareNode = squareNodes[i];
    squareNode.content = toolNodes[i];
    squareNode.name = toolTags[i];
  }

  HLItemsNode *oldSquaresNode = _squaresNode;
  _squaresNode = squaresNode;
  [_cropNode addChild:squaresNode];

  CGSize oldSize = _size;
  [self HL_layoutXYAnimation:animation];
  [self HL_layoutZ];
  CGSize newSize = _size;

  if (animation == HLToolbarNodeAnimationNone) {
    if (oldSquaresNode) {
      [oldSquaresNode removeFromParent];
    }
  } else {
    // note: If toolbar is not animated to change size, then we don't need the MAXs below.
    CGPoint delta;
    switch (animation) {
      case HLToolbarNodeAnimationSlideUp:
        delta = CGPointMake(0.0f, MAX(oldSize.height, newSize.height));
        break;
      case HLToolbarNodeAnimationSlideDown:
        delta = CGPointMake(0.0f, -1.0f * MAX(oldSize.height, newSize.height));
        break;
      case HLToolbarNodeAnimationSlideLeft:
        delta = CGPointMake(-1.0f * MAX(oldSize.width, newSize.width), 0.0f);
        break;
      case HLToolbarNodeAnimationSlideRight:
        delta = CGPointMake(MAX(oldSize.width, newSize.width), 0.0f);
        break;
      default:
        [NSException raise:@"HLToolbarNodeUnhandledAnimation" format:@"Unhandled animation %ld.", (long)animation];
        break;
    }
    squaresNode.position = CGPointMake(-delta.x, -delta.y);
    [squaresNode runAction:[SKAction moveByX:delta.x y:delta.y duration:HLToolbarSlideDuration]];
    if (oldSquaresNode) {
      // note: In iOS8, removeFromParent as SKAction in a sequence causes an untraceable EXC_BAD_ACCESS.
      // Change to a completion block.
      [oldSquaresNode runAction:[SKAction moveByX:delta.x y:delta.y duration:HLToolbarSlideDuration] completion:^{
        [oldSquaresNode removeFromParent];
      }];
      // note: See containsPoint; after this animation the accumulated from of the crop node is unreliable.
    }
  }
}

- (void)setTool:(SKNode *)toolNode forTag:(NSString *)toolTag
{
  int s = 0;
  NSArray *squareNodes = _squaresNode.itemNodes;
  for (HLBackdropItemNode *squareNode in squareNodes) {
    if ([squareNode.name isEqualToString:toolTag]) {
      squareNode.content = toolNode;
      break;
    }
    ++s;
  }
}

- (void)layoutToolsAnimation:(HLToolbarNodeAnimation)animation
{
  [self HL_layoutXYAnimation:animation];
}

- (NSUInteger)toolCount
{
  return [_squaresNode.itemNodes count];
}

- (NSString *)toolAtLocation:(CGPoint)location
{
  NSArray *squareNodes = _squaresNode.itemNodes;
  for (HLBackdropItemNode *squareNode in squareNodes) {
    if ([squareNode containsPoint:location]) {
      return squareNode.name;
    }
  }
  return nil;
}

- (SKNode *)squareNodeForTool:(NSString *)toolTag
{
  NSArray *squareNodes = _squaresNode.itemNodes;
  for (HLBackdropItemNode *squareNode in squareNodes) {
    if ([squareNode.name isEqualToString:toolTag]) {
      return squareNode;
    }
  }
  return nil;
}

- (BOOL)highlightForTool:(NSString *)toolTag
{
  NSArray *squareNodes = _squaresNode.itemNodes;
  for (HLBackdropItemNode *squareNode in squareNodes) {
    if ([squareNode.name isEqualToString:toolTag]) {
      return squareNode.highlight;
    }
  }
  return NO;
}

- (void)setHighlight:(BOOL)highlight forTool:(NSString *)toolTag
{
  NSArray *squareNodes = _squaresNode.itemNodes;
  for (HLBackdropItemNode *squareNode in squareNodes) {
    if ([squareNode.name isEqualToString:toolTag]) {
      squareNode.highlight = highlight;
      break;
    }
  }
}

- (void)toggleHighlightForTool:(NSString *)toolTag
{
  NSArray *squareNodes = _squaresNode.itemNodes;
  for (HLBackdropItemNode *squareNode in squareNodes) {
    if ([squareNode.name isEqualToString:toolTag]) {
      squareNode.highlight = !squareNode.highlight;
      break;
    }
  }
}

- (void)setHighlight:(BOOL)finalHighlight
             forTool:(NSString *)toolTag
          blinkCount:(int)blinkCount
   halfCycleDuration:(NSTimeInterval)halfCycleDuration
          completion:(void (^)(void))completion
{
  NSArray *squareNodes = _squaresNode.itemNodes;
  for (HLBackdropItemNode *squareNode in squareNodes) {
    if ([squareNode.name isEqualToString:toolTag]) {
      [squareNode setHighlight:finalHighlight
                    blinkCount:blinkCount
             halfCycleDuration:halfCycleDuration
                    completion:completion];
    }
  }
}

- (BOOL)enabledForTool:(NSString *)toolTag
{
  NSArray *squareNodes = _squaresNode.itemNodes;
  for (HLBackdropItemNode *squareNode in squareNodes) {
    if ([squareNode.name isEqualToString:toolTag]) {
      return squareNode.enabled;
    }
  }
  return YES;
}

- (void)setEnabled:(BOOL)enabled forTool:(NSString *)toolTag
{
  NSArray *squareNodes = _squaresNode.itemNodes;
  for (HLBackdropItemNode *squareNode in squareNodes) {
    if ([squareNode.name isEqualToString:toolTag]) {
      squareNode.enabled = enabled;
      break;
    }
  }
}

- (void)showWithOrigin:(CGPoint)origin
         finalPosition:(CGPoint)finalPosition
             fullScale:(CGFloat)fullScale
              animated:(BOOL)animated
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

- (void)showUpdateOrigin:(CGPoint)origin
{
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
    // note: Avoiding [SKAction removeFromParent]; see
    //   http://stackoverflow.com/questions/26131591/exc-bad-access-sprite-kit/26188747
    SKAction *remove = [SKAction runBlock:^{
      [self removeFromParent];
    }];
    SKAction *hideSequence = [SKAction sequence:@[ hideGroup, remove ]];
    [self runAction:hideSequence withKey:@"hide"];
  } else {
    // note: It's a little perverse to set position back to _lastOrigin, but we do it for
    // consistency between animated and non-animated.  The caller might be confused to find
    // that any changes to position while the toolbar is showing will be discarded once the
    // toolbar is hidden again; on the other hand, showUpdateOrigin is provided for the
    // purpose, and the caller will be forced to explicitly pass position again when calling
    // showWithOrigin.
    self.position = _lastOrigin;
    [self removeFromParent];
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

  NSString *toolTag = [self toolAtLocation:location];
  if (!toolTag) {
    return;
  }

  if (_toolTappedBlock) {
    _toolTappedBlock(toolTag);
  }

  id <HLToolbarNodeDelegate> delegate = _delegate;
  if (delegate) {
    [delegate toolbarNode:self didTapTool:toolTag];
  }
}

#pragma mark -
#pragma mark Private

- (void)HL_layoutXYAnimation:(HLToolbarNodeAnimation)animation
{
  // Find natural tool sizes.
  CGSize naturalToolsSize = CGSizeZero;
  NSArray *squareNodes = _squaresNode.itemNodes;
  for (HLBackdropItemNode *squareNode in squareNodes) {
    // note: The tool's frame.size only includes what is visible.  Instead, require that the
    // tool implement a size method.  Assume that the reported size, however, does not yet
    // account for rotation.
    SKNode *toolNode = squareNode.content;
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
  int squareCount = (int)[squareNodes count];
  CGSize toolbarConstantSize = CGSizeMake(_squareSeparatorSize * (squareCount - 1) + _toolPad * (squareCount * 2) + _backgroundBorderSize * 2,
                                          _toolPad * 2 + _backgroundBorderSize * 2);
  CGFloat finalToolsScale;
  CGSize finalToolbarSize;
  if (_automaticWidth && _automaticHeight) {
    finalToolsScale = 1.0f;
    finalToolbarSize = CGSizeMake(naturalToolsSize.width + toolbarConstantSize.width,
                                  naturalToolsSize.height + toolbarConstantSize.height);
  } else if (_automaticWidth) {
    finalToolsScale = (_size.height - toolbarConstantSize.height) / naturalToolsSize.height;
    if (_automaticToolsScaleLimit && finalToolsScale > 1.0f) {
      finalToolsScale = 1.0f;
    }
    finalToolbarSize = CGSizeMake(naturalToolsSize.width * finalToolsScale + toolbarConstantSize.width,
                                  _size.height);
  } else if (_automaticHeight) {
    finalToolsScale = (_size.width - toolbarConstantSize.width) / naturalToolsSize.width;
    if (_automaticToolsScaleLimit && finalToolsScale > 1.0f) {
      finalToolsScale = 1.0f;
    }
    finalToolbarSize = CGSizeMake(_size.width,
                                  naturalToolsSize.height * finalToolsScale + toolbarConstantSize.height);
  } else {
    finalToolsScale = MIN((_size.width - toolbarConstantSize.width) / naturalToolsSize.width,
                          (_size.height - toolbarConstantSize.height) / naturalToolsSize.height);
    if (_automaticToolsScaleLimit && finalToolsScale > 1.0f) {
      finalToolsScale = 1.0f;
    }
    finalToolbarSize = _size;
  }

  // note: Size and anchorPoint may or may not have changed, but if this is the first layout, then _backgroundNode
  // and _cropNode have not yet been initialized correctly.  (We could do it in the property mutator methods, but
  // the documented promise is that "no changes take effect until an explicit call to layout"; moreover, since in
  // those mutators the _squaresNode wouldn't be updated, the effected change might only be partial, and therefore
  // ugly.)
  
  // Set toolbar size.
  _size = finalToolbarSize;
  if (animation == HLToolbarNodeAnimationNone) {
    _backgroundNode.size = finalToolbarSize;
    [(SKSpriteNode *)_cropNode.maskNode setSize:finalToolbarSize];
  } else if (!CGSizeEqualToSize(_backgroundNode.size, finalToolbarSize)) {
    SKAction *resize = [SKAction resizeToWidth:finalToolbarSize.width height:finalToolbarSize.height duration:HLToolbarResizeDuration];
    resize.timingMode = SKActionTimingEaseOut;
    [_backgroundNode runAction:resize];
    // noob: The cropNode mask must be resized along with the toolbar size.  Or am I missing something?
    SKAction *resizeMaskNode = [SKAction customActionWithDuration:HLToolbarResizeDuration actionBlock:^(SKNode *node, CGFloat elapsedTime){
      SKSpriteNode *maskNode = (SKSpriteNode *)node;
      maskNode.size = self->_backgroundNode.size;
    }];
    resizeMaskNode.timingMode = resize.timingMode;
    [_cropNode.maskNode runAction:resizeMaskNode];
  }

  // Set toolbar anchorPoint.
  _backgroundNode.anchorPoint = _anchorPoint;
  [(SKSpriteNode *)_cropNode.maskNode setAnchorPoint:_anchorPoint];
  
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
  
  // Layout tools (scaled and positioned appropriately).
  CGFloat x = _anchorPoint.x * -finalToolbarSize.width + _backgroundBorderSize + justificationOffset;
  CGFloat y = _anchorPoint.y * -finalToolbarSize.height + finalToolbarSize.height / 2.0f;
  for (HLBackdropItemNode *squareNode in squareNodes) {
    SKNode *toolNode = squareNode.content;
    
    CGSize naturalToolSize = HLGetBoundsForTransformation([(id)toolNode size], toolNode.zRotation);
    // note: Can multiply toolNode.scale by finalToolsScale, directly.  But that's messing
    // with the properties of the nodes passed in to us.  Instead, set the scale of the
    // square, which will then be inherited (multiplied) automatically.
    CGSize finalToolSize = CGSizeMake(naturalToolSize.width * finalToolsScale,
                                      naturalToolSize.height * finalToolsScale);
    CGSize squareSize = CGSizeMake(finalToolSize.width + _toolPad * 2.0f,
                                   finalToolSize.height + _toolPad * 2.0f);
    squareNode.size = CGSizeMake(squareSize.width / finalToolsScale,
                                 squareSize.height / finalToolsScale);
    squareNode.xScale = finalToolsScale;
    squareNode.yScale = finalToolsScale;
    squareNode.position = CGPointMake(x + finalToolSize.width / 2.0f + _toolPad, y);
    
    x += finalToolSize.width + _toolPad * 2 + _squareSeparatorSize;
  }
}

- (void)HL_layoutZ
{
  CGFloat zPositionLayerIncrement = self.zPositionScale / HLToolbarNodeZPositionLayerCount;
  _backgroundNode.zPosition = HLToolbarNodeZPositionLayerBackground * zPositionLayerIncrement;
  _squaresNode.zPosition = HLToolbarNodeZPositionLayerSquares * zPositionLayerIncrement;
  _squaresNode.zPositionScale = zPositionLayerIncrement;
}

@end

@implementation HLToolbarNodeMultiGestureTarget

- (instancetype)initWithToolbarNode:(HLToolbarNode *)toolbarNode
{
  self = [super init];
  if (self) {
    _toolbarNode = toolbarNode;
  }
  return self;
}

- (NSArray *)addsToGestureRecognizers
{
  UITapGestureRecognizer *doubleTapRecognizer = [[UITapGestureRecognizer alloc] init];
  doubleTapRecognizer.numberOfTapsRequired = 2;
  return @[ [[UITapGestureRecognizer alloc] init],
            doubleTapRecognizer,
            [[UILongPressGestureRecognizer alloc] init],
            [[UIPanGestureRecognizer alloc] init] ];
}

- (BOOL)addToGesture:(UIGestureRecognizer *)gestureRecognizer firstTouch:(UITouch *)touch isInside:(BOOL *)isInside
{
  *isInside = YES;
  if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
    // note: Require only one touch, same as our gesture recognizer returned from
    // addsToGestureRecognizers?  I think it's okay to be non-strict.
    NSUInteger numberOfTapsRequired = [(UITapGestureRecognizer *)gestureRecognizer numberOfTapsRequired];
    switch (numberOfTapsRequired) {
      case 1:
        [gestureRecognizer addTarget:self action:@selector(handleTap:)];
        return YES;
      case 2:
        [gestureRecognizer addTarget:self action:@selector(handleDoubleTap:)];
        return YES;
      default:
        break;
    }
  } else if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
    [gestureRecognizer addTarget:self action:@selector(handleLongPress:)];
    return YES;
  } else if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
    [gestureRecognizer addTarget:self action:@selector(handlePan:)];
    return YES;
  }
  return NO;
}

- (void)handleTap:(UIGestureRecognizer *)gestureRecognizer
{
  id <HLToolbarNodeMultiGestureTargetDelegate> delegate = _delegate;
  if (!delegate) {
    return;
  }

  CGPoint viewLocation = [gestureRecognizer locationInView:_toolbarNode.scene.view];
  CGPoint sceneLocation = [_toolbarNode.scene convertPointFromView:viewLocation];
  CGPoint location = [_toolbarNode convertPoint:sceneLocation fromNode:_toolbarNode.scene];
  
  NSString *toolTag = [_toolbarNode toolAtLocation:location];
  if (!toolTag) {
    return;
  }
  
  [delegate toolbarNode:_toolbarNode didTapTool:toolTag];
}

- (void)handleDoubleTap:(UIGestureRecognizer *)gestureRecognizer
{
  id <HLToolbarNodeMultiGestureTargetDelegate> delegate = _delegate;
  if (!delegate) {
    return;
  }
  
  CGPoint viewLocation = [gestureRecognizer locationInView:_toolbarNode.scene.view];
  CGPoint sceneLocation = [_toolbarNode.scene convertPointFromView:viewLocation];
  CGPoint location = [_toolbarNode convertPoint:sceneLocation fromNode:_toolbarNode.scene];
  
  NSString *toolTag = [_toolbarNode toolAtLocation:location];
  if (!toolTag) {
    return;
  }
  
  [delegate toolbarNode:_toolbarNode didDoubleTapTool:toolTag];
}

- (void)handleLongPress:(UIGestureRecognizer *)gestureRecognizer
{
  id <HLToolbarNodeMultiGestureTargetDelegate> delegate = _delegate;
  if (!delegate) {
    return;
  }
  
  CGPoint viewLocation = [gestureRecognizer locationInView:_toolbarNode.scene.view];
  CGPoint sceneLocation = [_toolbarNode.scene convertPointFromView:viewLocation];
  CGPoint location = [_toolbarNode convertPoint:sceneLocation fromNode:_toolbarNode.scene];
  
  NSString *toolTag = [_toolbarNode toolAtLocation:location];
  if (!toolTag) {
    return;
  }
  
  [delegate toolbarNode:_toolbarNode didLongPressTool:toolTag];
}

- (void)handlePan:(UIPanGestureRecognizer *)gestureRecognizer
{
  id <HLToolbarNodeMultiGestureTargetDelegate> delegate = _delegate;
  if (!delegate) {
    return;
  }

  [delegate toolbarNode:_toolbarNode didPanWithGestureRecognizer:gestureRecognizer];
}

@end
