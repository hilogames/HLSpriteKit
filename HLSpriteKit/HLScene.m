//
//  HLScene.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 5/21/14.
//  Copyright (c) 2014 Hilo Games. All rights reserved.
//

#import "HLScene.h"

#import "HLError.h"
#import "HLGestureTarget.h"
#import "SKNode+HLGestureTarget.h"

NSString * const HLSceneChildNoCoding = @"HLSceneChildNoCoding";
NSString * const HLSceneChildResizeWithScene = @"HLSceneChildResizeWithScene";
NSString * const HLSceneChildGestureTarget = @"HLSceneChildGestureTarget";

static NSString * const HLSceneChildUserDataKey = @"HLScene";

typedef NS_OPTIONS(NSUInteger, HLSceneChildOptionBits) {
  HLSceneChildBitNoCoding = (1 << 0),
  HLSceneChildBitResizeWithScene = (1 << 1),
  HLSceneChildBitGestureTarget = (1 << 2),
};

static const NSTimeInterval HLScenePresentationAnimationFadeDuration = 0.2f;

static BOOL _sceneAssetsLoaded = NO;

@implementation HLScene
{
  NSMutableDictionary *_childNoCoding;
  NSMutableDictionary *_childResizeWithScene;
  BOOL _childGestureTargetsExisted;

  SKNode *_modalPresentationNode;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self) {

    _gestureTargetHitTestMode = (HLSceneGestureTargetHitTestMode)[aDecoder decodeIntegerForKey:@"gestureTargetHitTestMode"];

    _childGestureTargetsExisted = NO;
    NSMutableArray *childrenArrayQueue = [NSMutableArray arrayWithObject:self.children];
    NSUInteger a = 0;
    while (a < [childrenArrayQueue count]) {
      NSArray *childrenArray = childrenArrayQueue[a];
      ++a;
      for (SKNode *node in childrenArray) {
        if ([node.children count] > 0) {
          [childrenArrayQueue addObject:node.children];
        }
        if (!node.userData) {
          continue;
        }
        NSNumber *optionBitsNumber = node.userData[HLSceneChildUserDataKey];
        if (!optionBitsNumber) {
          continue;
        }
        HLSceneChildOptionBits optionBits = [optionBitsNumber unsignedIntegerValue];
        if ((optionBits & HLSceneChildBitNoCoding) != 0) {
          if (!_childNoCoding) {
            _childNoCoding = [NSMutableDictionary dictionaryWithObject:node forKey:[NSValue valueWithNonretainedObject:node]];
          } else {
            _childNoCoding[[NSValue valueWithNonretainedObject:node]] = node;
          }
        }
        if ((optionBits & HLSceneChildBitResizeWithScene) != 0) {
          if (!_childResizeWithScene) {
            _childResizeWithScene = [NSMutableDictionary dictionaryWithObject:node forKey:[NSValue valueWithNonretainedObject:node]];
          } else {
            _childResizeWithScene[[NSValue valueWithNonretainedObject:node]] = node;
          }
        }
        if ((optionBits & HLSceneChildBitGestureTarget) != 0) {
          id <HLGestureTarget> target = [node hlGestureTarget];
          if (!target) {
            [NSException raise:@"HLSceneBadRegistration" format:@"Node registered for 'HLSceneChildGestureTarget' decoded without a gesture target: %@", target];
          }
          _childGestureTargetsExisted = YES;
          [self needSharedGestureRecognizers:[target addsToGestureRecognizers]];
        }
      }
    }
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  // note: All _child* registration references are re-created from node information
  // during initWithCoder, rather than explicitly encoded as references.  This is
  // good because it's otherwise quite hard to figure out whether a certain node
  // will be encoded or not -- and if the node won't be encoded, then we don't
  // want to encode our reference.

  // note: The shortcoming is this, though: If a node is registered to the scene
  // but then encoded separately from the scene's node hierarchy, it will have
  // the lingering userData flags attached to it, but this object won't have it
  // in its _child* lists.  Which may cause hijinks.  Let us hope in that case
  // the caller sees fit to call addChild:withOptions: for that node again,
  // when it is re-added.  It seems sensible.  (Otherwise we could check during
  // addNode:, but that again means going down the path of implicit registration,
  // which would involve a recursive check of all added nodes, which doesn't seem
  // lightweight or unintrusive.)

  NSMutableDictionary *removedChildren = [NSMutableDictionary dictionary];
  if (_childNoCoding) {
    [_childNoCoding enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop){
      SKNode *child = (SKNode *)object;
      if (child.parent) {
        removedChildren[[NSValue valueWithNonretainedObject:child]] = child.parent;
        [child removeFromParent];
      }
    }];
  }

  [super encodeWithCoder:aCoder];

  [aCoder encodeInteger:_gestureTargetHitTestMode forKey:@"gestureTargetHitTestMode"];

  [removedChildren enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop){
    SKNode *child = [key nonretainedObjectValue];
    SKNode *parent = (SKNode *)object;
    [parent addChild:child];
  }];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
  [NSException raise:@"HLCopyingNotImplemented" format:@"Copying not implemented for this descendant of an NSCopying parent."];
  return nil;
}

