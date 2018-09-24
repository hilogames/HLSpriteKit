//
//  HLScrollNode.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 10/20/14.
//  Copyright (c) 2014 Hilo Games. All rights reserved.
//

#import "HLScrollNode.h"

// note: Scroll node is currently flat, but in the future there might be scroll bar
// decorations or a background color or whatnot.
enum {
  HLScrollNodeZPositionLayerContent = 0,
  HLScrollNodeZPositionLayerCount
};

@implementation HLScrollNode
{
  CGPoint _contentOffsetOffline;
  CGFloat _contentScaleOffline;

  CGPoint _scrollLastNodeLocation;
  CGPoint _zoomPinContentLocation;
  CGPoint _zoomPinNodeLocation;
  CGFloat _zoomOriginalContentScale;

#if TARGET_OS_IPHONE
  CGFloat _touchesOriginalNodeDistance;
#endif
}

- (instancetype)init
{
  return [self initWithSize:CGSizeZero contentSize:CGSizeZero];
}

- (instancetype)initWithSize:(CGSize)size contentSize:(CGSize)contentSize
{
  self = [super init];
  if (self) {
    _size = size;
    _anchorPoint = CGPointMake(0.5f, 0.5f);
    _contentSize = contentSize;
    _contentAnchorPoint = CGPointMake(0.5f, 0.5f);
    _contentOffsetOffline = CGPointZero;
#if TARGET_OS_IPHONE
    _contentInset = UIEdgeInsetsZero;
#else
    _contentInset = NSEdgeInsetsZero;
#endif
    _contentScaleOffline = 1.0f;
    _contentScaleMinimum = 1.0f;
    _contentScaleMinimumMode = HLScrollNodeContentScaleMinimumFitTight;
    _contentScaleMaximum = 1.0f;
    _contentClipped = NO;
  }
  return self;
}

- (instancetype)initWithSize:(CGSize)size
                 anchorPoint:(CGPoint)anchorPoint
                     content:(SKNode *)contentNode
                 contentSize:(CGSize)contentSize
                 contentAnchorPoint:(CGPoint)contentAnchorPoint
               contentOffset:(CGPoint)contentOffset
#if TARGET_OS_IPHONE
                contentInset:(UIEdgeInsets)contentInset
#else
                contentInset:(NSEdgeInsets)contentInset
