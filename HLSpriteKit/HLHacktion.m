//
//  HLHacktion.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 2/4/16.
//  Copyright (c) 2016 Hilo Games. All rights reserved.
//

#import "HLHacktion.h"

#import <TargetConditionals.h>

@implementation HLHacktion

+ (SKAction *)performSelector:(SEL)selector onStrongTarget:(id)strongTarget withArgument:(id)argument
{
  HLPerformSelectorStrongSingleHacktion *performSelector = [[HLPerformSelectorStrongSingleHacktion alloc] initWithStrongTarget:strongTarget
                                                                                                                      selector:selector
                                                                                                                      argument:argument];
  return performSelector.action;
}

+ (SKAction *)performSelector:(SEL)selector onStrongTarget:(id)strongTarget withArgument1:(id)argument1 argument2:(id)argument2
{
  HLPerformSelectorStrongDoubleHacktion *performSelector = [[HLPerformSelectorStrongDoubleHacktion alloc] initWithStrongTarget:strongTarget
                                                                                                                      selector:selector
                                                                                                                     argument1:argument1
                                                                                                                     argument2:argument2];
  return performSelector.action;
}

+ (SKAction *)performSelector:(SEL)selector onWeakTarget:(id)weakTarget
{
  HLPerformSelectorWeakHacktion *performSelector = [[HLPerformSelectorWeakHacktion alloc] initWithWeakTarget:weakTarget selector:selector];
  return performSelector.action;
}

+ (SKAction *)performSelector:(SEL)selector onWeakTarget:(id)weakTarget withArgument:(id)argument
{
  HLPerformSelectorWeakSingleHacktion *performSelector = [[HLPerformSelectorWeakSingleHacktion alloc] initWithWeakTarget:weakTarget
                                                                                                                selector:selector
                                                                                                                argument:argument];
  return performSelector.action;
}

+ (SKAction *)performSelector:(SEL)selector onWeakTarget:(id)weakTarget withArgument1:(id)argument1 argument2:(id)argument2
{
  HLPerformSelectorWeakDoubleHacktion *performSelector = [[HLPerformSelectorWeakDoubleHacktion alloc] initWithWeakTarget:weakTarget
                                                                                                                selector:selector
                                                                                                               argument1:argument1
                                                                                                               argument2:argument2];
  return performSelector.action;
}

+ (SKAction *)customActionWithDuration:(NSTimeInterval)duration
                              selector:(SEL)selector
                            weakTarget:(id)weakTarget
                                  node:(SKNode *)node
                              userData:(id)userData
{
  HLCustomHacktion *customAction = [[HLCustomHacktion alloc] initWithWeakTarget:weakTarget
                                                                       selector:selector
                                                                           node:node
                                                                       duration:duration
                                                                       userData:userData];
  return customAction.action;
}

+ (SKAction *)sequence:(NSArray *)actions onNode:(SKNode *)node
{
  HLSequenceHacktion *sequence = [[HLSequenceHacktion alloc] initWithNode:node actions:actions];
  return sequence.action;
}

@end

@implementation HLPerformSelectorStrongSingleHacktion