- (void)didMoveToView:(SKView *)view
{
  [super didMoveToView:view];
  if (_sharedGestureRecognizers) {
    for (UIGestureRecognizer *sharedGestureRecognizer in _sharedGestureRecognizers) {
      [view addGestureRecognizer:sharedGestureRecognizer];
    }
  }
}

- (void)willMoveFromView:(SKView *)view
{
  [super willMoveFromView:view];
  if (_sharedGestureRecognizers) {
    for (UIGestureRecognizer *sharedGestureRecognizer in _sharedGestureRecognizers) {
      [view removeGestureRecognizer:sharedGestureRecognizer];
    }
  }
}

- (void)didChangeSize:(CGSize)oldSize
{
  [super didChangeSize:oldSize];

  if (_childResizeWithScene) {
    [_childResizeWithScene enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop){
      [object setSize:self.size];
      // Commented out: This generates code without warnings if child is declared SKNode *.
      //    SEL selector = @selector(setSize:);
      //    NSMethodSignature *methodSignature = [child methodSignatureForSelector:@selector(setSize:)];
      //    if (methodSignature) {
      //      NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
      //      [invocation setTarget:child];
      //      [invocation setSelector:selector];
      //      [invocation setArgument:&selfSize atIndex:2];
      //      [invocation invoke];
      //    }
    }];
  }
}

#pragma mark -
#pragma mark Shared Gesture Recognizers

