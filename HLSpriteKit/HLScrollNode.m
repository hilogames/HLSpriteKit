//
//  HLScrollNode.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 10/20/14.
//  Copyright (c) 2014 Hilo. All rights reserved.
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
  CGFloat _pinchOriginalContentScale;
  CGPoint _pinchOriginalContentPosition;
  CGPoint _pinchCenterNodeLocation;
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
  _contentNode.position = [self HL_contentConstrainedPositionX:_contentNode.position.x positionY:_contentNode.position.y];
}

- (void)setAnchorPoint:(CGPoint)anchorPoint
{
  _anchorPoint = anchorPoint;
  if (!_contentNode) {
    return;
  }
  _contentNode.position = [self HL_contentConstrainedPositionX:_contentNode.position.x positionY:_contentNode.position.y];
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

    CGFloat zPositionLayerSize = self.zPositionScale / HLScrollNodeZPositionLayerCount;
    _contentNode.zPosition = HLScrollNodeZPositionLayerContent * zPositionLayerSize;
    if ([_contentNode isKindOfClass:[HLComponentNode class]]) {
      [(HLComponentNode *)_contentNode setZPositionScale:zPositionLayerSize];
    }

    CGFloat constrainedScale = [self HL_contentConstrainedScale:_contentScaleOffline];
    _contentNode.xScale = constrainedScale;
    _contentNode.yScale = constrainedScale;
    _contentNode.position = [self HL_contentConstrainedPositionX:_contentOffsetOffline.x positionY:_contentOffsetOffline.y];
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
  _contentNode.position = [self HL_contentConstrainedPositionX:_contentNode.position.x positionY:_contentNode.position.y];
}

- (void)setContentAnchorPoint:(CGPoint)contentAnchorPoint
{
  _contentAnchorPoint = contentAnchorPoint;
  if (!_contentNode) {
    return;
  }
  _contentNode.position = [self HL_contentConstrainedPositionX:_contentNode.position.x positionY:_contentNode.position.y];
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
  _contentNode.position = [self HL_contentConstrainedPositionX:contentOffset.x positionY:contentOffset.y];
}

- (void)setContentOffset:(CGPoint)contentOffset animatedDuration:(NSTimeInterval)duration completion:(void (^)(void))completion
{
  if (!_contentNode) {
    _contentOffsetOffline = contentOffset;
    return;
  }
  // note: Assume it is acceptable to constrain position once rather than continually during animation.
  // One example how that might not be acceptable: If the caller expects the movement to take less
  // than the full animation duration if constrained.
  CGPoint constrainedPosition = [self HL_contentConstrainedPositionX:contentOffset.x positionY:contentOffset.y];
  SKAction *moveTo = [SKAction moveTo:constrainedPosition duration:duration];
  moveTo.timingMode = SKActionTimingEaseInEaseOut;
  [_contentNode runAction:moveTo completion:completion];
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
  _contentNode.position = [self HL_contentConstrainedPositionX:_contentNode.position.x positionY:_contentNode.position.y];
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
  _contentNode.position = [self HL_contentConstrainedPositionX:_contentNode.position.x positionY:_contentNode.position.y];
}