#endif
                contentScale:(CGFloat)contentScale
         contentScaleMinimum:(CGFloat)contentScaleMinimum
     contentScaleMinimumMode:(HLScrollNodeContentScaleMinimumMode)contentScaleMinimumMode
         contentScaleMaximum:(CGFloat)contentScaleMaximum
{
  self = [super init];
  if (self) {
    _size = size;
    _anchorPoint = anchorPoint;
    _contentSize = contentSize;
    _contentAnchorPoint = contentAnchorPoint;
    _contentOffsetOffline = contentOffset;
    _contentInset = contentInset;
    _contentScaleOffline = contentScale;
    _contentScaleMinimum = contentScaleMinimum;
    _contentScaleMinimumMode = contentScaleMinimumMode;
    _contentScaleMaximum = contentScaleMaximum;
    _contentClipped = NO;

    self.contentNode = contentNode;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self) {

    _delegate = [aDecoder decodeObjectForKey:@"delegate"];

    _contentNode = [aDecoder decodeObjectForKey:@"contentNode"];
#if TARGET_OS_IPHONE
    _size = [aDecoder decodeCGSizeForKey:@"size"];
    _anchorPoint = [aDecoder decodeCGPointForKey:@"anchorPoint"];
    _contentSize = [aDecoder decodeCGSizeForKey:@"contentSize"];
    _contentAnchorPoint = [aDecoder decodeCGPointForKey:@"contentAnchorPoint"];
    _contentInset = [aDecoder decodeUIEdgeInsetsForKey:@"contentInset"];
#else
    _size = [aDecoder decodeSizeForKey:@"size"];
    _anchorPoint = [aDecoder decodePointForKey:@"anchorPoint"];
    _contentSize = [aDecoder decodeSizeForKey:@"contentSize"];
    _contentAnchorPoint = [aDecoder decodePointForKey:@"contentAnchorPoint"];
    _contentInset = NSEdgeInsetsMake((CGFloat)[aDecoder decodeDoubleForKey:@"contentInsetTop"],
                                     (CGFloat)[aDecoder decodeDoubleForKey:@"contentInsetLeft"],
                                     (CGFloat)[aDecoder decodeDoubleForKey:@"contentInsetBottom"],
                                     (CGFloat)[aDecoder decodeDoubleForKey:@"contentInsetRight"]);
#endif
    _contentScaleMinimum = (CGFloat)[aDecoder decodeDoubleForKey:@"contentScaleMinimum"];
    _contentScaleMinimumMode = [aDecoder decodeIntegerForKey:@"contentScaleMinimumMode"];
    _contentScaleMaximum = (CGFloat)[aDecoder decodeDoubleForKey:@"contentScaleMaximum"];
    _contentClipped = [aDecoder decodeBoolForKey:@"contentClipped"];

#if TARGET_OS_IPHONE
    _contentOffsetOffline = [aDecoder decodeCGPointForKey:@"contentOffsetOffline"];
#else
    _contentOffsetOffline = [aDecoder decodePointForKey:@"contentOffsetOffline"];
#endif
    _contentScaleOffline = (CGFloat)[aDecoder decodeDoubleForKey:@"contentScaleOffline"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [super encodeWithCoder:aCoder];

  [aCoder encodeConditionalObject:_delegate forKey:@"delegate"];

  [aCoder encodeObject:_contentNode forKey:@"contentNode"];
#if TARGET_OS_IPHONE
  [aCoder encodeCGSize:_size forKey:@"size"];
  [aCoder encodeCGPoint:_anchorPoint forKey:@"anchorPoint"];
  [aCoder encodeCGSize:_contentSize forKey:@"contentSize"];
  [aCoder encodeCGPoint:_contentAnchorPoint forKey:@"contentAnchorPoint"];
  [aCoder encodeUIEdgeInsets:_contentInset forKey:@"contentInset"];
#else
  [aCoder encodeSize:_size forKey:@"size"];
  [aCoder encodePoint:_anchorPoint forKey:@"anchorPoint"];
  [aCoder encodeSize:_contentSize forKey:@"contentSize"];
  [aCoder encodePoint:_contentAnchorPoint forKey:@"contentAnchorPoint"];
  [aCoder encodeDouble:_contentInset.top forKey:@"contentInsetTop"];
  [aCoder encodeDouble:_contentInset.left forKey:@"contentInsetLeft"];
  [aCoder encodeDouble:_contentInset.bottom forKey:@"contentInsetBottom"];
  [aCoder encodeDouble:_contentInset.right forKey:@"contentInsetRight"];
#endif
  [aCoder encodeDouble:_contentScaleMinimum forKey:@"contentScaleMinimum"];
  [aCoder encodeInteger:_contentScaleMinimumMode forKey:@"contentScaleMinimumMode"];
  [aCoder encodeDouble:_contentScaleMaximum forKey:@"contentScaleMaximum"];
  [aCoder encodeBool:_contentClipped forKey:@"contentClipped"];

#if TARGET_OS_IPHONE
  [aCoder encodeCGPoint:_contentOffsetOffline forKey:@"contentOffsetOffline"];
#else
  [aCoder encodePoint:_contentOffsetOffline forKey:@"contentOffsetOffline"];
#endif
  [aCoder encodeDouble:_contentScaleOffline forKey:@"contentScaleOffline"];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
  [NSException raise:@"HLCopyingNotImplemented" format:@"Copying not implemented for this descendant of an NSCopying parent."];
  return nil;
}

- (void)setSize:(CGSize)size
{
  _size = size;
  if (_contentClipped) {
    SKCropNode *cropNode = (SKCropNode *)self.children.firstObject;
    ((SKSpriteNode *)cropNode.maskNode).size = size;
  }
  if (_contentNode) {
    CGFloat constrainedScale = [self HL_contentConstrainedScale:_contentNode.xScale];
    _contentNode.xScale = constrainedScale;
    _contentNode.yScale = constrainedScale;
    _contentNode.position = [self HL_contentConstrainedPositionX:_contentNode.position.x positionY:_contentNode.position.y scale:constrainedScale];
  }
}

- (void)setAnchorPoint:(CGPoint)anchorPoint
{
  _anchorPoint = anchorPoint;
  if (_contentClipped) {
    SKCropNode *cropNode = (SKCropNode *)self.children.firstObject;
    ((SKSpriteNode *)cropNode.maskNode).anchorPoint = anchorPoint;
  }
  if (_contentNode) {
    _contentNode.position = [self HL_contentConstrainedPositionX:_contentNode.position.x positionY:_contentNode.position.y scale:_contentNode.xScale];
  }
}

- (void)setZPositionScale:(CGFloat)zPositionScale
{
  // note: Scroll node is currently flat, but in the future it might have layers
  // (for example, to display scroll bars decorations, or a background matte.)
  // If/when that happens, then the content node will have to have its zPositionScale
  // configured also -- if it's an HLComponentNode.  The caller won't know the correct
  // layer increment to pass, so it must be our job.
  [super setZPositionScale:zPositionScale];
  if (!_contentNode) {
    return;
  }
  CGFloat zPositionLayerIncrement = zPositionScale / HLScrollNodeZPositionLayerCount;
  _contentNode.zPosition = HLScrollNodeZPositionLayerContent * zPositionLayerIncrement;
  if ([_contentNode isKindOfClass:[HLComponentNode class]]) {
    [(HLComponentNode *)_contentNode setZPositionScale:zPositionLayerIncrement];
  }
}

- (void)setContentNode:(SKNode *)contentNode
{
  if (_contentNode) {
    _contentOffsetOffline = _contentNode.position;
    _contentScaleOffline = _contentNode.xScale;
    [_contentNode removeFromParent];
  }

  _contentNode = contentNode;

  if (_contentNode) {

    if (_contentClipped) {
      SKCropNode *cropNode = (SKCropNode *)self.children.firstObject;
      [cropNode addChild:_contentNode];
    } else {
      [self addChild:_contentNode];
    }

    CGFloat zPositionLayerIncrement = self.zPositionScale / HLScrollNodeZPositionLayerCount;
    _contentNode.zPosition = HLScrollNodeZPositionLayerContent * zPositionLayerIncrement;
    if ([_contentNode isKindOfClass:[HLComponentNode class]]) {
      [(HLComponentNode *)_contentNode setZPositionScale:zPositionLayerIncrement];
    }

    CGFloat constrainedScale = [self HL_contentConstrainedScale:_contentScaleOffline];
    _contentNode.xScale = constrainedScale;
    _contentNode.yScale = constrainedScale;
    _contentNode.position = [self HL_contentConstrainedPositionX:_contentOffsetOffline.x positionY:_contentOffsetOffline.y scale:constrainedScale];
  }
}

- (void)setContent:(SKNode *)contentNode
       contentSize:(CGSize)contentSize
     contentOffset:(CGPoint)contentOffset
      contentScale:(CGFloat)contentScale
{
  if (_contentNode) {
    [_contentNode removeFromParent];
  }

  _contentNode = contentNode;
  _contentSize = contentSize;

  if (!_contentNode) {
    _contentOffsetOffline = contentOffset;
    _contentScaleOffline = contentScale;
    return;
  }

  if (_contentClipped) {
    SKCropNode *cropNode = (SKCropNode *)self.children.firstObject;
    [cropNode addChild:_contentNode];
  } else {
    [self addChild:_contentNode];
  }

  CGFloat zPositionLayerIncrement = self.zPositionScale / HLScrollNodeZPositionLayerCount;
  _contentNode.zPosition = HLScrollNodeZPositionLayerContent * zPositionLayerIncrement;
  if ([_contentNode isKindOfClass:[HLComponentNode class]]) {
    [(HLComponentNode *)_contentNode setZPositionScale:zPositionLayerIncrement];
  }

  CGFloat constrainedScale = [self HL_contentConstrainedScale:contentScale];
  _contentNode.xScale = constrainedScale;
  _contentNode.yScale = constrainedScale;
  _contentNode.position = [self HL_contentConstrainedPositionX:contentOffset.x positionY:contentOffset.y scale:constrainedScale];
}

- (void)setContentSize:(CGSize)contentSize
{
  _contentSize = contentSize;
  if (!_contentNode) {
    return;
  }
  CGFloat constrainedScale = [self HL_contentConstrainedScale:_contentNode.xScale];
  _contentNode.xScale = constrainedScale;
  _contentNode.yScale = constrainedScale;
  _contentNode.position = [self HL_contentConstrainedPositionX:_contentNode.position.x positionY:_contentNode.position.y scale:constrainedScale];
}

- (void)setContentAnchorPoint:(CGPoint)contentAnchorPoint
{
  _contentAnchorPoint = contentAnchorPoint;
  if (!_contentNode) {
    return;
  }
  _contentNode.position = [self HL_contentConstrainedPositionX:_contentNode.position.x positionY:_contentNode.position.y scale:_contentNode.xScale];
}

- (CGPoint)contentOffset
{
  if (!_contentNode) {
    return _contentOffsetOffline;
  }
  return _contentNode.position;
}

- (void)setContentOffset:(CGPoint)contentOffset
{
  if (!_contentNode) {
    _contentOffsetOffline = contentOffset;
    return;
  }
  _contentNode.position = [self HL_contentConstrainedPositionX:contentOffset.x positionY:contentOffset.y scale:_contentNode.xScale];
}

- (void)setContentOffset:(CGPoint)contentOffset animatedDuration:(NSTimeInterval)duration completion:(void (^)(void))completion
{
  SKAction *action = [self actionForSetContentOffset:contentOffset animatedDuration:duration];
  if (!action) {
    _contentOffsetOffline = contentOffset;
    return;
  }
  action.timingMode = SKActionTimingEaseInEaseOut;
  [_contentNode runAction:action completion:completion];
}

- (SKAction *)actionForSetContentOffset:(CGPoint)contentOffset animatedDuration:(NSTimeInterval)duration
{
  if (!_contentNode) {
    return nil;
  }
  // note: Assume it is acceptable to constrain position once rather than continually during animation.
  // One example how that might not be acceptable: If the caller expects the movement to take less
  // than the full animation duration if constrained.
  CGPoint constrainedPosition = [self HL_contentConstrainedPositionX:contentOffset.x positionY:contentOffset.y scale:_contentNode.xScale];
  return [SKAction moveTo:constrainedPosition duration:duration];
}

#if TARGET_OS_IPHONE
- (void)setContentInset:(UIEdgeInsets)contentInset
#else
- (void)setContentInset:(NSEdgeInsets)contentInset
#endif
{
  _contentInset = contentInset;
  if (!_contentNode) {
    return;
  }
  CGFloat constrainedScale = [self HL_contentConstrainedScale:_contentNode.xScale];
  _contentNode.xScale = constrainedScale;
  _contentNode.yScale = constrainedScale;
  _contentNode.position = [self HL_contentConstrainedPositionX:_contentNode.position.x positionY:_contentNode.position.y scale:constrainedScale];
}

- (CGFloat)contentScale
{
  if (!_contentNode) {
    return _contentScaleOffline;
  }
  return _contentNode.xScale;
}

- (void)setContentScale:(CGFloat)contentScale
{
  if (!_contentNode) {
    _contentScaleOffline = contentScale;
    return;
  }
  CGFloat constrainedScale = [self HL_contentConstrainedScale:contentScale];
  _contentNode.xScale = constrainedScale;
  _contentNode.yScale = constrainedScale;
  _contentNode.position = [self HL_contentConstrainedPositionX:_contentNode.position.x positionY:_contentNode.position.y scale:constrainedScale];
}

- (void)setContentScale:(CGFloat)contentScale animatedDuration:(NSTimeInterval)duration completion:(void (^)(void))completion
{
  SKAction *action = [self actionForSetContentScale:contentScale animatedDuration:duration];
  if (!action) {
    _contentScaleOffline = contentScale;
    return;
  }
  action.timingMode = SKActionTimingEaseInEaseOut;
  [_contentNode runAction:action completion:completion];
}

- (SKAction *)actionForSetContentScale:(CGFloat)contentScale animatedDuration:(NSTimeInterval)duration
{
  if (!_contentNode) {
    return nil;
  }
  // note: Assume it is acceptable to constrain scale once rather than continually during animation.
  // Position, however, must be continually constrained based on interpolated scale values.
  CGFloat startConstrainedScale = _contentNode.xScale;
  CGFloat endConstrainedScale = [self HL_contentConstrainedScale:contentScale];
  // note: Remember original position and keep trying to get back to it throughout the animation.
  // An alternate implementation could calculate the constrained final position based on the
  // constrained final scale, and then head there smoothly throughout the animation.
  CGPoint constrainedPosition = _contentNode.position;
  return [SKAction customActionWithDuration:duration actionBlock:^(SKNode *node, CGFloat elapsedTime){
    CGFloat interpolatedScale = startConstrainedScale + (endConstrainedScale - startConstrainedScale) * (CGFloat)(elapsedTime / duration);
    self->_contentNode.xScale = interpolatedScale;
    self->_contentNode.yScale = interpolatedScale;
    self->_contentNode.position = [self HL_contentConstrainedPositionX:constrainedPosition.x positionY:constrainedPosition.y scale:interpolatedScale];
  }];
}

- (void)setContentScaleMinimum:(CGFloat)contentScaleMinimum
{
  _contentScaleMinimum = contentScaleMinimum;
  if (!_contentNode) {
    return;
  }
  CGFloat constrainedScale = [self HL_contentConstrainedScale:_contentNode.xScale];
  _contentNode.xScale = constrainedScale;
  _contentNode.yScale = constrainedScale;
  _contentNode.position = [self HL_contentConstrainedPositionX:_contentNode.position.x positionY:_contentNode.position.y scale:constrainedScale];
}

- (void)setContentScaleMaximum:(CGFloat)contentScaleMaximum
{
  _contentScaleMaximum = contentScaleMaximum;
  if (!_contentNode) {
    return;
  }
  CGFloat constrainedScale = [self HL_contentConstrainedScale:_contentNode.xScale];
  _contentNode.xScale = constrainedScale;
  _contentNode.yScale = constrainedScale;
  _contentNode.position = [self HL_contentConstrainedPositionX:_contentNode.position.x positionY:_contentNode.position.y scale:constrainedScale];
}

- (void)setContentClipped:(BOOL)contentClipped
{
  if (_contentClipped == contentClipped) {
    return;
  }
  _contentClipped = contentClipped;
  if (_contentClipped) {
    SKCropNode *cropNode = [SKCropNode node];
    SKSpriteNode *maskNode = [SKSpriteNode spriteNodeWithColor:[SKColor blackColor] size:_size];
    maskNode.anchorPoint = _anchorPoint;
    cropNode.maskNode = maskNode;
    [self addChild:cropNode];
    if (_contentNode) {
      [_contentNode removeFromParent];
      [cropNode addChild:_contentNode];
    }
  } else {
    SKCropNode *cropNode = (SKCropNode *)self.children.firstObject;
    [cropNode removeFromParent];
    if (_contentNode) {
      [_contentNode removeFromParent];
      [self addChild:_contentNode];
    }
  }
}

- (void)setContentOffset:(CGPoint)contentOffset contentScale:(CGFloat)contentScale
{
  if (!_contentNode) {
    _contentOffsetOffline = contentOffset;
    _contentScaleOffline = contentScale;
    return;
  }
  CGFloat constrainedScale = [self HL_contentConstrainedScale:contentScale];
  _contentNode.xScale = constrainedScale;
  _contentNode.yScale = constrainedScale;
  _contentNode.position = [self HL_contentConstrainedPositionX:contentOffset.x positionY:contentOffset.y scale:constrainedScale];
}

- (void)setContentOffset:(CGPoint)contentOffset
            contentScale:(CGFloat)contentScale
        animatedDuration:(NSTimeInterval)duration
              completion:(void (^)(void))completion
{
  SKAction *action = [self actionForSetContentOffset:contentOffset contentScale:contentScale animatedDuration:duration];
  if (!action) {
    _contentScaleOffline = contentScale;
    return;
  }
  action.timingMode = SKActionTimingEaseInEaseOut;
  [_contentNode runAction:action completion:completion];
}

- (SKAction *)actionForSetContentOffset:(CGPoint)contentOffset
                           contentScale:(CGFloat)contentScale
                       animatedDuration:(NSTimeInterval)duration
{
  if (!_contentNode) {
    return nil;
  }
  // note: Assume it is acceptable to constrain scale once rather than continually during animation.
  // Handle position as in setContentOffset:animatedDuration:completion:, although it's worth noting
  // that here there is more risk of intermediate illegal values for position since scale is changing.
  CGFloat startConstrainedScale = _contentNode.xScale;
  CGFloat endConstrainedScale = [self HL_contentConstrainedScale:contentScale];
  CGPoint startConstrainedPosition = _contentNode.position;
  CGPoint endConstrainedPosition = [self HL_contentConstrainedPositionX:contentOffset.x positionY:contentOffset.y scale:endConstrainedScale];
  return [SKAction customActionWithDuration:duration actionBlock:^(SKNode *node, CGFloat elapsedTime){
    CGFloat elapsedProportion = (CGFloat)(elapsedTime / duration);
    CGFloat interpolatedScale = startConstrainedScale + (endConstrainedScale - startConstrainedScale) * elapsedProportion;
    self->_contentNode.xScale = interpolatedScale;
    self->_contentNode.yScale = interpolatedScale;
    CGPoint interpolatedPosition = CGPointMake(startConstrainedPosition.x + (endConstrainedPosition.x - startConstrainedPosition.x) * elapsedProportion,
                                               startConstrainedPosition.y + (endConstrainedPosition.y - startConstrainedPosition.y) * elapsedProportion);
    // note: Here the interpolatedPosition might not be constrained correctly for the current (interpolated)
    // scale.  But we allow intermediate illegal position values in order to make a smoother animation.
    //self->_contentNode.position = [self HL_contentConstrainedPositionX:interpolatedPosition.x positionY:interpolatedPosition.y scale:interpolatedScale];
    self->_contentNode.position = interpolatedPosition;
  }];
}

- (void)scrollContentLocation:(CGPoint)contentLocation toNodeLocation:(CGPoint)nodeLocation
{
  if (!_contentNode) {
    return;
  }
  // note: Use similar mechanics as setContentOffset:.
  CGFloat constrainedScale = _contentNode.xScale;
  CGPoint contentOffset = CGPointMake(nodeLocation.x - contentLocation.x * constrainedScale,
                                      nodeLocation.y - contentLocation.y * constrainedScale);
  _contentNode.position = [self HL_contentConstrainedPositionX:contentOffset.x positionY:contentOffset.y scale:constrainedScale];
}

- (void)scrollContentLocation:(CGPoint)contentLocation
               toNodeLocation:(CGPoint)nodeLocation
             animatedDuration:(NSTimeInterval)duration
                   completion:(void (^)(void))completion
{
  SKAction *action = [self actionForScrollContentLocation:contentLocation toNodeLocation:nodeLocation animatedDuration:duration];
  if (!action) {
    return;
  }
  action.timingMode = SKActionTimingEaseInEaseOut;
  [_contentNode runAction:action completion:completion];
}

- (SKAction *)actionForScrollContentLocation:(CGPoint)contentLocation
                              toNodeLocation:(CGPoint)nodeLocation
                            animatedDuration:(NSTimeInterval)duration
{
  if (!_contentNode) {
    return nil;
  }
  // note: Use similar mechanics as setContentOffset:animatedDuration:completion:.
  CGFloat constrainedScale = _contentNode.xScale;
  CGPoint contentOffset = CGPointMake(nodeLocation.x - contentLocation.x * constrainedScale,
                                      nodeLocation.y - contentLocation.y * constrainedScale);
  CGPoint constrainedPosition = [self HL_contentConstrainedPositionX:contentOffset.x positionY:contentOffset.y scale:constrainedScale];
  return [SKAction moveTo:constrainedPosition duration:duration];
}

- (void)scrollContentLocation:(CGPoint)contentLocation
               toNodeLocation:(CGPoint)nodeLocation
           andSetContentScale:(CGFloat)contentScale
{
  if (!_contentNode) {
    _contentScaleOffline = contentScale;
    return;
  }
  // note: Use similar mechanics as setContentOffset:contentScale:.
  CGFloat constrainedScale = [self HL_contentConstrainedScale:contentScale];
  _contentNode.xScale = constrainedScale;
  _contentNode.yScale = constrainedScale;
  CGPoint contentOffset = CGPointMake(nodeLocation.x - contentLocation.x * constrainedScale,
                                      nodeLocation.y - contentLocation.y * constrainedScale);
  _contentNode.position = [self HL_contentConstrainedPositionX:contentOffset.x positionY:contentOffset.y scale:constrainedScale];
}

- (void)scrollContentLocation:(CGPoint)contentLocation
               toNodeLocation:(CGPoint)nodeLocation
           andSetContentScale:(CGFloat)contentScale
             animatedDuration:(NSTimeInterval)duration
                   completion:(void (^)(void))completion
{
  SKAction *action = [self actionForScrollContentLocation:contentLocation toNodeLocation:nodeLocation andSetContentScale:contentScale animatedDuration:duration];
  if (!action) {
    _contentScaleOffline = contentScale;
    return;
  }
  action.timingMode = SKActionTimingEaseInEaseOut;
  [_contentNode runAction:action completion:completion];
}

- (SKAction *)actionForScrollContentLocation:(CGPoint)contentLocation
                              toNodeLocation:(CGPoint)nodeLocation
                          andSetContentScale:(CGFloat)contentScale
                            animatedDuration:(NSTimeInterval)duration
{
  if (!_contentNode) {
    return nil;
  }
  // note: Use similar mechanics as setContentOffset:contentScale:animatedDuration:completion:.
  CGFloat startConstrainedScale = _contentNode.xScale;
  CGFloat endConstrainedScale = [self HL_contentConstrainedScale:contentScale];
  CGPoint startConstrainedPosition = _contentNode.position;
  CGPoint endConstrainedPosition = [self HL_contentConstrainedPositionX:(nodeLocation.x - contentLocation.x * endConstrainedScale)
                                                              positionY:(nodeLocation.y - contentLocation.y * endConstrainedScale)
                                                                  scale:endConstrainedScale];
  return [SKAction customActionWithDuration:duration actionBlock:^(SKNode *node, CGFloat elapsedTime){
    CGFloat elapsedProportion = (CGFloat)(elapsedTime / duration);
    CGFloat interpolatedScale = startConstrainedScale + (endConstrainedScale - startConstrainedScale) * elapsedProportion;
    self->_contentNode.xScale = interpolatedScale;
    self->_contentNode.yScale = interpolatedScale;
    CGPoint interpolatedPosition = CGPointMake(startConstrainedPosition.x + (endConstrainedPosition.x - startConstrainedPosition.x) * elapsedProportion,
                                               startConstrainedPosition.y + (endConstrainedPosition.y - startConstrainedPosition.y) * elapsedProportion);
    // note: Here the interpolatedPosition might not be constrained correctly for the current (interpolated)
    // scale.  But like setContentOffset:contentScale:animatedDuration:completion:, we allow intermediate
    // illegal position values in order to make a smoother animation.
    //self->_contentNode.position = [self HL_contentConstrainedPositionX:interpolatedPosition.x positionY:interpolatedPosition.y scale:interpolatedScale];
    self->_contentNode.position = interpolatedPosition;
  }];
}

- (void)pinContentLocation:(CGPoint)contentLocation andSetContentScale:(CGFloat)contentScale
{
  if (!_contentNode) {
    _contentScaleOffline = contentScale;
    return;
  }
  // note: Use similar mechanics as setContentOffset:contentScale:.
  CGFloat startConstrainedScale = _contentNode.xScale;
  CGFloat endConstrainedScale = [self HL_contentConstrainedScale:contentScale];
  CGPoint startConstrainedPosition = _contentNode.position;
  CGPoint nodeLocation = CGPointMake(startConstrainedPosition.x + contentLocation.x * startConstrainedScale,
                                     startConstrainedPosition.y + contentLocation.y * startConstrainedScale);
  _contentNode.xScale = endConstrainedScale;
  _contentNode.yScale = endConstrainedScale;
  _contentNode.position = [self HL_contentConstrainedPositionX:(nodeLocation.x - contentLocation.x * endConstrainedScale)
                                                     positionY:(nodeLocation.y - contentLocation.y * endConstrainedScale)
                                                         scale:endConstrainedScale];
}

- (void)pinContentLocation:(CGPoint)contentLocation
        andSetContentScale:(CGFloat)contentScale
          animatedDuration:(NSTimeInterval)duration
                completion:(void (^)(void))completion
{
  SKAction *action = [self actionForPinContentLocation:contentLocation andSetContentScale:contentScale animatedDuration:duration];
  if (!action) {
    _contentScaleOffline = contentScale;
    return;
  }
  action.timingMode = SKActionTimingEaseInEaseOut;
  [_contentNode runAction:action completion:completion];
}

- (SKAction *)actionForPinContentLocation:(CGPoint)contentLocation
                       andSetContentScale:(CGFloat)contentScale
                         animatedDuration:(NSTimeInterval)duration
{
  if (!_contentNode) {
    return nil;
  }
  // note: Use similar mechanics as setContentOffset:contentScale:animatedDuration:completion:.
  CGFloat startConstrainedScale = _contentNode.xScale;
  CGFloat endConstrainedScale = [self HL_contentConstrainedScale:contentScale];
  CGPoint startConstrainedPosition = _contentNode.position;
  CGPoint nodeLocation = CGPointMake(startConstrainedPosition.x + contentLocation.x * startConstrainedScale,
                                     startConstrainedPosition.y + contentLocation.y * startConstrainedScale);
  CGPoint endConstrainedPosition = [self HL_contentConstrainedPositionX:(nodeLocation.x - contentLocation.x * endConstrainedScale)
                                                              positionY:(nodeLocation.y - contentLocation.y * endConstrainedScale)
                                                                  scale:endConstrainedScale];
  return [SKAction customActionWithDuration:duration actionBlock:^(SKNode *node, CGFloat elapsedTime){
    CGFloat elapsedProportion = (CGFloat)(elapsedTime / duration);
    CGFloat interpolatedScale = startConstrainedScale + (endConstrainedScale - startConstrainedScale) * elapsedProportion;
    self->_contentNode.xScale = interpolatedScale;
    self->_contentNode.yScale = interpolatedScale;
    // note: Three options (?) here:
    // Could find intermediate positions by calculating them from nodePosition and contentLocation and contraining:
    //self->_contentNode.position = [self HL_contentConstrainedPositionX:(nodeLocation.x - contentLocation.x * interpolatedScale)
    //                                                         positionY:(nodeLocation.y - contentLocation.y * interpolatedScale)
    //                                                             scale:interpolatedScale];
    // But, as elsewhere, that can make things a little jerky.  One smoother way to do it is to skip the constraint:
    //self->_contentNode.position = CGPointMake(nodeLocation.x - contentLocation.x * interpolatedScale,
    //                                          nodeLocation.y - contentLocation.y * interpolatedScale);
    // But then the final position needs to be constrained.  The best result seems to be doing it the same way as
    // other scroll-and-scales: Pre-calculating a final constrained position and doing a straightforward (non-constrained)
    // interpolation.
    CGPoint interpolatedPosition = CGPointMake(startConstrainedPosition.x + (endConstrainedPosition.x - startConstrainedPosition.x) * elapsedProportion,
                                               startConstrainedPosition.y + (endConstrainedPosition.y - startConstrainedPosition.y) * elapsedProportion);
    self->_contentNode.position = interpolatedPosition;
  }];
}

#pragma mark -
#pragma mark HLGestureTarget

- (NSArray *)addsToGestureRecognizers
{
#if TARGET_OS_IPHONE
  return @[ [[UIPanGestureRecognizer alloc] init],
            [[UIPinchGestureRecognizer alloc] init] ];
#else
  return @[ [[NSPanGestureRecognizer alloc] init],
            [[NSMagnificationGestureRecognizer alloc] init] ];
#endif
}

- (BOOL)addToGesture:(HLGestureRecognizer *)gestureRecognizer firstLocation:(CGPoint)sceneLocation isInside:(BOOL *)isInside
{
  // note: The content might extend beyond the boundaries of the scroll node.  If a gesture
  // starts in this extended area, a gesture handler like HLScene might ask us if we'd like
  // to be the target for the gesture.  Whether we're clipping content or not, it seems like
  // the answer should be "no".
  CGPoint locationInSelf = [self convertPoint:sceneLocation fromNode:self.scene];
  if (locationInSelf.x < _size.width * -_anchorPoint.x
      || locationInSelf.x > _size.width * (1.0f - _anchorPoint.x)
      || locationInSelf.y < _size.height * -_anchorPoint.y
      || locationInSelf.y > _size.height * (1.0f - _anchorPoint.y)) {
    *isInside = NO;
    return NO;
  }

#if TARGET_OS_IPHONE
  if (HLGestureTarget_areEquivalentGestureRecognizers(gestureRecognizer, [[UIPanGestureRecognizer alloc] init])) {
    [gestureRecognizer addTarget:self action:@selector(handlePan:)];
    *isInside = YES;
    [self HL_scrollStart:locationInSelf];
    return YES;
  } else if (HLGestureTarget_areEquivalentGestureRecognizers(gestureRecognizer, [[UIPinchGestureRecognizer alloc] init])) {
    [gestureRecognizer addTarget:self action:@selector(handlePinch:)];
    *isInside = YES;
    return YES;
  }
#else
  if (HLGestureTarget_areEquivalentGestureRecognizers(gestureRecognizer, [[NSPanGestureRecognizer alloc] init])) {
    [gestureRecognizer addTarget:self action:@selector(handlePan:)];
    *isInside = YES;
    [self HL_scrollStart:locationInSelf];
    return YES;
  }
  if (HLGestureTarget_areEquivalentGestureRecognizers(gestureRecognizer, [[NSMagnificationGestureRecognizer alloc] init])) {
    [gestureRecognizer addTarget:self action:@selector(handlePinch:)];
    *isInside = YES;
    return YES;
  }
#endif

  *isInside = NO;
  return NO;
}

- (void)handlePan:(HLGestureRecognizer *)gestureRecognizer
{
  if (!_contentNode) {
    return;
  }

#if TARGET_OS_IPHONE
  if (gestureRecognizer.state == UIGestureRecognizerStateEnded
      || gestureRecognizer.state == UIGestureRecognizerStateCancelled) {
    return;
  }
#else
  if (gestureRecognizer.state == NSGestureRecognizerStateEnded
      || gestureRecognizer.state == NSGestureRecognizerStateCancelled) {
    return;
  }
#endif

  // note: The pan doesn't begin (UIGestureRecgonizerStateBegan) until there is already
  // movement from the original touch location.  I think translationInView accounts for
  // this, but I track my own translation (so that the conversion from view to node
  // coordinate systems is done by convertPointFromView and convertPoint:fromNode).  So
  // call HL_scrollStart from addToGesture:firstTouch:isInside:, starting the pan from
  // there.  For UIGestureRecognizerStateBegan, we update it.

  CGPoint viewLocation = [gestureRecognizer locationInView:self.scene.view];
  CGPoint sceneLocation = [self.scene convertPointFromView:viewLocation];
  CGPoint nodeLocation = [self convertPoint:sceneLocation fromNode:self.scene];
  [self HL_scrollUpdate:nodeLocation];
}

- (void)handlePinch:(HLGestureRecognizer *)gestureRecognizer
{
  if (!_contentNode) {
    return;
  }

#if TARGET_OS_IPHONE

  if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
    CGPoint viewLocation = [gestureRecognizer locationInView:self.scene.view];
    CGPoint sceneLocation = [self.scene convertPointFromView:viewLocation];
    CGPoint nodeLocation = [self convertPoint:sceneLocation fromNode:self.scene];
    [self HL_zoomStart:nodeLocation];
  } else if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {
    CGFloat scale = ((UIPinchGestureRecognizer *)gestureRecognizer).scale;
    [self HL_zoomUpdate:scale];
  }

#else

  if (gestureRecognizer.state == NSGestureRecognizerStateBegan) {
    CGPoint viewLocation = [gestureRecognizer locationInView:self.scene.view];
    CGPoint sceneLocation = [self.scene convertPointFromView:viewLocation];
    CGPoint nodeLocation = [self convertPoint:sceneLocation fromNode:self.scene];
    [self HL_zoomStart:nodeLocation];
  } else if (gestureRecognizer.state == NSGestureRecognizerStateChanged) {
    CGFloat scale = 1.0f + ((NSMagnificationGestureRecognizer *)gestureRecognizer).magnification;
    [self HL_zoomUpdate:scale];
  }

#endif
}

#if TARGET_OS_IPHONE

#pragma mark -
#pragma mark UIResponder

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
  [self HL_touchesBeganOrEndedWithEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
  NSSet *allTouches = [event allTouches];
  NSUInteger allTouchesCount = [allTouches count];

  if (allTouchesCount == 1) {

    UITouch *touch = [touches anyObject];
    CGPoint viewLocation = [touch locationInView:self.scene.view];
    CGPoint sceneLocation = [self.scene convertPointFromView:viewLocation];
    CGPoint nodeLocation = [self convertPoint:sceneLocation fromNode:self.scene];
    [self HL_scrollUpdate:nodeLocation];

  } else if (allTouchesCount == 2) {

    NSArray *allTouchesArray = [allTouches allObjects];

    UITouch *touch0 = allTouchesArray[0];
    CGPoint viewLocation0 = [touch0 locationInView:self.scene.view];
    CGPoint sceneLocation0 = [self.scene convertPointFromView:viewLocation0];
    CGPoint nodeLocation0 = [self convertPoint:sceneLocation0 fromNode:self.scene];

    UITouch *touch1 = allTouchesArray[1];
    CGPoint viewLocation1 = [touch1 locationInView:self.scene.view];
    CGPoint sceneLocation1 = [self.scene convertPointFromView:viewLocation1];
    CGPoint nodeLocation1 = [self convertPoint:sceneLocation1 fromNode:self.scene];

    CGFloat touchesNodeDistance = (CGFloat)sqrt((nodeLocation0.x - nodeLocation1.x) * (nodeLocation0.x - nodeLocation1.x)
                                                + (nodeLocation0.y - nodeLocation1.y) * (nodeLocation0.y - nodeLocation1.y));
    CGFloat scale = touchesNodeDistance / _touchesOriginalNodeDistance;

    [self HL_zoomUpdate:scale];
  }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
  [self HL_touchesBeganOrEndedWithEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
  [self HL_touchesBeganOrEndedWithEvent:event];
}

- (void)HL_touchesBeganOrEndedWithEvent:(UIEvent *)event
{
  // note: When there is one touch, we're scrolling; two touches, we're zooming.
  // When the number of touches change (whether increase or decrease), our action
  // needs to reset itself based on current location.

  NSSet *allTouches = [event allTouches];
  NSUInteger allTouchesCount = [allTouches count];

  if (allTouchesCount == 1) {

    UITouch *touch = [allTouches anyObject];
    CGPoint viewLocation = [touch locationInView:self.scene.view];
    CGPoint sceneLocation = [self.scene convertPointFromView:viewLocation];
    CGPoint nodeLocation = [self convertPoint:sceneLocation fromNode:self.scene];
    [self HL_scrollStart:nodeLocation];

  } else if (allTouchesCount == 2) {

    NSArray *allTouchesArray = [allTouches allObjects];

    UITouch *touch0 = allTouchesArray[0];
    CGPoint viewLocation0 = [touch0 locationInView:self.scene.view];
    CGPoint sceneLocation0 = [self.scene convertPointFromView:viewLocation0];
    CGPoint nodeLocation0 = [self convertPoint:sceneLocation0 fromNode:self.scene];

    UITouch *touch1 = allTouchesArray[1];
    CGPoint viewLocation1 = [touch1 locationInView:self.scene.view];
    CGPoint sceneLocation1 = [self.scene convertPointFromView:viewLocation1];
    CGPoint nodeLocation1 = [self convertPoint:sceneLocation1 fromNode:self.scene];

    _touchesOriginalNodeDistance = (CGFloat)sqrt((nodeLocation0.x - nodeLocation1.x) * (nodeLocation0.x - nodeLocation1.x)
                                                 + (nodeLocation0.y - nodeLocation1.y) * (nodeLocation0.y - nodeLocation1.y));

    CGPoint centerNodeLocation;
    centerNodeLocation.x = (nodeLocation0.x + nodeLocation1.x) / 2.0f;
    centerNodeLocation.y = (nodeLocation0.y + nodeLocation1.y) / 2.0f;

    [self HL_zoomStart:centerNodeLocation];
  }
}

#else

#pragma mark -
#pragma mark NSResponder

- (void)mouseDown:(NSEvent *)event
{
  CGPoint nodeLocation = [event locationInNode:self];
  [self HL_scrollStart:nodeLocation];
}

- (void)mouseDragged:(NSEvent *)event
{
  if (!_contentNode) {
    return;
  }
  CGPoint nodeLocation = [event locationInNode:self];
  [self HL_scrollUpdate:nodeLocation];
}

#endif

#pragma mark -
#pragma mark Private

- (CGPoint)HL_contentConstrainedPositionX:(CGFloat)positionX positionY:(CGFloat)positionY scale:(CGFloat)scale
{
  CGFloat contentWidthScaled = _contentSize.width * scale;
  CGFloat positionXMax = _size.width * -1.0f * _anchorPoint.x - contentWidthScaled * -1.0f * _contentAnchorPoint.x + _contentInset.left;
  CGFloat positionXMin = _size.width * (1.0f - _anchorPoint.x) - contentWidthScaled * (1.0f - _contentAnchorPoint.x) - _contentInset.right;
  if (positionXMax < positionXMin) {
    // note: Only happens in the tighter dimension if HLScrollNodeContentMinimumModeFitLoose,
    // or if contentSize too small to fill scroll node at maximum scale.
    positionX = positionXMin + (positionXMax - positionXMin) * (1.0f - _contentAnchorPoint.x);
  } else if (positionX < positionXMin) {
    positionX = positionXMin;
  } else if (positionX > positionXMax) {
    positionX = positionXMax;
  }
  CGFloat contentHeightScaled = _contentSize.height * scale;
  CGFloat positionYMax = _size.height * -1.0f * _anchorPoint.y - contentHeightScaled * -1.0f * _contentAnchorPoint.y + _contentInset.bottom;
  CGFloat positionYMin = _size.height * (1.0f - _anchorPoint.y) - contentHeightScaled * (1.0f - _contentAnchorPoint.y) - _contentInset.top;
  if (positionYMax < positionYMin) {
    // note: Only happens in the tighter dimension if HLScrollNodeContentMinimumModeFitLoose,
    // or if contentSize too small to fill scroll node at maximum scale.
    positionY = positionYMin + (positionYMax - positionYMin) * (1.0f - _contentAnchorPoint.y);
  } else if (positionY < positionYMin) {
    positionY = positionYMin;
  } else if (positionY > positionYMax) {
    positionY = positionYMax;
  }
  return CGPointMake(positionX, positionY);
}

- (CGFloat)HL_contentConstrainedScale:(CGFloat)scale
{
  switch (_contentScaleMinimumMode) {
    case HLScrollNodeContentScaleMinimumFitTight: {
      CGFloat naturalScaleMin = MAX((_size.width - _contentInset.left - _contentInset.right) / _contentSize.width,
                                    (_size.height - _contentInset.top - _contentInset.bottom) / _contentSize.height);
      CGFloat combinedScaleMin = MAX(_contentScaleMinimum, naturalScaleMin);
      if (scale < combinedScaleMin) {
        scale = combinedScaleMin;
      }
      break;
    }
    case HLScrollNodeContentScaleMinimumFitLoose: {
      CGFloat naturalScaleMin = MIN((_size.width - _contentInset.left - _contentInset.right) / _contentSize.width,
                                    (_size.height - _contentInset.top - _contentInset.bottom) / _contentSize.height);
      CGFloat combinedScaleMin = MAX(_contentScaleMinimum, naturalScaleMin);
      if (scale < combinedScaleMin) {
        scale = combinedScaleMin;
      }
      break;
    }
    case HLScrollNodeContentScaleMinimumAsConfigured:
      if (scale < _contentScaleMinimum) {
        scale = _contentScaleMinimum;
      }
      break;
  }

  if (scale > _contentScaleMaximum) {
    scale = _contentScaleMaximum;
  }

  return scale;
}

- (void)HL_scrollStart:(CGPoint)nodeLocation
{
  _scrollLastNodeLocation = nodeLocation;
}

- (void)HL_scrollUpdate:(CGPoint)nodeLocation
{
  CGPoint translationInNode = CGPointMake(nodeLocation.x - _scrollLastNodeLocation.x,
                                          nodeLocation.y - _scrollLastNodeLocation.y);
  _contentNode.position = [self HL_contentConstrainedPositionX:(_contentNode.position.x + translationInNode.x)
                                                     positionY:(_contentNode.position.y + translationInNode.y)
                                                         scale:_contentNode.xScale];
  _scrollLastNodeLocation = nodeLocation;

  id <HLScrollNodeDelegate> delegate = _delegate;
  if (delegate && [delegate respondsToSelector:@selector(scrollNode:didScrollToContentOffset:)]) {
    [delegate scrollNode:self didScrollToContentOffset:_contentNode.position];
  }
}

- (void)HL_zoomStart:(CGPoint)centerNodeLocation
{
  // note: The idea is that we pin the HLScrollNode and content together at a point (call it
  // the center point of the gesture or event as it starts), and they will remained pinned
  // together at that point throughout the gesture or event (if possible).
  _zoomPinNodeLocation = centerNodeLocation;
  CGPoint contentPosition = _contentNode.position;
  _zoomOriginalContentScale = _contentNode.xScale;
  _zoomPinContentLocation = CGPointMake((_zoomPinNodeLocation.x - contentPosition.x) / _zoomOriginalContentScale,
                                         (_zoomPinNodeLocation.y - contentPosition.y) / _zoomOriginalContentScale);
}

- (void)HL_zoomUpdate:(CGFloat)scale
{
  CGFloat constrainedScale = [self HL_contentConstrainedScale:(scale * _zoomOriginalContentScale)];
  _contentNode.xScale = constrainedScale;
  _contentNode.yScale = constrainedScale;
  _contentNode.position = [self HL_contentConstrainedPositionX:(_zoomPinNodeLocation.x - _zoomPinContentLocation.x * constrainedScale)
                                                     positionY:(_zoomPinNodeLocation.y - _zoomPinContentLocation.y * constrainedScale)
                                                         scale:constrainedScale];

  id <HLScrollNodeDelegate> delegate = _delegate;
  if (delegate && [delegate respondsToSelector:@selector(scrollNode:didZoomToContentScale:)]) {
    [delegate scrollNode:self didZoomToContentScale:_contentNode.xScale];
  }
}

@end