- (void)needSharedGestureRecognizers:(NSArray *)gestureRecognizers
{
  if (!_sharedGestureRecognizers) {
    _sharedGestureRecognizers = [NSMutableArray array];
  }
  // note: Uses an n*m search rather than something indexed, because it is assumed the
  // number of gesture recognizers is kept reasonably small.  For adding a large number
  // of targets to the scene, this might be problematic.
  for (UIGestureRecognizer *neededGestureRecognizer in gestureRecognizers) {
    BOOL foundShared = NO;
    for (UIGestureRecognizer *sharedGestureRecognizer in _sharedGestureRecognizers) {
      if (HLGestureTarget_areEquivalentGestureRecognizers(neededGestureRecognizer, sharedGestureRecognizer)) {
        foundShared = YES;
        break;
      }
    }
    if (!foundShared) {
      [neededGestureRecognizer removeTarget:nil action:NULL];
      neededGestureRecognizer.delegate = self;
      [_sharedGestureRecognizers addObject:neededGestureRecognizer];
      UIView *view = self.view;
      if (view) {
        [view addGestureRecognizer:neededGestureRecognizer];
      }
    }
  }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
  // If no nodes are registered for our gesture recognition system, then don't try
  // to do any of our own processing.  This will prevent us from accidentally hijacking
  // gestures from a subclass which isn't interested in this provided system.  (We could
  // make our gesture handler delegate private as a way to handle the issue, but on the
  // other hand, we might have subclasses which want to cooperate with our system by doing
  // some selective overriding.)
  //
  // note: Current implementation makes it easy to check whether gesture targets were
  // ever registered, but not easy to check whether gesture targets are currently registered.
  // That seems good enough.
  if (!_childGestureTargetsExisted) {
    return YES;
  }

  // TODO: If the scene has lots of gesture recognizers, then each one will be calling
  // this same code.  Since the touch location will always be the same, they could
  // certainly share the hit-testing code.  In addition, the same target will have
  // addToGesture:firstTouch:isInside: called on it for each gesture recognizer,
  // perhaps leading to a lot of redundant checking, especially is-inside checking.
  // Ideas:
  //
  //   - That's okay, because is-inside checking is usually quick.
  //
  //   - Could separate out the is-inside check, passing only the point and not the
  //     type of gesture.  This wouldn't work e.g. for HLScrollNode content nodes,
  //     which consider all gestures inside except is-inside.  To fix that, we make
  //     it so that gesture targets have another property: gestureTransparent.  The
  //     flow is then: check is-inside once for all gesture types for a certain target
  //     (caching the result here?); then if inside, call addToGesture:, and if it
  //     doesn't add, then check gestureTransparent to see if we should continue
  //     checking.  (Keep in mind that is-inside checking is often repeated in the
  //     addToGesture: routine, so separating them would introduce a little redundancy
  //     in some cases.)
  
  [gestureRecognizer removeTarget:nil action:NULL];
  CGPoint sceneLocation = [touch locationInNode:self];

  SKNode *node = self;
  if (_gestureTargetHitTestMode == HLSceneGestureTargetHitTestModeDeepestThenParent) {
    node = [self nodeAtPoint:sceneLocation];
  } else if (_gestureTargetHitTestMode == HLSceneGestureTargetHitTestModeZPositionThenParent) {
    NSArray *nodesAtPoint = [self nodesAtPoint:sceneLocation];
    CGFloat highestGlobalZPosition = 0.0f;
    for (SKNode *n in nodesAtPoint) {
      CGFloat globalZPosition = n.zPosition;
      for (SKNode *p = n.parent; p != nil; p = p.parent) {
        globalZPosition += p.zPosition;
      }
      if (!node || globalZPosition > highestGlobalZPosition) {
        node = n;
        highestGlobalZPosition = globalZPosition;
      }
    }
  } else {
    [NSException raise:@"HLSceneUnknownGestureTargetHitTestMode" format:@"Unknown gesture target hit test mode %ld.", (long)_gestureTargetHitTestMode];
  }

  while (node != self) {

    // note: Any target registered for gesture recognition should be called to add itself
    // to any type of gesture, even if the gesture handler was not returned from the
    // target's addsToGestureRecognizers.  Because, of course, the target usually wants to
    // block gestures of all types if they are "inside" the target.

    NSNumber *optionBits = (node.userData)[HLSceneChildUserDataKey];
    if (optionBits && ([optionBits unsignedIntegerValue] & HLSceneChildBitGestureTarget) != 0) {
      id <HLGestureTarget> target = [node hlGestureTarget];
      if (target) {
        BOOL isInside = NO;
        if ([target addToGesture:gestureRecognizer firstTouch:touch isInside:&isInside]) {
          return YES;
        } else if (isInside) {
          return NO;
        }
      }
    }
    node = node.parent;
  }

  return NO;
}

- (void)HLScene_handleGesture:(UIGestureRecognizer *)gestureRecognizer
{
  // All gestures are handled by HLGestureTargets; this method is a no-op used a default
  // target action for the gesture recognizer at initialization.
}

#pragma mark -
#pragma mark Child Behavior Registration

