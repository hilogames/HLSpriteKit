//
//  HLGestureTarget.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 7/10/14.
//  Copyright (c) 2014 Hilo Games. All rights reserved.
//

#import "HLGestureTarget.h"

BOOL
HLGestureTarget_areEquivalentGestureRecognizers(HLGestureRecognizer *a, HLGestureRecognizer *b)
{
  const CFTimeInterval HLGestureTargetLongPressMinimumPressDurationEpsilon = 0.01;
  const CGFloat HLGestureTargetLongPressAllowableMovementEpsilon = 0.1f;

  Class classA = [a class];
  if (classA != [b class]) {
    return NO;
  }

#if TARGET_OS_IPHONE

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
    if (fabs(longPressA.minimumPressDuration - longPressB.minimumPressDuration) > HLGestureTargetLongPressMinimumPressDurationEpsilon) {
      return NO;
    }
    if (fabs(longPressA.allowableMovement - longPressB.allowableMovement) > HLGestureTargetLongPressAllowableMovementEpsilon) {
      return NO;
    }
    return YES;
  }

#else

  if (classA == [NSClickGestureRecognizer class]) {
    NSClickGestureRecognizer *clickA = (NSClickGestureRecognizer *)a;
    NSClickGestureRecognizer *clickB = (NSClickGestureRecognizer *)b;
    if (clickA.numberOfClicksRequired != clickB.numberOfClicksRequired) {
      return NO;
    }
    return YES;
  }

  if (classA == [NSPressGestureRecognizer class]) {
    NSPressGestureRecognizer *pressA = (NSPressGestureRecognizer *)a;
    NSPressGestureRecognizer *pressB = (NSPressGestureRecognizer *)b;
    if (fabs(pressA.minimumPressDuration - pressB.minimumPressDuration) > HLGestureTargetLongPressMinimumPressDurationEpsilon) {
      return NO;
    }
    if (fabs(pressA.allowableMovement - pressB.allowableMovement) > HLGestureTargetLongPressAllowableMovementEpsilon) {
      return NO;
    }
    return YES;
  }

#endif

  return YES;
}

#if TARGET_OS_IPHONE

@implementation HLTapGestureTarget

+ (instancetype)tapGestureTargetWithDelegate:(id<HLTapGestureTargetDelegate>)delegate
{
  return [[HLTapGestureTarget alloc] initWithDelegate:delegate];
}

+ (instancetype)tapGestureTargetWithHandleGestureBlock:(void (^)(HLGestureRecognizer *))handleGestureBlock
{
  return [[HLTapGestureTarget alloc] initWithHandleGestureBlock:handleGestureBlock];
}

- (instancetype)initWithDelegate:(id<HLTapGestureTargetDelegate>)delegate
{
  self = [super init];
  if (self) {
    _delegate = delegate;
    _gestureTransparent = NO;
  }
  return self;
}

- (instancetype)initWithHandleGestureBlock:(void (^)(HLGestureRecognizer *))handleGestureBlock
{
  self = [super init];
  if (self) {
    _handleGestureBlock = handleGestureBlock;
    _gestureTransparent = NO;
  }
  return self;
}

- (instancetype)init
{
  self = [super init];
  if (self) {
    _gestureTransparent = NO;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super init];
  if (self) {
    _delegate = [aDecoder decodeObjectForKey:@"delegate"];
    // note: Cannot decode _handleGestureBlock.
    _gestureTransparent = [aDecoder decodeBoolForKey:@"gestureTransparent"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [aCoder encodeConditionalObject:_delegate forKey:@"delegate"];
  // note: Cannot encode _handleGestureBlock.
  [aCoder encodeBool:_gestureTransparent forKey:@"gestureTransparent"];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
  HLTapGestureTarget *copy = [[[self class] allocWithZone:zone] init];
  if (copy) {
    copy->_delegate = _delegate;
    copy->_handleGestureBlock = _handleGestureBlock;
    copy->_gestureTransparent = _gestureTransparent;
  }
  return self;
}

- (BOOL)addToGesture:(HLGestureRecognizer *)gestureRecognizer
       firstLocation:(CGPoint)sceneLocation
            isInside:(BOOL *)isInside
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
    [gestureRecognizer addTarget:self action:@selector(HLTapGestureTarget_handleGesture:)];
  }
  return handleGesture;
}

