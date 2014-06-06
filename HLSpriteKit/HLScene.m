//
//  HLScene.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 5/21/14.
//  Copyright (c) 2014 Hilo. All rights reserved.
//

#import "HLScene.h"

#import "HLError.h"
#import "HLGestureTarget.h"

NSString * const HLSceneChildNoCoding = @"HLSceneChildNoCoding";
NSString * const HLSceneChildResizeWithScene = @"HLSceneChildResizeWithScene";
NSString * const HLSceneChildGestureTarget = @"HLSceneChildGestureTarget";

static BOOL HLSceneAssetsLoaded = NO;

@implementation HLScene
{
  NSMutableSet *_childNoCoding;

  NSMutableSet *_childResizeWithScene;

  NSMutableSet *_childTapTargets;
  UITapGestureRecognizer *_tapRecognizer;

  NSMutableSet *_childPanTargets;
  UIPanGestureRecognizer *_panRecognizer;

  SKNode *_modalPresentationNode;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self) {
    // note: None of the no-coding children were encoded; nothing to track now.  Subclass
    // or owner will have to recreate them.
    _childNoCoding = nil;
    _childResizeWithScene = [aDecoder decodeObjectForKey:@"childResizeWithScene"];
    _childTapTargets = [aDecoder decodeObjectForKey:@"childTapTargets"];
    _childPanTargets = [aDecoder decodeObjectForKey:@"childPanTargets"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  NSMutableDictionary *removedChildren = [NSMutableDictionary dictionary];
  if (_childNoCoding) {
    for (SKNode *child in _childNoCoding) {
      if (child.parent) {
        [removedChildren setObject:child.parent forKey:child];
        [child removeFromParent];
      }
    }
  }

  [super encodeWithCoder:aCoder];

  [self HLScene_encodeChildReferences:_childResizeWithScene forKey:@"childResizeWithScene" withCoder:aCoder];
  [self HLScene_encodeChildReferences:_childTapTargets forKey:@"childTapTargets" withCoder:aCoder];
  [self HLScene_encodeChildReferences:_childPanTargets forKey:@"childPanTargets" withCoder:aCoder];

  [removedChildren enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop){
    [object addChild:key];
  }];
}

- (void)HLScene_encodeChildReferences:(NSSet *)childReferences forKey:(NSString *)key withCoder:(NSCoder *)aCoder
{
  // note: No-coding children should not be encoded by super, obviously.  But also, we
  // can and should refuse to encode them or their children even when referenced by other
  // object variables: Whoever unencodes this object is going to need to recreate the
  // no-coding children, and when they do, they will be creating new objects which will
  // have to be re-registered with the HLScene.

  // noob: In fact, there is a more general problem here: The possibility of persistent
  // memory leaks caused by nodes removed from the node tree by the subclass (and
  // dereferenced) but which the subclass forgot to unregister.  TODO: Detect such nodes
  // automatically.  For now we can emit a warning if the node: 1) has no scene (and so
  // won't be encoded by super), and 2) is only referenced by our sets.  But maybe we
  // could use sets of weak pointers to advantage here, or do some other better automatic
  // detection.

  if (!childReferences) {
    return;
  }

  NSSet *filteredChildReferences = [childReferences objectsPassingTest:^BOOL(id obj, BOOL *stop){
    SKNode *node = (SKNode *)obj;
    while (node) {
      if ([self->_childNoCoding containsObject:node]) {
        return NO;
      }
      node = node.parent;
    }
    return YES;
  }];

  [filteredChildReferences enumerateObjectsUsingBlock:^(id obj, BOOL *stop){
    SKNode *node = (SKNode *)obj;
    if (!node.scene) {
      HLError(HLLevelWarning, [NSString stringWithFormat:@"HLScene encoding reference to child node with no scene: %@", node]);
    }
  }];

  [aCoder encodeObject:filteredChildReferences forKey:key];
}

- (void)didMoveToView:(SKView *)view
{
  [super didMoveToView:view];

  if ([_childTapTargets count] > 0) {
    _tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(HLScene_handleGesture:)];
    _tapRecognizer.delegate = self;
    [view addGestureRecognizer:_tapRecognizer];
  }
  if ([_childPanTargets count] > 0) {
    _panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(HLScene_handleGesture:)];
    _panRecognizer.delegate = self;
    [view addGestureRecognizer:_panRecognizer];
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

- (void)didChangeSize:(CGSize)oldSize
{
  [super didChangeSize:oldSize];

  if (_childResizeWithScene) {
    for (id child in _childResizeWithScene) {
      [child setSize:self.size];
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
    }
  }
}