- (void)addChild:(SKNode *)node withOptions:(NSSet *)options
{
  // noob: Is this convenience method just bloat?  Are there dangers related to
  // subclassing and other overrides (for instance, should this call [super addChild:node]
  // rather than [self addChild:node] in case some override of addChild: thinks that this
  // method is now the preferred way to add a child)?
  [self addChild:node];
  [self registerDescendant:node withOptions:options];
}

- (void)registerDescendant:(SKNode *)node withOptions:(NSSet *)options
{
  HLSceneChildOptionBits optionBits = 0;
  NSNumber *optionBitsNumber = (node.userData)[HLSceneChildUserDataKey];
  if (optionBitsNumber) {
    optionBits = [optionBitsNumber unsignedIntegerValue];
  }

  if ([options containsObject:HLSceneChildNoCoding]) {
    optionBits |= HLSceneChildBitNoCoding;
    if (!_childNoCoding) {
      _childNoCoding = [NSMutableDictionary dictionaryWithObject:node forKey:[NSValue valueWithNonretainedObject:node]];
    } else {
      _childNoCoding[[NSValue valueWithNonretainedObject:node]] = node;
    }
  }

  if ([options containsObject:HLSceneChildResizeWithScene]) {
    if (![node respondsToSelector:@selector(setSize:)]) {
      [NSException raise:@"HLSceneBadRegistration" format:@"Node registered for 'HLSceneChildResizeWithScene' does not support setSize: selector."];
    }
    optionBits |= HLSceneChildBitResizeWithScene;
    if (!_childResizeWithScene) {
      _childResizeWithScene = [NSMutableDictionary dictionaryWithObject:node forKey:[NSValue valueWithNonretainedObject:node]];
    } else {
      _childResizeWithScene[[NSValue valueWithNonretainedObject:node]] = node;
    }
  }

  if ([options containsObject:HLSceneChildGestureTarget]) {
    id <HLGestureTarget> target = [node hlGestureTarget];
    if (!target) {
      [NSException raise:@"HLSceneBadRegistration" format:@"Node registered for 'HLSceneChildGestureTarget' must have a gesture target set by SKNode+HLGestureTarget's hlSetGestureTarget."];
    }
    optionBits |= HLSceneChildBitGestureTarget;
    _childGestureTargetsExisted = YES;
    [self needSharedGestureRecognizers:[target addsToGestureRecognizers]];
  }

  if (!node.userData) {
    node.userData = [NSMutableDictionary dictionaryWithObject:@(optionBits) forKey:HLSceneChildUserDataKey];
  } else {
    (node.userData)[HLSceneChildUserDataKey] = @(optionBits);
  }
}

- (void)unregisterDescendant:(SKNode *)node
{
  if (!node) {
    return;
  }

  if (_childNoCoding) {
    [_childNoCoding removeObjectForKey:[NSValue valueWithNonretainedObject:node]];
    if ([_childNoCoding count] == 0) {
      _childNoCoding = nil;
    }
  }

  if (_childResizeWithScene) {
    [_childResizeWithScene removeObjectForKey:[NSValue valueWithNonretainedObject:node]];
    if ([_childResizeWithScene count] == 0) {
      _childResizeWithScene = nil;
    }
  }

  // note: _childGestureTargetsExisted tracks whether any gesture target
  // was ever registered, not whether one is currently registered.

  [node.userData removeObjectForKey:HLSceneChildUserDataKey];
}

#pragma mark -
#pragma mark Loading Scene Assets

+ (void)loadSceneAssetsWithCompletion:(void(^)(void))completion
{
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    [self loadSceneAssets];
    if (!completion) {
      return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
      completion();
    });
  });
}

+ (void)loadSceneAssets
{
  // note: To be overridden by subclasses.
  _sceneAssetsLoaded = YES;
}

+ (BOOL)sceneAssetsLoaded
{
  return _sceneAssetsLoaded;
}

