//
//  HLGestureTarget.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 7/10/14.
//  Copyright (c) 2014 Hilo. All rights reserved.
//

#import "HLGestureTarget.h"

BOOL
HLGestureTarget_areEquivalentGestureRecognizers(UIGestureRecognizer *a, UIGestureRecognizer *b)
{
  Class classA = [a class];
  if (classA != [b class]) {
    return NO;
  }

  if (classA == [UITapGestureRecognizer class]) {
    UITapGestureRecognizer *tapA = (UITapGestureRecognizer *)a;
    UITapGestureRecognizer *tapB = (UITapGestureRecognizer *)b;
    if (tapA.numberOfTapsRequired != tapB.numberOfTapsRequired) {
      return NO;
    }
    if (tapA.numberOfTouchesRequired != tapB.numberOfTouchesRequired) {
      return NO;
    }
    return YES;
  }
  
  if (classA == [UISwipeGestureRecognizer class]) {
    UISwipeGestureRecognizer *swipeA = (UISwipeGestureRecognizer *)a;
    UISwipeGestureRecognizer *swipeB = (UISwipeGestureRecognizer *)b;
    if (swipeA.direction != swipeB.direction) {
      return NO;
    }
    if (swipeA.numberOfTouchesRequired != swipeB.numberOfTouchesRequired) {
      return NO;
    }
    return YES;
  }

  if (classA == [UIPanGestureRecognizer class]) {
    UIPanGestureRecognizer *panA = (UIPanGestureRecognizer *)a;
    UIPanGestureRecognizer *panB = (UIPanGestureRecognizer *)b;
    if (panA.minimumNumberOfTouches != panB.minimumNumberOfTouches) {
      return NO;
    }
    if (panA.maximumNumberOfTouches != panB.maximumNumberOfTouches) {
      return NO;
    }
    return YES;
  }

  if (classA == [UIScreenEdgePanGestureRecognizer class]) {
    UIScreenEdgePanGestureRecognizer *screenEdgePanA = (UIScreenEdgePanGestureRecognizer *)a;
    UIScreenEdgePanGestureRecognizer *screenEdgePanB = (UIScreenEdgePanGestureRecognizer *)b;
    if (screenEdgePanA.edges != screenEdgePanB.edges) {
      return NO;
    }
    return YES;
  }
  
  if (classA == [UILongPressGestureRecognizer class]) {
    UILongPressGestureRecognizer *longPressA = (UILongPressGestureRecognizer *)a;
    UILongPressGestureRecognizer *longPressB = (UILongPressGestureRecognizer *)b;
    if (longPressA.numberOfTapsRequired != longPressB.numberOfTapsRequired) {
      return NO;
    }
    if (longPressA.numberOfTouchesRequired != longPressB.numberOfTouchesRequired) {
      return NO;
    }
    const CFTimeInterval HLGestureTargetLongPressMinimumPressDurationEpsilon = 0.01;
    if (fabs(longPressA.minimumPressDuration - longPressB.minimumPressDuration) > HLGestureTargetLongPressMinimumPressDurationEpsilon) {
      return NO;
    }
    const CGFloat HLGestureTargetLongPressAllowableMovementEpsilon = 0.1f;
    if (fabs(longPressA.allowableMovement - longPressB.allowableMovement) > HLGestureTargetLongPressAllowableMovementEpsilon) {
      return NO;
    }
    return YES;
  }
  return YES;
}

@implementation HLGestureTargetTapDelegate

