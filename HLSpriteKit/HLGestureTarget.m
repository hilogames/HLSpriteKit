//
//  HLGestureTarget.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 7/10/14.
//  Copyright (c) 2014 Hilo. All rights reserved.
//

#import "HLGestureTarget.h"

@implementation HLGestureTargetConfigurableDelegate

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super init];
  if (self) {
    _addsToTapGestureRecognizer = [aDecoder decodeBoolForKey:@"addsToTapGestureRecognizer"];
    _addsToDoubleTapGestureRecognizer = [aDecoder decodeBoolForKey:@"addsToDoubleTapGestureRecognizer"];
    _addsToLongPressGestureRecognizer = [aDecoder decodeBoolForKey:@"addsToLongPressGestureRecognizer"];
    _addsToPanGestureRecognizer = [aDecoder decodeBoolForKey:@"addsToPanGestureRecognizer"];
    _addsToPinchGestureRecognizer = [aDecoder decodeBoolForKey:@"addsToPinchGestureRecognizer"];
    _addsToRotationGestureRecognizer = [aDecoder decodeBoolForKey:@"addsToRotationGestureRecognizer"];
    // note: Cannot decode _handleGestureBlock.
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [aCoder encodeBool:_addsToTapGestureRecognizer forKey:@"addsToTapGestureRecognizer"];
  [aCoder encodeBool:_addsToDoubleTapGestureRecognizer forKey:@"addsToDoubleTapGestureRecognizer"];
  [aCoder encodeBool:_addsToLongPressGestureRecognizer forKey:@"addsToLongPressGestureRecognizer"];
  [aCoder encodeBool:_addsToPanGestureRecognizer forKey:@"addsToPanGestureRecognizer"];
  [aCoder encodeBool:_addsToPinchGestureRecognizer forKey:@"addsToPinchGestureRecognizer"];
  [aCoder encodeBool:_addsToRotationGestureRecognizer forKey:@"addsToRotationGestureRecognizer"];
  // note: Cannot encode _handleGestureBlock.
}

- (BOOL)addToGesture:(UIGestureRecognizer *)gestureRecognizer firstTouch:(UITouch *)touch isInside:(BOOL *)isInside
{
  BOOL handleGesture = NO;

  if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
    UITapGestureRecognizer *tapGestureRecognizer = (UITapGestureRecognizer *)gestureRecognizer;
    if (tapGestureRecognizer.numberOfTapsRequired == 1) {
      if (_addsToTapGestureRecognizer) {
        handleGesture = YES;
      }
    } else if (tapGestureRecognizer.numberOfTapsRequired == 2) {
      if (_addsToDoubleTapGestureRecognizer) {
        handleGesture = YES;
      }
    }
  } else if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
    if (_addsToLongPressGestureRecognizer) {
      handleGesture = YES;
    }
  } else if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
    if (_addsToPanGestureRecognizer) {
      handleGesture = YES;
    }
  } else if ([gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]]) {
    if (_addsToPinchGestureRecognizer) {
      handleGesture = YES;
    }
  } else if ([gestureRecognizer isKindOfClass:[UIRotationGestureRecognizer class]]) {
    if (_addsToRotationGestureRecognizer) {
      handleGesture = YES;
    }
  }

  // note: Simple implementation says everything is inside.
  *isInside = YES;
  if (handleGesture) {
    [gestureRecognizer addTarget:self action:@selector(HLGestureTargetConfigurableDelegate_handleGesture:)];
  }
  return handleGesture;
}

- (BOOL)addsToTapGestureRecognizer
{
  return _addsToTapGestureRecognizer;
}

- (BOOL)addsToDoubleTapGestureRecognizer
{
  return _addsToDoubleTapGestureRecognizer;
}

- (BOOL)addsToLongPressGestureRecognizer
{
  return _addsToLongPressGestureRecognizer;
}

- (BOOL)addsToPanGestureRecognizer
{
  return _addsToPanGestureRecognizer;
}

- (BOOL)addsToPinchGestureRecognizer
{
  return _addsToPinchGestureRecognizer;
}

- (BOOL)addsToRotationGestureRecognizer
{
  return _addsToRotationGestureRecognizer;
}

- (void)HLGestureTargetConfigurableDelegate_handleGesture:(UIGestureRecognizer *)gestureRecognizer
{
  if (_handleGestureBlock) {
    _handleGestureBlock(gestureRecognizer);
  }
}

@end

@implementation HLGestureTargetTapDelegate

- (instancetype)initWithHandleGestureBlock:(void (^)(UIGestureRecognizer *))handleGestureBlock
{
  self = [super init];
  if (self) {
    _handleGestureBlock = handleGestureBlock;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super init];
  if (self) {
    // note: Cannot decode _handleGestureBlock.
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  // note: Cannot encode _handleGestureBlock.
}

- (BOOL)addToGesture:(UIGestureRecognizer *)gestureRecognizer firstTouch:(UITouch *)touch isInside:(BOOL *)isInside
{
  BOOL handleGesture = NO;
  
  if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
    UITapGestureRecognizer *tapGestureRecognizer = (UITapGestureRecognizer *)gestureRecognizer;
    if (tapGestureRecognizer.numberOfTapsRequired == 1) {
      handleGesture = YES;
    }
  }
  
  // note: Simple implementation says everything is inside.
  *isInside = YES;
  if (handleGesture) {
    [gestureRecognizer addTarget:self action:@selector(HLGestureTargetTapDelegate_handleGesture:)];
  }
  return handleGesture;
}

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

- (BOOL)addsToRotationGestureRecognizer
{
  return NO;
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