- (void)setContentScale:(CGFloat)contentScale animatedDuration:(NSTimeInterval)duration completion:(void (^)(void))completion
{
  if (!_contentNode) {
    _contentScaleOffline = contentScale;
    return;
  }
  // note: Assume it is acceptable to constrain scale once rather than continually during animation.
  // Position, however, must be continually constrained based on interpolated scale values.
  CGFloat constrainedScale = [self HL_contentConstrainedScale:contentScale];
  // note: Remember original position and keep trying to get back to it throughout the animation.
  // An alternate implementation could calculate the constrained final position based on the
  // constrained final scale, and then head there smoothly throughout the animation.
  CGPoint constrainedPosition = _contentNode.position;
  SKAction *scaleTo = [SKAction customActionWithDuration:duration actionBlock:^(SKNode *node, CGFloat elapsedTime){
    CGFloat interpolatedScale = constrainedScale * (CGFloat)(elapsedTime / duration);
    self->_contentNode.xScale = interpolatedScale;
    self->_contentNode.yScale = interpolatedScale;
    self->_contentNode.position = [self HL_contentConstrainedPositionX:constrainedPosition.x positionY:constrainedPosition.y];
  }];
  scaleTo.timingMode = SKActionTimingEaseInEaseOut;
  [_contentNode runAction:scaleTo completion:completion];
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
  _contentNode.position = [self HL_contentConstrainedPositionX:_contentNode.position.x positionY:_contentNode.position.y];
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
  _contentNode.position = [self HL_contentConstrainedPositionX:_contentNode.position.x positionY:_contentNode.position.y];
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

#pragma mark -
#pragma mark HLGestureTargetDelegate

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
                                                     positionY:(_contentNode.position.y + translationInNode.y)];
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
    _pinchCenterNodeLocation = [self convertPoint:sceneLocation fromNode:self.scene];
    _pinchOriginalContentPosition = _contentNode.position;
    _pinchOriginalContentScale = _contentNode.xScale;

  } else if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {

    CGFloat constrainedScale = [self HL_contentConstrainedScale:(gestureRecognizer.scale * _pinchOriginalContentScale)];
    _contentNode.xScale = constrainedScale;
    _contentNode.yScale = constrainedScale;
    CGFloat constrainedScaleFactor = constrainedScale / _pinchOriginalContentScale;
    _contentNode.position = [self HL_contentConstrainedPositionX:((_pinchOriginalContentPosition.x - _pinchCenterNodeLocation.x) * constrainedScaleFactor - _pinchCenterNodeLocation.x)
                                                       positionY:((_pinchOriginalContentPosition.y - _pinchCenterNodeLocation.y) * constrainedScaleFactor - _pinchCenterNodeLocation.y)];

  }

}

#pragma mark -
#pragma mark Private

- (CGPoint)HL_contentConstrainedPositionX:(CGFloat)positionX positionY:(CGFloat)positionY
{
  CGFloat contentWidthScaled = _contentSize.width * _contentNode.xScale;
  CGFloat positionXMax = _size.width * -1.0f * _anchorPoint.x - contentWidthScaled * -1.0f * self.contentAnchorPoint.x + _contentInset.left;
  CGFloat positionXMin = _size.width * (1.0f - _anchorPoint.x) - contentWidthScaled * (1.0f - self.contentAnchorPoint.x) - _contentInset.right;
  if (positionXMax < positionXMin) {
    // note: Only happens in the tighter dimension if HLScrollNodeContentMinimumModeFitLoose,
    // or if contentSize too small to fill scroll node at maximum scale.
    positionX = positionXMin + (positionXMax - positionXMin) / 2.0f;
  } else if (positionX < positionXMin) {
    positionX = positionXMin;
  } else if (positionX > positionXMax) {
    positionX = positionXMax;
  }
  CGFloat contentHeightScaled = _contentSize.height * _contentNode.yScale;
  CGFloat positionYMax = _size.height * -1.0f * _anchorPoint.y - contentHeightScaled * -1.0f * self.contentAnchorPoint.y + _contentInset.bottom;
  CGFloat positionYMin = _size.height * (1.0f - _anchorPoint.y) - contentHeightScaled * (1.0f - self.contentAnchorPoint.y) - _contentInset.top;
  if (positionYMax < positionYMin) {
    // note: Only happens in the tighter dimension if HLScrollNodeContentMinimumModeFitLoose,
    // or if contentSize too small to fill scroll node at maximum scale.
    positionY = positionYMin + (positionYMax - positionYMin) / 2.0f;
  } else if (positionY < positionYMin) {
    positionY = positionYMin;
  } else if (positionY > positionYMax) {
    positionY = positionYMax;
  }
  return CGPointMake(positionX, positionY);
}

- (CGFloat)HL_contentConstrainedScale:(CGFloat)scale
{
  if (scale > _contentScaleMaximum) {
    scale = _contentScaleMaximum;
  } else {
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
  }
  return scale;
}

@end
