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
  NSMutableSet *_childDoubleTapTargets;
  NSMutableSet *_childLongPressTargets;
  NSMutableSet *_childPanTargets;
  NSMutableSet *_childPinchTargets;

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
    _childDoubleTapTargets = [aDecoder decodeObjectForKey:@"childDoubleTapTargets"];
    _childLongPressTargets = [aDecoder decodeObjectForKey:@"childLongPressTargets"];
    _childPanTargets = [aDecoder decodeObjectForKey:@"childPanTargets"];
    _childPinchTargets = [aDecoder decodeObjectForKey:@"childPinchTargets"];
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
  [self HLScene_encodeChildReferences:_childDoubleTapTargets forKey:@"childDoubleTapTargets" withCoder:aCoder];
  [self HLScene_encodeChildReferences:_childLongPressTargets forKey:@"childLongPressTargets" withCoder:aCoder];
  [self HLScene_encodeChildReferences:_childPanTargets forKey:@"childPanTargets" withCoder:aCoder];
  [self HLScene_encodeChildReferences:_childPinchTargets forKey:@"childPinchTargets" withCoder:aCoder];

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
  // dereferenced) but which the subclass forgot to unregister.
  
  if (!childReferences) {
    return;
  }

  NSMutableSet *filteredChildReferences = [NSMutableSet set];
  for (SKNode *node in childReferences) {
    BOOL noCoding = NO;
    SKNode *n = node;
    while (n) {
      if ([self->_childNoCoding containsObject:node]) {
        noCoding = YES;
        break;
      }
      n = n.parent;
    }
    if (!noCoding) {
      [filteredChildReferences addObject:node];
    }
  }

  // TODO: Can fix the memory leak problem.  For now we've got a warning hacked in there.
  // Another idea is to use the equivalent of weak pointers to avoid encoding objects that
  // only we reference.  However, even that isn't complete enough, since someone else might
  // currently have a reference, but then choose not to encode the object.  I'm thinking the
  // best idea is this: (temporarily?) encode the registration information on the node itself,
  // and then do a one-time (or lazy-loading) scan of the entire node-tree at decode time to
  // recreate our child sets.  Probably store it on the nodes itself using SKNode's userData.
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

  if (_tapRecognizer) {
    [view addGestureRecognizer:_tapRecognizer];
  }
  if (_doubleTapRecognizer) {
    [view addGestureRecognizer:_doubleTapRecognizer];
  }
  if (_longPressRecognizer) {
    [view addGestureRecognizer:_longPressRecognizer];
  }
  if (_panRecognizer) {
    [view addGestureRecognizer:_panRecognizer];
  }
  if (_pinchRecognizer) {
    [view addGestureRecognizer:_pinchRecognizer];
  }
}

- (void)willMoveFromView:(SKView *)view
{
  [super willMoveFromView:view];

  if (_tapRecognizer) {
    [view removeGestureRecognizer:_tapRecognizer];
  }
  if (_doubleTapRecognizer) {
    [view removeGestureRecognizer:_doubleTapRecognizer];
  }
  if (_longPressRecognizer) {
    [view removeGestureRecognizer:_longPressRecognizer];
  }
  if (_panRecognizer) {
    [view removeGestureRecognizer:_panRecognizer];
  }
  if (_pinchRecognizer) {
    [view removeGestureRecognizer:_pinchRecognizer];
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
#pragma mark Shared Gesture Recognizers

- (BOOL)needSharedTapGestureRecognizer
{
  if (_tapRecognizer) {
    return NO;
  }
  _tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(HLScene_handleGesture:)];
  _tapRecognizer.delegate = self;
  UIView *view = self.view;
  if (view) {
    [view addGestureRecognizer:_tapRecognizer];
  }
  return YES;
}

- (BOOL)needSharedDoubleTapGestureRecognizer
{
  if (_doubleTapRecognizer) {
    return NO;
  }
  _doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(HLScene_handleGesture:)];
  _doubleTapRecognizer.delegate = self;
  _doubleTapRecognizer.numberOfTapsRequired = 2;
  // noob: Requiring single-tap recognizer to fail can be very nice, since a double-tap
  // will certainly be recognized as a single tap first.  But requiring it to fail slows
  // down the single-tap recognizer more than seems appropriate; there must be a better
  // way.
  //[_tapRecognizer requireGestureRecognizerToFail:_doubleTapRecognizer];
  UIView *view = self.view;
  if (view) {
    [view addGestureRecognizer:_doubleTapRecognizer];
  }
  return YES;
}

