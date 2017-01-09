//
//  HLAction.m
//  Gargoyles
//
//  Created by Karl Voskuil on 12/22/16.
//  Copyright © 2016 Hilo Games. All rights reserved.
//

#import "HLAction.h"

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

CGFloat
HLActionApplyTiming(HLActionTimingMode timingMode, CGFloat normalTime)
{
  switch (timingMode) {
    case HLActionTimingModeLinear:
      return normalTime;
    case HLActionTimingModeEaseIn:
      return normalTime * normalTime * normalTime;
    case HLActionTimingModeEaseOut: {
      CGFloat t = (1.0f - normalTime);
      return t * t * t + 1.0f;
    }
    case HLActionTimingModeEaseInEaseOut:
      if (normalTime < 0.5f) {
        return normalTime * normalTime * normalTime * 4.0f;
      } else {
        CGFloat t = normalTime * 2.0f - 2.0f;
        return t * t * t / 2.0f + 1.0f;
      }
  }
}

/**
 note: Could build some or all of this functionality into all HLGroupAction.  But my
 instinct is that all HLActions should be as trim and simple as possible, which means
 keeping all this (otherwise unneeded) extra stuff out of there.
*/
@implementation HLActionRunner
{
  NSMutableDictionary *_actions;
}

- (instancetype)init
{
  self = [super init];
  if (self) {
    _actions = [NSMutableDictionary dictionary];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super init];
  if (self) {
    _actions = [aDecoder decodeObjectForKey:@"actions"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [aCoder encodeObject:_actions forKey:@"actions"];
}

- (void)update:(NSTimeInterval)elapsedTime node:(SKNode *)node
{
  // note: See note in [HLAction update] for handling action completion and removal.  In
  // short, an action must be allowed a final update call regardless of its elapsed time
  // and duration; it's only completed when its update returns NO.

  // TODO: Could keep a reference to the node on the runner, but that seems a little
  // backward, since in SKAction the node owns the action-runner and not vice-versa; also
  // it's a little confusing for encoding, since generally we want to encode the runner
  // but we don't want to encode the node.  Could put the runner on node.userData and make
  // a class category (hlActionRunAction: and hlActionUpdate:) like we do for
  // layout-manager and gesture-target, but that doesn't seem quite right either.  For
  // now, just keep the two objects separate, and pass the node into the update method as
  // needed.

  NSMutableArray *removeKeys = nil;
  for (NSString *key in _actions) {
    HLAction *action = _actions[key];
    if (![action update:elapsedTime node:node]) {
      if (!removeKeys) {
        removeKeys = [NSMutableArray array];
      }
      [removeKeys addObject:key];
    }
  }
  if (removeKeys) {
    [_actions removeObjectsForKeys:removeKeys];
  }
}

- (void)runAction:(HLAction *)action forKey:(NSString *)key
{
  // note: Requiring a key greatly simplifies the implementation here.
  if (!key) {
    [NSException raise:@"HLActionMissingKey" format:@"Action cannot be run without a key."];
  }
  _actions[key] = action;
}

- (BOOL)hasActions
{
  return [_actions count] > 0;
}

- (HLAction *)actionForKey:(NSString *)key
{
  return _actions[key];
}

- (void)removeActionForKey:(NSString *)key
{
  if (!key) {
    return;
  }
  [_actions removeObjectForKey:key];
}

- (void)removeAllActions
{
  [_actions removeAllObjects];
}

@end

@implementation HLAction

- (instancetype)initWithDuration:(NSTimeInterval)duration
{
  self = [super init];
  if (self) {
    _timingMode = HLActionTimingModeLinear;
    _duration = duration;
    _elapsedTime = 0.0f;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super init];
  if (self) {
    _timingMode = [aDecoder decodeIntegerForKey:@"timingMode"];
    _duration = [aDecoder decodeDoubleForKey:@"duration"];
    _elapsedTime = [aDecoder decodeDoubleForKey:@"elapsedTime"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [aCoder encodeInteger:_timingMode forKey:@"timingMode"];
  [aCoder encodeDouble:_duration forKey:@"duration"];
  [aCoder encodeDouble:_elapsedTime forKey:@"elapsedTime"];
}

- (BOOL)update:(NSTimeInterval)elapsedTime node:(SKNode *)node
{
  // TODO: Using elapsedTime means that each action state stores duration and
  // elapsed-time-since-start.  The alternative would be to pass in a global clock time,
  // and have each action state store its duration and time-started.  The latter would
  // avoid the drift caused by adding lots of small floating point numbers.  However, it's
  // easier to deal with elapsed time for now; we can always change it later.

  // note: Some edge cases in terms of actions, elapsed time, and duration:
  //
  //   . What if an action has a duration of 0.0?  Does it get called once or not at all?
  //
  //   . What if a slow update rate (frame rate) causes our elapsed time to miss the
  //     duration by a large margin?
  //
  //   . What if a simple durated action (like a wait, or this base-class implementation)
  //     gets updated exactly when elapsed time equals duration?
  //
  // The general rule is this: Actions must be allowed to complete themselves regardless
  // of elapsed time and duration.  The action update method gets called until it returns
  // NO, and then it is never called again.  For simple durated actions, they will
  // complete when elapsed time is greater than or equal to the duration; for collections
  // of actions, though, possible floating point error prevents this invariant, and they
  // will complete only when all their actions are completed.
  //
  // One motivating example is HLCustomAction, which wants to guarantee to invoke its
  // selector with elapsed-time-exactly-equal-to-duration even if we miss that exact
  // moment (allowing the owner to finalize state).  So we must update the action until it
  // gets that chance, at which time it will return NO.  Furthermore, it shouldn't have to
  // track whether or not it has already done so: Once it returns NO from update, it
  // shouldn't be updated again.
  //
  // And another motivating (and complicating) example is a sequence, which calculates its
  // duration as the sum of its actions' durations, but (due to possible floating point
  // error) cannot know that all its actions have completed based on elapsed time and that
  // sum.
  //
  // In short:
  //
  //   . The boolean return value signifies "not yet completed"; when it is NO, the action
  //     has completed.
  //
  //   . This base class implementation is a simple durated event, and so it is completed
  //     when elapsed time is greater than or equal to the duration.  But our descendant
  //     classes, especially collections of actions, might very well override this opinion
  //     of completion.

  _elapsedTime += elapsedTime;
  return (_elapsedTime < _duration);
}

@end

@implementation HLAction (HLActions)

+ (HLGroupAction *)group:(NSArray *)actions
{
  return [[HLGroupAction alloc] initWithActions:actions];
}

+ (HLSequenceAction *)sequence:(NSArray *)actions
{
  return [[HLSequenceAction alloc] initWithActions:actions];
}

+ (HLWaitAction *)waitForDuration:(NSTimeInterval)duration
{
  return [[HLWaitAction alloc] initWithDuration:duration];
}

+ (HLMoveToAction *)moveTo:(CGPoint)destination duration:(NSTimeInterval)duration
{
  return [[HLMoveToAction alloc] initWithDestination:destination duration:duration];
}

+ (HLCustomAction *)customActionWithDuration:(NSTimeInterval)duration
                                    selector:(SEL)selector
                                  weakTarget:(id)weakTarget
                                    userData:(id)userData
{
  return [[HLCustomAction alloc] initWithWeakTarget:weakTarget selector:selector duration:duration userData:userData];
}

@end

@implementation HLGroupAction
{
  NSMutableArray *_mutableActions;
}

- (instancetype)initWithActions:(NSArray *)actions
{
  // note: This requirement allows us to assert proper usage in update, below; otherwise
  // it's not needed.
  if (!actions || [actions count] == 0) {
    [NSException raise:@"HLGroupActionInvalid" format:@"An action group must be created with at least one action."];
  }
  NSTimeInterval durationMax = 0.0;
  for (HLAction *action in actions) {
    NSTimeInterval duration = action.duration;
    if (duration > durationMax) {
      durationMax = duration;
    }
  }
  self = [super initWithDuration:durationMax];
  if (self) {
    _mutableActions = [NSMutableArray arrayWithArray:actions];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self) {
    _mutableActions = [aDecoder decodeObjectForKey:@"actions"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [super encodeWithCoder:aCoder];
  [aCoder encodeObject:_mutableActions forKey:@"actions"];
}

- (BOOL)update:(NSTimeInterval)elapsedTime node:(SKNode *)node
{
  // note: See note in [HLAction update] for handling action completion and removal.  In
  // short, an action must be allowed a final update call regardless of its elapsed time
  // and duration; it's only completed when its update returns NO.  For collections of
  // actions, that also means we can't trust [super update] to know when we are complete
  // (based on elasped time): we are only completed when all our actions are completed,
  // and our duration is approximate.

  // note: Since groups must be created non-empty, the only way we have no actions is if
  // we've removed them on a previous update and returned NO.  This gives us a nice way to
  // assert the rule that actions aren't updated if they've previously returned NO.
  assert([_mutableActions count] > 0);

  [super update:elapsedTime node:node];

  NSUInteger i = 0;
  while (i < [_mutableActions count]) {
    HLAction *action = _mutableActions[i];
    if (![action update:elapsedTime node:node]) {
      [_mutableActions removeObjectAtIndex:i];
    } else {
      ++i;
    }
  }

  return ([_mutableActions count] > 0);
}

@end

@implementation HLSequenceAction
{
  NSMutableArray *_mutableActions;
}

- (instancetype)initWithActions:(NSArray *)actions
{
  // note: This requirement allows us to assert proper usage in update, below; otherwise
  // it's not needed.
  if (!actions || [actions count] == 0) {
    [NSException raise:@"HLSequenceActionInvalid" format:@"An action sequence must be created with at least one action."];
  }
  NSTimeInterval durationTotal = 0.0;
  for (HLAction *action in actions) {
    durationTotal += action.duration;
  }
  self = [super initWithDuration:durationTotal];
  if (self) {
    _mutableActions = [NSMutableArray arrayWithArray:actions];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self) {
    _mutableActions = [aDecoder decodeObjectForKey:@"actions"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [super encodeWithCoder:aCoder];
  [aCoder encodeObject:_mutableActions forKey:@"actions"];
}

- (BOOL)update:(NSTimeInterval)elapsedTime node:(SKNode *)node
{
  // note: See note in [HLAction update] for handling action completion and removal.  In
  // short, an action must be allowed a final update call regardless of its elapsed time
  // and duration; it's only completed when its update returns NO.  For collections of
  // actions, that also means we can't trust [super update] to know when we are complete
  // (based on elasped time): we are only completed when all our actions are completed,
  // and our duration is approximate.

  // note: Also, sequences have another expectation: One action in a sequence won't get
  // its first update call until the last action has completed.

  // note: Since sequences must be created non-empty, the only way we have no actions is
  // if we've removed them on a previous update and returned NO.  This gives us a nice way
  // to assert the rule that actions aren't updated if they've previously returned NO.
  assert([_mutableActions count] > 0);

  [super update:elapsedTime node:node];

  HLAction *currentAction = _mutableActions.firstObject;
  NSTimeInterval currentActionElapsedTime = elapsedTime;
  while (YES) {
    if ([currentAction update:currentActionElapsedTime node:node]) {
      break;
    }
    [_mutableActions removeObjectAtIndex:0];
    currentAction = _mutableActions.firstObject;
    if (!currentAction) {
      break;
    }
    // note: Okay, the next action should probably get updated in this same tick.  What's
    // the best way to calculate the elapsed time into the new action that minimizes
    // floating point error, matches reasonably well with the sequence's previously
    // calculated duration, meets the user's expectations of sequence, and hopefully
    // cannot introduce a negative elapsed time for the new action?  Uh.... Let's
    // prioritize updating the next action no matter what, even if the math produces a
    // negative elapsed time, because if we skip the update based on a negative elapsed,
    // then we won't know what to do with other actions in the sequence.  Meanwhile, the
    // new elapsed time with the least amount of error probably isn't the one calculated
    // using the completed action's idea of elapsed time, but instead using the overall
    // sequence's idea of elapsed time.  But we don't keep track of completed actions'
    // durations, so that means we're going to have to subtract from the sequence's
    // duration, which just can't possibly be perfect.  Maybe it would be better to track
    // the sum of completed durations as we complete them (since that's the same way we
    // summed up our overall duration)?  Hard to say.
    NSTimeInterval completedActionDuration = self.duration;
    for (HLAction *remainingAction in _mutableActions) {
      completedActionDuration -= remainingAction.duration;
    }
    currentActionElapsedTime = self.elapsedTime - completedActionDuration;
    if (currentActionElapsedTime < 0.0) {
      // note: I think this is possible, but I think it's only possible due to floating
      // point error, and so the difference should be very small.  Could assert that it's
      // small?  Proceeding means either lying to the next action, prolonging the
      // sequence, or else telling the action that negative time has passed, which seems
      // worse.  It would be nice if the prolonging of the sequence was a correction of
      // floating point error, not a compounding, but I'm not smart enough to figure that
      // out right now.
      assert(NO);
      currentActionElapsedTime = 0.0;
    }
  }

  return (currentAction != nil);
}

@end

@implementation HLWaitAction

@end

@implementation HLMoveToAction
{
  CGPoint _origin;
  CGPoint _destination;
}

- (instancetype)initWithDestination:(CGPoint)destination duration:(NSTimeInterval)duration
{
  self = [super initWithDuration:duration];
  if (self) {
    _destination = destination;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self) {
#if TARGET_OS_IPHONE
    _origin = [aDecoder decodeCGPointForKey:@"origin"];
    _destination = [aDecoder decodeCGPointForKey:@"destination"];
#else
    _origin = [aDecoder decodePointForKey:@"origin"];
    _destination = [aDecoder decodePointForKey:@"destination"];
#endif
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [super encodeWithCoder:aCoder];
#if TARGET_OS_IPHONE
  [aCoder encodeCGPoint:_origin forKey:@"origin"];
  [aCoder encodeCGPoint:_destination forKey:@"destination"];
#else
  [aCoder encodePoint:_origin forKey:@"origin"];
  [aCoder encodePoint:_destination forKey:@"destination"];
#endif
}

- (BOOL)update:(NSTimeInterval)elapsedTime node:(SKNode *)node
{
  // note: See note in [HLAction update] for handling action completion and removal.  In
  // short, an action must be allowed a final update call regardless of its elapsed time
  // and duration; it's only completed when its update returns NO.

  // note: It's worth noting that SKAction moveTo works this same way: The node's origin
  // is remembered, and the position is set at each update absolutely on a line between
  // origin and destination (disregarding current position along the way).
  if (self.elapsedTime == 0.0) {
    _origin = node.position;
  }

  // note: We use our simple base-class idea of completion for this.
  if (![super update:elapsedTime node:node]) {
    node.position = _destination;
    return NO;
  }
  // note: Uh, we assume the base class won't return YES if elapsed time is greater than
  // duration, or else our positioning code here will overshoot.  There should be no need
  // for a runtime check.
  assert(self.elapsedTime <= self.duration);

  CGFloat normalTime = self.elapsedTime / self.duration;
  CGFloat normalValue = HLActionApplyTiming(self.timingMode, normalTime);

  CGPoint position;
  position.x = _origin.x * (1.0f - normalValue) + _destination.x * normalValue;
  position.y = _origin.y * (1.0f - normalValue) + _destination.y * normalValue;
  node.position = position;

  return YES;
}

@end

@implementation HLCustomAction
{
  __weak id _weakTarget;
  SEL _selector;
  id _userData;
}

- (instancetype)initWithWeakTarget:(id)weakTarget
                          selector:(SEL)selector
                          duration:(NSTimeInterval)duration
                          userData:(id)userData
{
  self = [super initWithDuration:duration];
  if (self) {
    _weakTarget = weakTarget;
    _selector = selector;
    _userData = userData;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self) {
    _weakTarget = [aDecoder decodeObjectForKey:@"weakTarget"];
    _selector = NSSelectorFromString([aDecoder decodeObjectForKey:@"selector"]);
    _userData = [aDecoder decodeObjectForKey:@"userData"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [super encodeWithCoder:aCoder];
  [aCoder encodeConditionalObject:_weakTarget forKey:@"weakTarget"];
  [aCoder encodeObject:NSStringFromSelector(_selector) forKey:@"selector"];
  [aCoder encodeObject:_userData forKey:@"userData"];
}

- (BOOL)update:(NSTimeInterval)elapsedTime node:(SKNode *)node
{
  // note: See note in [HLAction update] for handling action completion and removal.  In
  // short, an action must be allowed a final update call regardless of its elapsed time
  // and duration; it's only completed when its update returns NO.  Further, when it
  // returns NO, then it won't be called again.  For our purposes, we take advantage of
  // this to guarantee that we'll do one (and only one) final callback to our target where
  // elapsed time is equal to duration (as a way of saying, "this action is complete").
  // This is the same behavior as SKAction's customActionWithDuration:actionBlock:., and
  // is true even when this last call comes quite a bit after the action should have
  // completed (due to slow update calls).

  // note: Use the base-class's simple idea of completion: that is, when elapsed time is
  // greater than or equal to duration.
  BOOL notYetCompleted = [super update:elapsedTime node:node];

  id target = _weakTarget;
  if (!target) {
    return notYetCompleted;
  }

  IMP imp = [target methodForSelector:_selector];
  void (*func)(id, SEL, SKNode *, CGFloat, NSTimeInterval, id) = (void (*)(id, SEL, SKNode *, CGFloat, NSTimeInterval, id))imp;
  if (notYetCompleted) {
    func(target, _selector, node, (CGFloat)self.elapsedTime, self.duration, _userData);
  } else {
    func(target, _selector, node, (CGFloat)self.duration, self.duration, _userData);
  }

  return notYetCompleted;
}

@end
