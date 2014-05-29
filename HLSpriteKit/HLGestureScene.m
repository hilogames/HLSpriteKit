//
//  HLGestureScene.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 5/27/14.
//  Copyright (c) 2014 Hilo. All rights reserved.
//

#import "HLGestureScene.h"

#import "HLGestureTarget.h"

@implementation HLGestureScene
{
  UITapGestureRecognizer *_tapRecognizer;
  UIPanGestureRecognizer *_panRecognizer;
}

- (void)didMoveToView:(SKView *)view
{
  [super didMoveToView:view];
  
  for (SKNode *child in self.children) {
    if ([child conformsToProtocol:@protocol(HLGestureTarget)]) {
      SKNode <HLGestureTarget> *gestureTarget = (SKNode <HLGestureTarget> *)child;
      if (!_tapRecognizer && [gestureTarget addsToTapGestureRecognizer]) {
        _tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
        _tapRecognizer.delegate = self;
        [view addGestureRecognizer:_tapRecognizer];
      }
      if (!_panRecognizer && [gestureTarget addsToPanGestureRecognizer]) {
        _panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
        _panRecognizer.delegate = self;
        [view addGestureRecognizer:_panRecognizer];
      }
    }
  }
}

- (void)willMoveFromView:(SKView *)view
{
  [super willMoveFromView:view];

  if (_tapRecognizer) {
    [view removeGestureRecognizer:_tapRecognizer];
    _tapRecognizer = nil;
  }
  if (_panRecognizer) {
    [view removeGestureRecognizer:_panRecognizer];
    _panRecognizer = nil;
  }
}

#pragma mark -
#pragma mark UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
  [gestureRecognizer removeTarget:nil action:nil];
  CGPoint sceneLocation = [touch locationInNode:self];

  // note: This works well for me so far, but we might need to try nodesAtPoint
  // or something else, depending on the needs of the owner.
  SKNode *node = [self nodeAtPoint:sceneLocation];
  while (node != self) {
    if ([node conformsToProtocol:@protocol(HLGestureTarget) ]) {
      SKNode <HLGestureTarget> *target = (SKNode <HLGestureTarget> *)node;
      BOOL isInside = NO;
      if ([target addToGesture:gestureRecognizer firstTouch:touch isInside:&isInside]) {
        return YES;
      } else if (isInside) {
        return NO;
      }
    }
    node = node.parent;
  }

  return NO;
}

- (void)handleGesture:(UIGestureRecognizer *)gestureRecognizer
{
  // All gestures are handled by HLGestureTargets; this method is a no-op used a default
  // target action for the gesture recognizer at initialization.
}

@end
