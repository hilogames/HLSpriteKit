//
//  HLScrollNode.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 10/20/14.
//  Copyright (c) 2014 Hilo Games. All rights reserved.
//

#import "HLScrollNode.h"

enum {
  HLScrollNodeZPositionLayerBackground = 0,
  HLScrollNodeZPositionLayerContent,
  HLScrollNodeZPositionLayerCount
};

@implementation HLScrollNode
{
  CGPoint _contentOffsetOffline;
  CGFloat _contentScaleOffline;

  CGPoint _panLastNodeLocation;
  CGPoint _pinchPinContentLocation;
  CGPoint _pinchPinNodeLocation;
  CGFloat _pinchOriginalContentScale;
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
    _contentInset = UIEdgeInsetsZero;
    _contentScaleOffline = 1.0f;
    _contentScaleMinimum = 1.0f;
    _contentScaleMinimumMode = HLScrollNodeContentScaleMinimumFitTight;
    _contentScaleMaximum = 1.0f;
  }
  return self;
}

- (instancetype)initWithSize:(CGSize)size
                 anchorPoint:(CGPoint)anchorPoint
                     content:(SKNode *)contentNode
                 contentSize:(CGSize)contentSize
                 contentAnchorPoint:(CGPoint)contentAnchorPoint
               contentOffset:(CGPoint)contentOffset
                contentInset:(UIEdgeInsets)contentInset
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

    self.contentNode = contentNode;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  [NSException raise:@"HLCodingNotImplemented" format:@"Coding not implemented for this descendant of an NSCoding parent."];
  // note: Call [init] for the sake of the compiler trying to detect problems with designated initializers.
  return [self initWithSize:CGSizeZero contentSize:CGSizeZero];
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

- (void)setSize:(CGSize)size
{
  _size = size;
  if (!_contentNode) {
    return;
  }
  CGFloat constrainedScale = [self HL_contentConstrainedScale:_contentNode.xScale];
  _contentNode.xScale = constrainedScale;
  _contentNode.yScale = constrainedScale;
  _contentNode.position = [self HL_contentConstrainedPositionX:_contentNode.position.x positionY:_contentNode.position.y scale:constrainedScale];
}

- (void)setAnchorPoint:(CGPoint)anchorPoint
{
  _anchorPoint = anchorPoint;
  if (!_contentNode) {
    return;
  }
  _contentNode.position = [self HL_contentConstrainedPositionX:_contentNode.position.x positionY:_contentNode.position.y scale:_contentNode.xScale];
}

- (void)setZPositionScale:(CGFloat)zPositionScale
{
  [super setZPositionScale:zPositionScale];
  if (!_contentNode) {
    return;
  }
  CGFloat zPositionLayerSize = zPositionScale / HLScrollNodeZPositionLayerCount;
  _contentNode.zPosition = HLScrollNodeZPositionLayerContent * zPositionLayerSize;
  if ([_contentNode isKindOfClass:[HLComponentNode class]]) {
    [(HLComponentNode *)_contentNode setZPositionScale:zPositionLayerSize];
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

    [self addChild:_contentNode];

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

- (void)setContentInset:(UIEdgeInsets)contentInset
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
  return @[ [[UIPanGestureRecognizer alloc] init],
            [[UIPinchGestureRecognizer alloc] init] ];
}

- (BOOL)addToGesture:(UIGestureRecognizer *)gestureRecognizer firstTouch:(UITouch *)touch isInside:(BOOL *)isInside
{
  if (HLGestureTarget_areEquivalentGestureRecognizers(gestureRecognizer, [[UIPanGestureRecognizer alloc] init])) {
    [gestureRecognizer addTarget:self action:@selector(handlePan:)];
    *isInside = YES;
    _panLastNodeLocation = [touch locationInNode:self];
    return YES;
  } else if (HLGestureTarget_areEquivalentGestureRecognizers(gestureRecognizer, [[UIPinchGestureRecognizer alloc] init])) {
    [gestureRecognizer addTarget:self action:@selector(handlePinch:)];
    *isInside = YES;
    return YES;
  }
  *isInside = NO;
  return NO;
}

- (void)handlePan:(UIPanGestureRecognizer *)gestureRecognizer
{
  // noob: The pan doesn't begin until there is already movement from the original touch
  // location.  I think translationInView accounts for this, but I like tracking my own
  // translation so that the conversion from view to node coordinate systems is done by
  // convertPointFromView and convertPoint:fromNode.  So remember the first touch location
  // in addToGesture:firstTouch:isInside:, and start the pan from there.

  if (!_contentNode) {
    return;
  }

  if (gestureRecognizer.state == UIGestureRecognizerStateEnded
      || gestureRecognizer.state == UIGestureRecognizerStateCancelled) {
    return;
  }

  CGPoint viewLocation = [gestureRecognizer locationInView:self.scene.view];
  CGPoint sceneLocation = [self.scene convertPointFromView:viewLocation];
  CGPoint nodeLocation = [self convertPoint:sceneLocation fromNode:self.scene];
  CGPoint translationInNode = CGPointMake(nodeLocation.x - _panLastNodeLocation.x,
                                          nodeLocation.y - _panLastNodeLocation.y);
  _contentNode.position = [self HL_contentConstrainedPositionX:(_contentNode.position.x + translationInNode.x)
                                                     positionY:(_contentNode.position.y + translationInNode.y)
                                                         scale:_contentNode.xScale];
  _panLastNodeLocation = nodeLocation;
}

- (void)handlePinch:(UIPinchGestureRecognizer *)gestureRecognizer
{
  if (!_contentNode) {
    return;
  }

  if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {

    // note: The idea is that we pin the HLScrollNode and content together at a point (the
    // center point of the gesture as it starts), and they will remained pinned together at
    // that point throughout the gesture (if possible).
    CGPoint viewLocation = [gestureRecognizer locationInView:self.scene.view];
    CGPoint sceneLocation = [self.scene convertPointFromView:viewLocation];
    _pinchPinNodeLocation = [self convertPoint:sceneLocation fromNode:self.scene];
    CGPoint contentPosition = _contentNode.position;
    _pinchOriginalContentScale = _contentNode.xScale;
    _pinchPinContentLocation = CGPointMake((_pinchPinNodeLocation.x - contentPosition.x) / _pinchOriginalContentScale,
                                           (_pinchPinNodeLocation.y - contentPosition.y) / _pinchOriginalContentScale);

  } else if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {

    CGFloat constrainedScale = [self HL_contentConstrainedScale:(gestureRecognizer.scale * _pinchOriginalContentScale)];
    _contentNode.xScale = constrainedScale;
    _contentNode.yScale = constrainedScale;
    _contentNode.position = [self HL_contentConstrainedPositionX:(_pinchPinNodeLocation.x - _pinchPinContentLocation.x * constrainedScale)
                                                       positionY:(_pinchPinNodeLocation.y - _pinchPinContentLocation.y * constrainedScale)
                                                           scale:constrainedScale];

  }

}

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

@end