- (instancetype)initWithHandleGestureBlock:(void (^)(UIGestureRecognizer *))handleGestureBlock
{
  self = [super init];
  if (self) {
    _handleGestureBlock = handleGestureBlock;
    _gestureTransparent = NO;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super init];
  if (self) {
    // note: Cannot decode _handleGestureBlock.
    _gestureTransparent = [aDecoder decodeBoolForKey:@"gestureTransparent"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  // note: Cannot encode _handleGestureBlock.
  [aCoder encodeBool:_gestureTransparent forKey:@"gestureTransparent"];
}

- (BOOL)addToGesture:(UIGestureRecognizer *)gestureRecognizer firstTouch:(UITouch *)touch isInside:(BOOL *)isInside
{
  BOOL handleGesture = NO;

  if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
    UITapGestureRecognizer *tapGestureRecognizer = (UITapGestureRecognizer *)gestureRecognizer;
    if (tapGestureRecognizer.numberOfTapsRequired == 1) {
      *isInside = YES;
      handleGesture = YES;
    }
  }

  *isInside = !_gestureTransparent;
  if (handleGesture) {
    [gestureRecognizer addTarget:self action:@selector(HLGestureTargetTapDelegate_handleGesture:)];
  }
  return handleGesture;
}

- (NSArray *)addsToGestureRecognizers
{
  return @[ [[UITapGestureRecognizer alloc] init] ];
}

- (void)HLGestureTargetTapDelegate_handleGesture:(UIGestureRecognizer *)gestureRecognizer
{
  if (_handleGestureBlock) {
    _handleGestureBlock(gestureRecognizer);
  }
}

@end

@implementation HLGestureTargetNode {
  __weak id <HLGestureTargetDelegate> _gestureTargetDelegateWeak;
  id <HLGestureTargetDelegate> _gestureTargetDelegateStrong;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self) {
    _gestureTargetDelegateWeak = [aDecoder decodeObjectForKey:@"gestureTargetDelegateWeak"];
    _gestureTargetDelegateStrong = [aDecoder decodeObjectForKey:@"gestureTargetDelegateStrong"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [super encodeWithCoder:aCoder];
  [aCoder encodeObject:_gestureTargetDelegateWeak forKey:@"gestureTargetDelegateWeak"];
  [aCoder encodeObject:_gestureTargetDelegateStrong forKey:@"gestureTargetDelegateStrong"];
}

- (void)setGestureTargetDelegateWeak:(id<HLGestureTargetDelegate>)delegate
{
  _gestureTargetDelegateWeak = delegate;
  _gestureTargetDelegateStrong = nil;
}

- (void)setGestureTargetDelegateStrong:(id<HLGestureTargetDelegate>)delegate
{
  _gestureTargetDelegateStrong = delegate;
  _gestureTargetDelegateWeak = nil;
}

- (id<HLGestureTargetDelegate>)gestureTargetDelegate
{
  if (_gestureTargetDelegateWeak) {
    return _gestureTargetDelegateWeak;
  } else {
    return _gestureTargetDelegateStrong;
  }
}

@end

@implementation HLGestureTargetSpriteNode {
  __weak id <HLGestureTargetDelegate> _gestureTargetDelegateWeak;
  id <HLGestureTargetDelegate> _gestureTargetDelegateStrong;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self) {
    _gestureTargetDelegateWeak = [aDecoder decodeObjectForKey:@"gestureTargetDelegateWeak"];
    _gestureTargetDelegateStrong = [aDecoder decodeObjectForKey:@"gestureTargetDelegateStrong"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [super encodeWithCoder:aCoder];
  [aCoder encodeObject:_gestureTargetDelegateWeak forKey:@"gestureTargetDelegateWeak"];
  [aCoder encodeObject:_gestureTargetDelegateStrong forKey:@"gestureTargetDelegateStrong"];
}

- (void)setGestureTargetDelegateWeak:(id<HLGestureTargetDelegate>)delegate
{
  _gestureTargetDelegateWeak = delegate;
  _gestureTargetDelegateStrong = nil;
}

- (void)setGestureTargetDelegateStrong:(id<HLGestureTargetDelegate>)delegate
{
  _gestureTargetDelegateStrong = delegate;
  _gestureTargetDelegateWeak = nil;
}

- (id<HLGestureTargetDelegate>)gestureTargetDelegate
{
  if (_gestureTargetDelegateWeak) {
    return _gestureTargetDelegateWeak;
  } else {
    return _gestureTargetDelegateStrong;
  }
}

@end