- (NSArray *)addsToGestureRecognizers
{
  return @[ [[UITapGestureRecognizer alloc] init] ];
}

- (void)HLTapGestureTarget_handleGesture:(HLGestureRecognizer *)gestureRecognizer
{
  id <HLTapGestureTargetDelegate> delegate = _delegate;
  if (delegate) {
    [delegate tapGestureTarget:self didTap:gestureRecognizer];
  }
  if (_handleGestureBlock) {
    _handleGestureBlock(gestureRecognizer);
  }
}

@end

#else

@implementation HLClickGestureTarget

+ (instancetype)clickGestureTargetWithDelegate:(id<HLClickGestureTargetDelegate>)delegate
{
  return [[HLClickGestureTarget alloc] initWithDelegate:delegate];
}

+ (instancetype)clickGestureTargetWithHandleGestureBlock:(void (^)(HLGestureRecognizer *))handleGestureBlock
{
  return [[HLClickGestureTarget alloc] initWithHandleGestureBlock:handleGestureBlock];
}

- (instancetype)initWithDelegate:(id<HLClickGestureTargetDelegate>)delegate
{
  self = [super init];
  if (self) {
    _delegate = delegate;
    _gestureTransparent = NO;
  }
  return self;
}

- (instancetype)initWithHandleGestureBlock:(void (^)(HLGestureRecognizer *))handleGestureBlock
{
  self = [super init];
  if (self) {
    _handleGestureBlock = handleGestureBlock;
    _gestureTransparent = NO;
  }
  return self;
}

- (instancetype)init
{
  self = [super init];
  if (self) {
    _gestureTransparent = NO;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super init];
  if (self) {
    _delegate = [aDecoder decodeObjectForKey:@"delegate"];
    // note: Cannot decode _handleGestureBlock.
    _gestureTransparent = [aDecoder decodeBoolForKey:@"gestureTransparent"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [aCoder encodeConditionalObject:_delegate forKey:@"delegate"];
  // note: Cannot encode _handleGestureBlock.
  [aCoder encodeBool:_gestureTransparent forKey:@"gestureTransparent"];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
  HLClickGestureTarget *copy = [[[self class] allocWithZone:zone] init];
  if (copy) {
    copy->_delegate = _delegate;
    copy->_handleGestureBlock = _handleGestureBlock;
    copy->_gestureTransparent = _gestureTransparent;
  }
  return self;
}

- (BOOL)addToGesture:(HLGestureRecognizer *)gestureRecognizer
       firstLocation:(CGPoint)sceneLocation
            isInside:(BOOL *)isInside
{
  BOOL handleGesture = NO;

  if ([gestureRecognizer isKindOfClass:[NSClickGestureRecognizer class]]) {
    NSClickGestureRecognizer *clickGestureRecognizer = (NSClickGestureRecognizer *)gestureRecognizer;
    if (clickGestureRecognizer.numberOfClicksRequired == 1) {
      *isInside = YES;
      handleGesture = YES;
    }
  }

  *isInside = !_gestureTransparent;
  if (handleGesture) {
    [gestureRecognizer addTarget:self action:@selector(HLClickGestureTarget_handleGesture:)];
  }
  return handleGesture;
}

- (NSArray *)addsToGestureRecognizers
{
  return @[ [[NSClickGestureRecognizer alloc] init] ];
}

- (void)HLClickGestureTarget_handleGesture:(HLGestureRecognizer *)gestureRecognizer
{
  id <HLClickGestureTargetDelegate> delegate = _delegate;
  if (delegate) {
    [delegate clickGestureTarget:self didClick:gestureRecognizer];
  }
  if (_handleGestureBlock) {
    _handleGestureBlock(gestureRecognizer);
  }
}

@end

#endif