- (instancetype)initWithStrongTarget:(id)strongTarget selector:(SEL)selector argument:(id)argument
{
  self = [super init];
  if (self) {
    _strongTarget = strongTarget;
    _selector = selector;
    _argument = argument;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super init];
  if (self) {
    _strongTarget = [aDecoder decodeObjectForKey:@"strongTarget"];
    _selector = NSSelectorFromString([aDecoder decodeObjectForKey:@"selector"]);
    _argument = [aDecoder decodeObjectForKey:@"argument"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [aCoder encodeObject:_strongTarget forKey:@"strongTarget"];
  [aCoder encodeObject:NSStringFromSelector(_selector) forKey:@"selector"];
  [aCoder encodeObject:_argument forKey:@"argument"];
}

- (void)execute
{
  if (!_strongTarget) {
    return;
  }
  IMP imp = [_strongTarget methodForSelector:_selector];
  void (*func)(id, SEL, id) = (void (*)(id, SEL, id))imp;
  func(_strongTarget, _selector, _argument);
}

- (SKAction *)action
{
  return [SKAction performSelector:@selector(execute) onTarget:self];
}

@end

@implementation HLPerformSelectorStrongDoubleHacktion

- (instancetype)initWithStrongTarget:(id)strongTarget selector:(SEL)selector argument1:(id)argument1 argument2:(id)argument2
{
  self = [super init];
  if (self) {
    _strongTarget = strongTarget;
    _selector = selector;
    _argument1 = argument1;
    _argument2 = argument2;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super init];
  if (self) {
    _strongTarget = [aDecoder decodeObjectForKey:@"strongTarget"];
    _selector = NSSelectorFromString([aDecoder decodeObjectForKey:@"selector"]);
    _argument1 = [aDecoder decodeObjectForKey:@"argument1"];
    _argument2 = [aDecoder decodeObjectForKey:@"argument2"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [aCoder encodeObject:_strongTarget forKey:@"strongTarget"];
  [aCoder encodeObject:NSStringFromSelector(_selector) forKey:@"selector"];
  [aCoder encodeObject:_argument1 forKey:@"argument1"];
  [aCoder encodeObject:_argument2 forKey:@"argument2"];
}

- (void)execute
{
  if (!_strongTarget) {
    return;
  }
  IMP imp = [_strongTarget methodForSelector:_selector];
  void (*func)(id, SEL, id, id) = (void (*)(id, SEL, id, id))imp;
  func(_strongTarget, _selector, _argument1, _argument2);
}

- (SKAction *)action
{
  return [SKAction performSelector:@selector(execute) onTarget:self];
}

@end

@implementation HLPerformSelectorWeakHacktion

- (instancetype)initWithWeakTarget:(id)weakTarget selector:(SEL)selector
{
  self = [super init];
  if (self) {
    _weakTarget = weakTarget;
    _selector = selector;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super init];
  if (self) {
    _weakTarget = [aDecoder decodeObjectForKey:@"weakTarget"];
    _selector = NSSelectorFromString([aDecoder decodeObjectForKey:@"selector"]);
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [aCoder encodeConditionalObject:_weakTarget forKey:@"weakTarget"];
  [aCoder encodeObject:NSStringFromSelector(_selector) forKey:@"selector"];
}

- (void)execute
{
  id target = _weakTarget;
  if (!target) {
    return;
  }
  IMP imp = [target methodForSelector:_selector];
  void (*func)(id, SEL) = (void (*)(id, SEL))imp;
  func(target, _selector);
}

- (SKAction *)action
{
  return [SKAction performSelector:@selector(execute) onTarget:self];
}

@end

@implementation HLPerformSelectorWeakSingleHacktion

- (instancetype)initWithWeakTarget:(id)weakTarget selector:(SEL)selector argument:(id)argument
{
  self = [super init];
  if (self) {
    _weakTarget = weakTarget;
    _selector = selector;
    _argument = argument;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super init];
  if (self) {
    _weakTarget = [aDecoder decodeObjectForKey:@"weakTarget"];
    _selector = NSSelectorFromString([aDecoder decodeObjectForKey:@"selector"]);
    _argument = [aDecoder decodeObjectForKey:@"argument"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [aCoder encodeConditionalObject:_weakTarget forKey:@"weakTarget"];
  [aCoder encodeObject:NSStringFromSelector(_selector) forKey:@"selector"];
  [aCoder encodeObject:_argument forKey:@"argument"];
}

- (void)execute
{
  id target = _weakTarget;
  if (!target) {
    return;
  }
  IMP imp = [target methodForSelector:_selector];
  void (*func)(id, SEL, id) = (void (*)(id, SEL, id))imp;
  func(target, _selector, _argument);
}

- (SKAction *)action
{
  return [SKAction performSelector:@selector(execute) onTarget:self];
}

@end

@implementation HLPerformSelectorWeakDoubleHacktion

- (instancetype)initWithWeakTarget:(id)weakTarget selector:(SEL)selector argument1:(id)argument1 argument2:(id)argument2
{
  self = [super init];
  if (self) {
    _weakTarget = weakTarget;
    _selector = selector;
    _argument1 = argument1;
    _argument2 = argument2;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super init];
  if (self) {
    _weakTarget = [aDecoder decodeObjectForKey:@"weakTarget"];
    _selector = NSSelectorFromString([aDecoder decodeObjectForKey:@"selector"]);
    _argument1 = [aDecoder decodeObjectForKey:@"argument1"];
    _argument2 = [aDecoder decodeObjectForKey:@"argument2"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [aCoder encodeConditionalObject:_weakTarget forKey:@"weakTarget"];
  [aCoder encodeObject:NSStringFromSelector(_selector) forKey:@"selector"];
  [aCoder encodeObject:_argument1 forKey:@"argument1"];
  [aCoder encodeObject:_argument2 forKey:@"argument2"];
}

- (void)execute
{
  id target = _weakTarget;
  if (!target) {
    return;
  }
  IMP imp = [target methodForSelector:_selector];
  void (*func)(id, SEL, id, id) = (void (*)(id, SEL, id, id))imp;
  func(target, _selector, _argument1, _argument2);
}

- (SKAction *)action
{
  return [SKAction performSelector:@selector(execute) onTarget:self];
}

@end

NSString * const HLCustomHacktionSceneDidUpdateNotification = @"HLCustomHacktionSceneDidUpdateNotification";

@implementation HLCustomHacktion
{
  NSTimeInterval _lastUpdateTime;
  NSTimeInterval _elapsedTime;
  BOOL _decodedSinceLastUpdate;
}

- (instancetype)initWithWeakTarget:(id)weakTarget
                          selector:(SEL)selector
                              node:(SKNode *)node
                          duration:(NSTimeInterval)duration
                          userData:(id)userData
{
  self = [super init];
  if (self) {
    _weakTarget = weakTarget;
    _selector = selector;
    _node = node;
    _duration = duration;
    _userData = userData;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super init];
  if (self) {
    _weakTarget = [aDecoder decodeObjectForKey:@"weakTarget"];
    _selector = NSSelectorFromString([aDecoder decodeObjectForKey:@"selector"]);
    _node = [aDecoder decodeObjectForKey:@"node"];
    _duration = [aDecoder decodeDoubleForKey:@"duration"];
    _userData = [aDecoder decodeObjectForKey:@"userData"];
    // note: At some point after decoding, we'll get our first notification that SKScene
    // update has been called.  How much time does SKScene think has elapsed between the
    // last frame before encoding and the first frame after encoding?  Experience proves
    // that seconds can pass during encoding and decoding tasks, and it certainly doesn't
    // think that seconds have elapsed between frames.  There seems to be no point in
    // coding _lastUpdateTime, or even the time elapsed between encoding and
    // _lastUpdateTime.
    _decodedSinceLastUpdate = YES;
    _elapsedTime = [aDecoder decodeDoubleForKey:@"elapsedTime"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [aCoder encodeConditionalObject:_weakTarget forKey:@"weakTarget"];
  [aCoder encodeObject:NSStringFromSelector(_selector) forKey:@"selector"];
  [aCoder encodeObject:_node forKey:@"node"];
  [aCoder encodeDouble:_duration forKey:@"duration"];
  [aCoder encodeObject:_userData forKey:@"userData"];
  // note: Don't bother encoding _lastUpdateTime.  See note in initWithCoder.
  [aCoder encodeDouble:_elapsedTime forKey:@"elapsedTime"];
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (void)notifySceneDidUpdate
{
  [[NSNotificationCenter defaultCenter] postNotificationName:HLCustomHacktionSceneDidUpdateNotification
                                                      object:self
                                                    userInfo:nil];
}

- (void)execute
{
  // note: It's common for the trigger for this custom action (self.action) to be running
  // in an SKAction repeatAction loop, so we must reinitialize carefully.  The previous
  // loop might never get its selector called with _elapsedTime == _duration; that's fine,
  // I think.

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(HL_sceneDidUpdate:)
                                               name:HLCustomHacktionSceneDidUpdateNotification
                                             object:nil];

  // TODO: As documented in the header: When decoded, an SKAction sequence running on a
  // node will restart from the beginning.  Tracked as a StackOverflow question at
  // <http://stackoverflow.com/q/36293846/1332415>.  It's unclear how to respond.  On one
  // hand, we have the opportunity to restore a more-intuitive behavior, so that our
  // custom action will not restart.  On the other hand, other actions occuring before
  // ours in the sequence will be replayed, and our goal is only to make custom actions
  // encodable, and not to "fix" any other SKAction behavior.  For now, don't try to
  // "fix".  But for the record, the notification subscription gets blown away, so this
  // execute method is called before the HL_sceneDidUpdate, and so we have an easy way to
  // resume in the middle of our custom action, with code like this:
  //
  //     if (_decodedSinceLastUpdate && _elapsedTime > 0.0) {
  //       return;
  //     }

  _lastUpdateTime = CFAbsoluteTimeGetCurrent();
  _elapsedTime = 0.0;

  [self HL_performSelectorWithElapsedTime:0.0];
}

- (SKAction *)action
{
  return [SKAction group:@[ [SKAction performSelector:@selector(execute) onTarget:self],
                            [SKAction waitForDuration:_duration] ]];
}

- (void)HL_sceneDidUpdate:(NSNotification *)notification
{
  const NSTimeInterval HLHacktionUpdateTimeEpsilon = 0.00001;

  assert(_elapsedTime < _duration);

  NSTimeInterval currentTime = CFAbsoluteTimeGetCurrent();

  NSTimeInterval elapsedTimeSinceLastUpdate;
  if (_decodedSinceLastUpdate) {
    _decodedSinceLastUpdate = NO;
    // note: We are not currently clever enough to understand how much time SKScene thinks
    // has elapsed between the last frame before encoding and the first frame after
    // decoding.  For now, we just assume it's considered to be 0.0 seconds.  It seems
    // unlikely this is exactly right; our idea of _elapsedTime will probably not match
    // with SKScene's after this.
    elapsedTimeSinceLastUpdate = 0.0;
  } else {
    elapsedTimeSinceLastUpdate = currentTime - _lastUpdateTime;
    if (elapsedTimeSinceLastUpdate < 0.0) {
      // note: Monotonicity not guranteed by our clock, but it seems appropriate here; our
      // whole function relates to elapsed time.  (We store absolute time only to help
      // figure out how much time has elapsed.)  Again, hard to know what SKScene does in
      // this case.
      elapsedTimeSinceLastUpdate = 0.0;
    }
  }

  _lastUpdateTime = currentTime;

  _elapsedTime += elapsedTimeSinceLastUpdate;
  if (_elapsedTime >= _duration - HLHacktionUpdateTimeEpsilon) {
    // note: We guarantee this final call with elapsedTime == _duration, even though we
    // can't guarantee that it actually happens exactly at _duration seconds.
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self HL_performSelectorWithElapsedTime:_duration];
    return;
  }

  [self HL_performSelectorWithElapsedTime:_elapsedTime];
}

- (void)HL_performSelectorWithElapsedTime:(NSTimeInterval)elapsedTime
{
  id target = _weakTarget;
  if (!target) {
    return;
  }
  IMP imp = [target methodForSelector:_selector];
  void (*func)(id, SEL, SKNode *, CGFloat, NSTimeInterval, id) = (void (*)(id, SEL, SKNode *, CGFloat, NSTimeInterval, id))imp;
  func(target, _selector, _node, (CGFloat)elapsedTime, _duration, _userData);
}

@end

@implementation HLSequenceHacktion
{
  NSUInteger _actionIndex;
}

- (instancetype)initWithNode:(SKNode *)node actions:(NSArray *)actions
{
  self = [super init];
  if (self) {
    _node = node;
    _actions = actions;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super init];
  if (self) {
    _node = [aDecoder decodeObjectForKey:@"node"];
    _actions = [aDecoder decodeObjectForKey:@"actions"];
    _actionIndex = (NSUInteger)[aDecoder decodeIntegerForKey:@"actionIndex"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [aCoder encodeConditionalObject:_node forKey:@"node"];
  [aCoder encodeObject:_actions forKey:@"actions"];
  [aCoder encodeInteger:(NSInteger)_actionIndex forKey:@"actionIndex"];
}

- (void)execute
{
  _actionIndex = 0;
  if (_node && _actionIndex < [_actions count]) {
    [self GL_runNextSubsequence];
  }
}

- (void)GL_runNextSubsequence
{
  NSUInteger actionsCount = [_actions count];
  assert(_actionIndex < actionsCount);
  SKNode *node = _node;
  if (!node) {
    return;
  }
  NSMutableArray *subsequence = [NSMutableArray arrayWithObject:_actions[_actionIndex]];
  ++_actionIndex;
  while (_actionIndex < actionsCount) {
    SKAction *action = _actions[_actionIndex];
    // note: The comparison without epsilon seems appropriate here.  Zero-duration actions
    // will presumably have a duration set with a floating-point value 0.0, which we assume
    // can be represented exactly as a float.
    if (action.duration > 0.0) {
      break;
    }
    [subsequence addObject:action];
    ++_actionIndex;
  }
  if (_actionIndex < actionsCount) {
    [subsequence addObject:[SKAction performSelector:@selector(GL_runNextSubsequence) onTarget:self]];
  }
  [node runAction:[SKAction sequence:subsequence]];
}

- (SKAction *)action
{
  return [SKAction performSelector:@selector(execute) onTarget:self];
}

@end