- (BOOL)needSharedLongPressGestureRecognizer
{
  if (_longPressRecognizer) {
    return NO;
  }
  _longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(HLScene_handleGesture:)];
  _longPressRecognizer.delegate = self;
  UIView *view = self.view;
  if (view) {
    [view addGestureRecognizer:_longPressRecognizer];
  }
  return YES;
}

- (BOOL)needSharedPanGestureRecognizer
{
  if (_panRecognizer) {
    return NO;
  }
  _panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(HLScene_handleGesture:)];
  _panRecognizer.delegate = self;
  _panRecognizer.maximumNumberOfTouches = 1;
  UIView *view = self.view;
  if (view) {
    [view addGestureRecognizer:_panRecognizer];
  }
  return YES;
}

- (BOOL)needSharedPinchGestureRecognizer
{
  if (_pinchRecognizer) {
    return NO;
  }
  _pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(HLScene_handleGesture:)];
  _pinchRecognizer.delegate = self;
  UIView *view = self.view;
  if (view) {
    [view addGestureRecognizer:_pinchRecognizer];
  }
  return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
  // note: If no nodes are registered for our gesture recognition system, then don't try
  // to do any of our own processing.  This will prevent us from accidentally hijacking
  // gestures from a subclass which isn't interested in this provided system.  (We could
  // make our gesture handler delegate private as a way to handle the issue, but on the
  // other hand, we might have subclasses which want to cooperate with our system by doing
  // some selective overriding.)
  if (!_childTapTargets && !_childDoubleTapTargets && !_childLongPressTargets && !_childPanTargets && !_childPinchTargets) {
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
        || (_childDoubleTapTargets && [_childDoubleTapTargets containsObject:node])
        || (_childLongPressTargets && [_childLongPressTargets containsObject:node])
        || (_childPanTargets && [_childPanTargets containsObject:node])
        || (_childPinchTargets && [_childPinchTargets containsObject:node])) {
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
        [self needSharedTapGestureRecognizer];
      } else {
        [_childTapTargets addObject:target];
      }
    }
    if ([target addsToDoubleTapGestureRecognizer]) {
      if (!_childDoubleTapTargets) {
        _childDoubleTapTargets = [NSMutableSet setWithObject:target];
        [self needSharedDoubleTapGestureRecognizer];
      } else {
        [_childDoubleTapTargets addObject:target];
      }
    }
    if ([target addsToLongPressGestureRecognizer]) {
      if (!_childLongPressTargets) {
        _childLongPressTargets = [NSMutableSet setWithObject:target];
        [self needSharedLongPressGestureRecognizer];
      } else {
        [_childLongPressTargets addObject:target];
      }
    }
    if ([target addsToPanGestureRecognizer]) {
      if (!_childPanTargets) {
        _childPanTargets = [NSMutableSet setWithObject:target];
        [self needSharedPanGestureRecognizer];
      } else {
        [_childPanTargets addObject:target];
      }
    }
    if ([target addsToPinchGestureRecognizer]) {
      if (!_childPinchTargets) {
        _childPinchTargets = [NSMutableSet setWithObject:target];
        [self needSharedPinchGestureRecognizer];
      } else {
        [_childPinchTargets addObject:target];
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
  if (_childDoubleTapTargets) {
    [_childDoubleTapTargets removeObject:node];
    if ([_childDoubleTapTargets count] == 0) {
      _childDoubleTapTargets = nil;
    }
  }
  if (_childLongPressTargets) {
    [_childLongPressTargets removeObject:node];
    if ([_childLongPressTargets count] == 0) {
      _childLongPressTargets = nil;
    }
  }
  if (_childPanTargets) {
    [_childPanTargets removeObject:node];
    if ([_childPanTargets count] == 0) {
      _childPanTargets = nil;
    }
  }
  if (_childPinchTargets) {
    [_childPinchTargets removeObject:node];
    if ([_childPinchTargets count] == 0) {
      _childPinchTargets = nil;
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

- (void)presentModalNode:(SKNode *)node
{
  [self presentModalNode:node zPositionMin:0.0f zPositionMax:0.0f];
}

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

- (BOOL)modalNodePresented
{
  return (_modalPresentationNode != nil);
}

@end
