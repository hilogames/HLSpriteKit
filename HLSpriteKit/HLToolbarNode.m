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
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self) {

    _delegate = [aDecoder decodeObjectForKey:@"delegate"];

    // note: Cannot decode toolTappedBlock.  Assume it will be reset on decode.

    _backgroundNode = [aDecoder decodeObjectForKey:@"backgroundNode"];
    _cropNode = [aDecoder decodeObjectForKey:@"cropNode"];
    _squaresNode = [aDecoder decodeObjectForKey:@"squaresNode"];

    _squareColor = [aDecoder decodeObjectForKey:@"squareColor"];
    _highlightColor = [aDecoder decodeObjectForKey:@"highlightColor"];
    _enabledAlpha = (CGFloat)[aDecoder decodeDoubleForKey:@"enabledAlpha"];
    _disabledAlpha = (CGFloat)[aDecoder decodeDoubleForKey:@"disabledAlpha"];

    _automaticWidth = [aDecoder decodeBoolForKey:@"automaticWidth"];
    _automaticHeight = [aDecoder decodeBoolForKey:@"automaticHeight"];
    _automaticToolsScaleLimit = [aDecoder decodeBoolForKey:@"automaticToolsScaleLimit"];
#if TARGET_OS_IPHONE
    _size = [aDecoder decodeCGSizeForKey:@"size"];
    _anchorPoint = [aDecoder decodeCGPointForKey:@"anchorPoint"];
#else
    _size = [aDecoder decodeSizeForKey:@"size"];
    _anchorPoint = [aDecoder decodePointForKey:@"anchorPoint"];
#endif
    _justification = [aDecoder decodeIntegerForKey:@"justification"];
    _backgroundBorderSize = (CGFloat)[aDecoder decodeDoubleForKey:@"backgroundBorderSize"];
    _squareSeparatorSize = (CGFloat)[aDecoder decodeDoubleForKey:@"squareSeparatorSize"];
    _toolPad = (CGFloat)[aDecoder decodeDoubleForKey:@"toolPad"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [super encodeWithCoder:aCoder];

  [aCoder encodeConditionalObject:_delegate forKey:@"delegate"];

  // note: Cannot encode toolTappedBlock.  Assume it will be reset on decode.

  [aCoder encodeObject:_backgroundNode forKey:@"backgroundNode"];
  [aCoder encodeObject:_cropNode forKey:@"cropNode"];
  [aCoder encodeObject:_squaresNode forKey:@"squaresNode"];

  [aCoder encodeObject:_squareColor forKey:@"squareColor"];
  [aCoder encodeObject:_highlightColor forKey:@"highlightColor"];
  [aCoder encodeDouble:_enabledAlpha forKey:@"enabledAlpha"];
  [aCoder encodeDouble:_disabledAlpha forKey:@"disabledAlpha"];

  [aCoder encodeBool:_automaticWidth forKey:@"automaticWidth"];
  [aCoder encodeBool:_automaticHeight forKey:@"automaticHeight"];
  [aCoder encodeBool:_automaticToolsScaleLimit forKey:@"automaticToolsScaleLimit"];
#if TARGET_OS_IPHONE
  [aCoder encodeCGSize:_size forKey:@"size"];
  [aCoder encodeCGPoint:_anchorPoint forKey:@"anchorPoint"];
#else
  [aCoder encodeSize:_size forKey:@"size"];
  [aCoder encodePoint:_anchorPoint forKey:@"anchorPoint"];
#endif
  [aCoder encodeInteger:_justification forKey:@"justification"];
  [aCoder encodeDouble:_backgroundBorderSize forKey:@"backgroundBorderSize"];
  [aCoder encodeDouble:_squareSeparatorSize forKey:@"squareSeparatorSize"];
  [aCoder encodeDouble:_toolPad forKey:@"toolPad"];
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
  if (_contentClipped) {
    return [_backgroundNode containsPoint:[self convertPoint:p fromNode:self.parent]];
  } else {
    return [super containsPoint:p];
  }
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
  if (_contentClipped) {
    [_cropNode addChild:squaresNode];
  } else {
    [self addChild:squaresNode];
  }

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
      // note: In iOS8, [SKAction removeFromParent] in a sequence causes an untraceable EXC_BAD_ACCESS.
      [oldSquaresNode runAction:[SKAction sequence:@[ [SKAction moveByX:delta.x y:delta.y duration:HLToolbarSlideDuration],
                                                      [SKAction performSelector:@selector(removeFromParent) onTarget:oldSquaresNode] ]]];
      // note: See containsPoint; after this animation the accumulated frame of the crop node is unreliable.
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

- (void)setContentClipped:(BOOL)contentClipped
{
  if (contentClipped == _contentClipped) {
    return;
  }
  _contentClipped = contentClipped;
  if (_contentClipped) {
    _cropNode = [SKCropNode node];
    SKSpriteNode *maskNode = [SKSpriteNode spriteNodeWithColor:[SKColor blackColor] size:_size];
    maskNode.anchorPoint = _anchorPoint;
    _cropNode.maskNode = maskNode;
    [self addChild:_cropNode];
    if (_squaresNode) {
      [_squaresNode removeFromParent];
      [_cropNode addChild:_squaresNode];
    }
  } else {
    [_cropNode removeFromParent];
    _cropNode = nil;
    if (_squaresNode) {
      [_squaresNode removeFromParent];
      [self addChild:_squaresNode];
    }
  }
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

- (SKNode *)toolNodeForTool:(NSString *)toolTag
{
  NSArray *squareNodes = _squaresNode.itemNodes;
  for (HLBackdropItemNode *squareNode in squareNodes) {
    if ([squareNode.name isEqualToString:toolTag]) {
      return squareNode.content;
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

#pragma mark -
#pragma mark HLGestureTarget

- (NSArray *)addsToGestureRecognizers
{
#if TARGET_OS_IPHONE
  return @[ [[UITapGestureRecognizer alloc] init] ];
#else
  return @[ [[NSClickGestureRecognizer alloc] init] ];
#endif
}

- (BOOL)addToGesture:(HLGestureRecognizer *)gestureRecognizer firstLocation:(CGPoint)sceneLocation isInside:(BOOL *)isInside
{
  *isInside = YES;
#if TARGET_OS_IPHONE
  if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
    // note: Require only one tap and one touch, same as our gesture recognizer returned
    // from addsToGestureRecognizers?  I think it's okay to be non-strict.
    [gestureRecognizer addTarget:self action:@selector(handleTap:)];
    return YES;
  }
#else
  if ([gestureRecognizer isKindOfClass:[NSClickGestureRecognizer class]]) {
    [gestureRecognizer addTarget:self action:@selector(handleClick:)];
    return YES;
  }
#endif
  return NO;
}

#if TARGET_OS_IPHONE

- (void)handleTap:(HLGestureRecognizer *)gestureRecognizer
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

#else

- (void)handleClick:(HLGestureRecognizer *)gestureRecognizer
{
  CGPoint viewLocation = [gestureRecognizer locationInView:self.scene.view];
  CGPoint sceneLocation = [self.scene convertPointFromView:viewLocation];
  CGPoint location = [self convertPoint:sceneLocation fromNode:self.scene];

  NSString *toolTag = [self toolAtLocation:location];
  if (!toolTag) {
    return;
  }

  if (_toolClickedBlock) {
    _toolClickedBlock(toolTag);
  }

  id <HLToolbarNodeDelegate> delegate = _delegate;
  if (delegate) {
    [delegate toolbarNode:self didClickTool:toolTag];
  }
}

#endif

#if TARGET_OS_IPHONE

#pragma mark -
#pragma mark UIResponder

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
  if ([touches count] > 1) {
    return;
  }

  UITouch *touch = [touches anyObject];
  if (touch.tapCount > 1) {
    return;
  }

  CGPoint viewLocation = [touch locationInView:self.scene.view];
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

#else

#pragma mark -
#pragma mark NSResponder

- (void)mouseUp:(NSEvent *)event
{
  if (event.clickCount > 1) {
    return;
  }

  CGPoint location = [event locationInNode:self];

  NSString *toolTag = [self toolAtLocation:location];
  if (!toolTag) {
    return;
  }

  if (_toolClickedBlock) {
    _toolClickedBlock(toolTag);
  }

  id <HLToolbarNodeDelegate> delegate = _delegate;
  if (delegate) {
    [delegate toolbarNode:self didClickTool:toolTag];
  }
}

#endif

#pragma mark -
#pragma mark Private

- (CGSize)HL_duckSize:(SKNode *)node
{
#if TARGET_OS_IPHONEs
  return [(id)node size];
#else
  // note: Careful handling of size selector is required when building for macOS,
  // for which the compiler sees multiple definitions with different return types.
  SEL selector = @selector(size);
  NSMethodSignature *sizeMethodSignature = [node methodSignatureForSelector:selector];
  if (sizeMethodSignature
      && strcmp(sizeMethodSignature.methodReturnType, @encode(CGSize)) == 0) {
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sizeMethodSignature];
    invocation.selector = selector;
    [invocation invokeWithTarget:node];
    CGSize nodeSize;
    [invocation getReturnValue:&nodeSize];
    return nodeSize;
  }
  return CGSizeZero;
#endif
}

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
    CGSize basicToolSize = [self HL_duckSize:toolNode];
    CGSize naturalToolSize = HLGetBoundsForTransformation(basicToolSize, toolNode.zRotation);
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
    if (_contentClipped) {
      [(SKSpriteNode *)_cropNode.maskNode setSize:finalToolbarSize];
    }
  } else if (!CGSizeEqualToSize(_backgroundNode.size, finalToolbarSize)) {
    SKAction *resize = [SKAction resizeToWidth:finalToolbarSize.width height:finalToolbarSize.height duration:HLToolbarResizeDuration];
    resize.timingMode = SKActionTimingEaseOut;
    [_backgroundNode runAction:resize];
    // noob: The cropNode mask must be resized along with the toolbar size.  Or am I missing something?
    if (_contentClipped) {
      SKAction *resizeMaskNode = [SKAction customActionWithDuration:HLToolbarResizeDuration actionBlock:^(SKNode *node, CGFloat elapsedTime){
        SKSpriteNode *maskNode = (SKSpriteNode *)node;
        maskNode.size = self->_backgroundNode.size;
      }];
      resizeMaskNode.timingMode = resize.timingMode;
      [_cropNode.maskNode runAction:resizeMaskNode];
    }
  }

  // Set toolbar anchorPoint.
  _backgroundNode.anchorPoint = _anchorPoint;
  if (_contentClipped) {
    [(SKSpriteNode *)_cropNode.maskNode setAnchorPoint:_anchorPoint];
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

  // Layout tools (scaled and positioned appropriately).
  CGFloat x = _anchorPoint.x * -finalToolbarSize.width + _backgroundBorderSize + justificationOffset;
  CGFloat y = _anchorPoint.y * -finalToolbarSize.height + finalToolbarSize.height / 2.0f;
  for (HLBackdropItemNode *squareNode in squareNodes) {
    SKNode *toolNode = squareNode.content;

    CGSize basicToolSize = [self HL_duckSize:toolNode];
    CGSize naturalToolSize = HLGetBoundsForTransformation(basicToolSize, toolNode.zRotation);
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

#if TARGET_OS_IPHONE

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

- (BOOL)addToGesture:(HLGestureRecognizer *)gestureRecognizer firstLocation:(CGPoint)sceneLocation isInside:(BOOL *)isInside
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

#endif