#pragma mark -
#pragma mark UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
  // note: If no nodes are registered for our gesture recognition system, then don't try
  // to do any of our own processing.  This will prevent us from accidentally hijacking
  // gestures from a subclass which isn't interested in this provided system.  (We could
  // make our gesture handler delegate private as a way to handle the issue, but on the
  // other hand, we might have subclasses which want to cooperate with our system by doing
  // some selective overriding.)
  if (!_childTapTargets && !_childPanTargets) {
    // TODO: Check this assertion during development; remove later.
    if (_tapRecognizer || _panRecognizer) {
      [NSException raise:@"HLSceneGestureRecognizerBadState" format:@"Gesture recognizer exists but no targets."];
    }
    return YES;
  }

  [gestureRecognizer removeTarget:nil action:nil];
  CGPoint sceneLocation = [touch locationInNode:self];

  // note: This works well for me so far, but we might need to try nodesAtPoint
  // or something else, depending on the needs of the owner.

  // noob: And come to think of it, this has only been tested when the SKView
  // ignores sibling order.  How do things change when it doesn't?

  SKNode *node = [self nodeAtPoint:sceneLocation];
  while (node != self) {

    // note: Any target registered for gesture recognition should be called to
    // add itself to any type of gesture, even if that target returns NO from
    // addsTo*GestureRecognizer for the gesture type.  Because, of course, the
    // target usually wants to block gestures of all types if they are "inside"
    // the target.

    if ((_childTapTargets && [_childTapTargets containsObject:node])
        || (_childPanTargets && [_childPanTargets containsObject:node])) {
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
  if ([options containsObject:HLSceneChildNoCoding]) {
    if (!_childNoCoding) {
      _childNoCoding = [NSMutableSet setWithObject:node];
    } else {
      [_childNoCoding addObject:node];
    }
  }

  if ([options containsObject:HLSceneChildResizeWithScene]) {
    if (![node respondsToSelector:@selector(setSize:)]) {
      [NSException raise:@"HLSceneBadRegistration" format:@"Node registered for 'HLSceneChildResizeWithScene' does not support setSize: selector."];
    }
    if (!_childResizeWithScene) {
      _childResizeWithScene = [NSMutableSet setWithObject:node];
    } else {
      [_childResizeWithScene addObject:node];
    }
  }

  if ([options containsObject:HLSceneChildGestureTarget]) {
    if (![node conformsToProtocol:@protocol(HLGestureTarget)]) {
      [NSException raise:@"HLSceneBadRegistration" format:@"Node registered for 'HLSceneChildGestureTarget' does not conform to HLGestureTarget protocol."];
    }
    SKNode <HLGestureTarget> *target = (SKNode <HLGestureTarget> *)node;
    if ([target addsToTapGestureRecognizer]) {
      if (!_childTapTargets) {
        _childTapTargets = [NSMutableSet setWithObject:target];
      } else {
        [_childTapTargets addObject:target];
      }
    }
    if ([target addsToPanGestureRecognizer]) {
      if (!_childPanTargets) {
        _childPanTargets = [NSMutableSet setWithObject:target];
      } else {
        [_childPanTargets addObject:target];
      }
    }
  }
}

- (void)unregisterDescendant:(SKNode *)node
{
  if (_childNoCoding) {
    [_childNoCoding removeObject:node];
    if ([_childNoCoding count] == 0) {
      _childNoCoding = nil;
    }
  }

  if (_childResizeWithScene) {
    [_childResizeWithScene removeObject:node];
    if ([_childResizeWithScene count] == 0) {
      _childResizeWithScene = nil;
    }
  }

  if (_childTapTargets) {
    [_childTapTargets removeObject:node];
    if ([_childTapTargets count] == 0) {
      _childTapTargets = nil;
    }
  }

  if (_childPanTargets) {
    [_childPanTargets removeObject:node];
    if ([_childPanTargets count] == 0) {
      _childPanTargets = nil;
    }
  }
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
  HLSceneAssetsLoaded = YES;
}

+ (BOOL)sceneAssetsLoaded
{
  return HLSceneAssetsLoaded;
}

+ (void)assertSceneAssetsLoaded
{
  if (!HLSceneAssetsLoaded) {
    HLError(HLLevelError, @"Scene assets not yet loaded.");
  }
}

#pragma mark -
#pragma mark Modal Presentation

- (void)presentModalNode:(SKNode *)node zPositionMin:(CGFloat)zPositionMin zPositionMax:(CGFloat)zPositionMax
{
  const CGFloat HLBackgroundFadeAlpha = 0.7f;

  // note: It might be fairly trivial to do multiple layers of modal presentation, but
  // until we have a test case, just keep it to one.
  if (_modalPresentationNode) {
    HLError(HLLevelError, @"HLScene already presenting a modal node; call dismissModalNode to dismiss.");
    return;
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
}

- (void)dismissModalNode
{
  if (!_modalPresentationNode) {
    return;
  }
  [_modalPresentationNode removeFromParent];
  [_modalPresentationNode removeAllChildren];
  _modalPresentationNode = nil;
}

@end