+ (void)assertSceneAssetsLoaded
{
  if (!_sceneAssetsLoaded) {
    HLError(HLLevelError, @"Scene assets not yet loaded.");
  }
}

#pragma mark -
#pragma mark Modal Presentation

- (void)presentModalNode:(SKNode *)node
               animation:(HLScenePresentationAnimation)animation
{
  [self presentModalNode:node animation:animation zPositionMin:0.0f zPositionMax:0.0f];
}

- (void)presentModalNode:(SKNode *)node
               animation:(HLScenePresentationAnimation)animation
            zPositionMin:(CGFloat)zPositionMin
            zPositionMax:(CGFloat)zPositionMax
{
  const CGFloat HLBackgroundFadeAlpha = 0.7f;

  // note: It might be fairly trivial to do multiple layers of modal presentation, but
  // until we have a test case, just keep it to one.
  if (_modalPresentationNode) {
    HLError(HLLevelError, @"HLScene already presenting a modal node; call dismissModalNode to dismiss.");
    return;
  }
  if (node.parent) {
    // note: Compromise between soft and hard fail: This is sloppiness on the part of the caller which
    // might reveal a logic error . . . but on the other hand, from our point of view it's no big deal.
    HLError(HLLevelWarning, @"Node for modal presentation in HLScene already has a parent; removing.");
    [node removeFromParent];
  }

  // note: The background node is important to our gesture recognition code (as well as
  // important visually): Any gestures starting off the modal node will find the
  // background node as the first receiving node, and (walking up the node tree, according
  // to current implementation) will find no other targets for the gesture.

  _modalPresentationNode = [SKSpriteNode spriteNodeWithColor:[UIColor colorWithWhite:0.0f alpha:HLBackgroundFadeAlpha] size:self.size];
  _modalPresentationNode.zPosition = zPositionMin;
  [self addChild:_modalPresentationNode withOptions:[NSSet setWithObjects:HLSceneChildNoCoding, HLSceneChildResizeWithScene, nil]];

  node.zPosition = (zPositionMax - zPositionMin);
  [_modalPresentationNode addChild:node];

  switch (animation) {
    case HLScenePresentationAnimationFade:
      // TODO: Hack fix for iOS8; when fading in from (the intended) alpha 0.0f this crashes with EXC_BAD_ACCESS.
      _modalPresentationNode.alpha = 0.01f;
      [_modalPresentationNode runAction:[SKAction fadeInWithDuration:HLScenePresentationAnimationFadeDuration]];
      break;
    case HLScenePresentationAnimationNone:
    default:
      break;
  }
}

- (void)dismissModalNodeAnimation:(HLScenePresentationAnimation)animation
{
  if (!_modalPresentationNode) {
    return;
  }
  switch (animation) {
    case HLScenePresentationAnimationFade: {
      // note: Avoid using completion or runBlock, since those can't be encoded during application state
      // preservation and restoration.
      // note: Also, since iOS8, using [SKAction removeFromParent] sometimes causes EXC_BAD_ACCESS.
      [_modalPresentationNode runAction:[SKAction sequence:@[ [SKAction fadeOutWithDuration:HLScenePresentationAnimationFadeDuration],
                                                             [SKAction performSelector:@selector(removeFromParent) onTarget:_modalPresentationNode],
                                                             [SKAction performSelector:@selector(removeAllChildren) onTarget:_modalPresentationNode] ]]];
      // note: Allow another modal node to be presented, even during fade-out animation.
      _modalPresentationNode = nil;
      break;
    }
    case HLScenePresentationAnimationNone:
    default:
      [_modalPresentationNode removeFromParent];
      [_modalPresentationNode removeAllChildren];
      _modalPresentationNode = nil;
      break;
  }
}

- (SKNode *)modalNodePresented
{
  if (_modalPresentationNode) {
    return [_modalPresentationNode.children firstObject];
  }
  return nil;
}

@end
