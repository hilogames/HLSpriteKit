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
  
  for (SKNode *node in self.children) {
    if ([node conformsToProtocol:@protocol(HLGestureTarget)]) {
      SKNode <HLGestureTarget> *target = (SKNode <HLGestureTarget> *)node;
      [self HL_addGestureRecognizersToView:view forTarget:target];
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

- (void)addChild:(SKNode *)node
{
  [super addChild:node];

  UIView *view = self.scene.view;
  if (view && [node conformsToProtocol:@protocol(HLGestureTarget)]) {
    SKNode <HLGestureTarget> *target = (SKNode <HLGestureTarget> *)node;
    [self HL_addGestureRecognizersToView:view forTarget:target];
  }
}

- (void)HL_addGestureRecognizersToView:(UIView *)view forTarget:(SKNode <HLGestureTarget> *)target
{
  if (!_tapRecognizer && [target addsToTapGestureRecognizer]) {
    _tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
    _tapRecognizer.delegate = self;
    [view addGestureRecognizer:_tapRecognizer];
  }

  if (!_panRecognizer && [target addsToPanGestureRecognizer]) {
    _panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
    _panRecognizer.delegate = self;
    [view addGestureRecognizer:_panRecognizer];
  }
}

- (void)didChangeSize:(CGSize)oldSize
{
  [super didChangeSize:oldSize];
  SKSpriteNode *modalPresentationNode = (SKSpriteNode *)[self childNodeWithName:@"HLGestureScene_modalPresentationNode"];
  if (modalPresentationNode) {
    modalPresentationNode.size = self.size;
  }
}

#pragma mark -
#pragma mark Modal Presentation

- (void)presentModalNode:(SKNode *)node zPositionMin:(CGFloat)zPositionMin zPositionMax:(CGFloat)zPositionMax
{
  const CGFloat HLBackgroundFadeAlpha = 0.7f;

  // note: As long as the background node covers the whole scene, our current gesture recognizer
  // implementation should find it (and nothing behind it) after any potential interaction with
  // the presented node.
  SKSpriteNode *modalPresentationNode = (SKSpriteNode *)[self childNodeWithName:@"HLGestureScene_modalPresentationNode"];
  if (!modalPresentationNode) {
    // note: Recreated each time we present a modal dialog (rather than persisted in a object
    // or static variable).  Assume it's not a performance issue for now.
    modalPresentationNode = [SKSpriteNode spriteNodeWithColor:[UIColor colorWithWhite:0.0f alpha:HLBackgroundFadeAlpha] size:self.size];
    modalPresentationNode.name = @"HLGestureScene_modalPresentationNode";
    [self addChild:modalPresentationNode];
  }
  modalPresentationNode.zPosition = zPositionMin;
  
  node.zPosition = (zPositionMax - zPositionMin);
  [modalPresentationNode addChild:node];
}

- (void)dismissModalNode
{
  SKSpriteNode *modalPresentationNode = (SKSpriteNode *)[self childNodeWithName:@"HLGestureScene_modalPresentationNode"];
  if (!modalPresentationNode) {
    return;
  }
  [modalPresentationNode removeFromParent];
  [modalPresentationNode removeAllChildren];
}

#pragma mark -
#pragma mark UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
  [gestureRecognizer removeTarget:nil action:nil];
  CGPoint sceneLocation = [touch locationInNode:self];

  // note: This works well for me so far, but we might need to try nodesAtPoint
  // or something else, depending on the needs of the owner.
  
  // noob: And come to think of it, this has only been tested when the SKView
  // ignores sibling order.  How do things change when it doesn't?

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
