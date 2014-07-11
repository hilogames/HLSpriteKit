//
//  HLGestureTarget.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 7/10/14.
//  Copyright (c) 2014 Hilo. All rights reserved.
//

#import "HLGestureTarget.h"

@implementation HLGestureTargetSpriteNode

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
  }
  
  // note: Simple implementation says everything is inside.
  *isInside = YES;
  if (handleGesture) {
    [gestureRecognizer addTarget:self action:@selector(HLGestureTargetSpriteNode_handleGesture:)];
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

- (void)HLGestureTargetSpriteNode_handleGesture:(UIGestureRecognizer *)gestureRecognizer
{
  if (_handleGestureBlock) {
    _handleGestureBlock(gestureRecognizer);
  }
}

@end
