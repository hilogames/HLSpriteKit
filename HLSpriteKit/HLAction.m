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

#include <math.h>

CGFloat
HLActionApplyTiming(HLActionTimingMode timingMode, CGFloat normalTime)
{
  // SKAction easing functions use cubic Bezier curves with implicit first and last
  // control points (0, 0) and (1, 1).  Trial and error with ease-out proves it is using
  // (1/3, 1/3) and (2/3, 1) for middle control points; the others are likely symmetric.
  // These Beziers are gentler than our sine curves, but the sine math is much simpler.

  // Precondition: 0.0 <= normalTime <= 1.0
  switch (timingMode) {
    case HLActionTimingLinear:
      return normalTime;
    case HLActionTimingEaseIn:
      return (CGFloat)(sin((normalTime - 1.0) * M_PI_2) + 1.0);
    case HLActionTimingEaseOut:
      return (CGFloat)sin(normalTime * M_PI_2);
    case HLActionTimingEaseInEaseOut:
      return (CGFloat)((1.0 - cos(normalTime * M_PI)) / 2.0);
  }
}

CGFloat
HLActionApplyTimingInverse(HLActionTimingMode timingMode, CGFloat normalTime)
{
  // Precondition: 0.0 <= normalTime <= 1.0
  switch (timingMode) {
    case HLActionTimingLinear:
      return normalTime;
    case HLActionTimingEaseIn:
      return (CGFloat)(asin(normalTime - 1.0) / M_PI_2 + 1.0);
    case HLActionTimingEaseOut: {
      return (CGFloat)(asin(normalTime) / M_PI_2);
    }
    case HLActionTimingEaseInEaseOut:
      return (CGFloat)(acos(1.0 - normalTime * 2.0) / M_PI);
  }
}

@interface HLAction ()

@property (nonatomic, assign) NSTimeInterval elapsedTimeLinear;

- (BOOL)HL_update:(NSTimeInterval)incrementalTime node:(SKNode *)node extraTime:(NSTimeInterval *)extraTime;

- (void)HL_advanceTime:(NSTimeInterval)incrementalTime;

- (void)HL_advanceTime:(NSTimeInterval)incrementalTime extraTime:(NSTimeInterval *)extraTime notYetCompleted:(BOOL *)notYetCompleted;

- (NSTimeInterval)HL_elapsedTimeForElapsedTimeLinear:(NSTimeInterval)elapsedTimeLinear;

- (NSTimeInterval)HL_elapsedTimeLinearForElapsedTime:(NSTimeInterval)elapsedTime;

@end

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

- (instancetype)copyWithZone:(NSZone *)zone
{
  HLActionRunner *copy = [[[self class] allocWithZone:zone] init];
  if (copy) {
    copy->_actions = [[NSMutableDictionary alloc] initWithDictionary:_actions copyItems:YES];
  }
  return copy;
}

- (void)update:(NSTimeInterval)incrementalTime node:(SKNode *)node speed:(CGFloat)speed
{
  // note: If we returned extraTime, like HL_update does, we would have to divide by
  // speed to put it back into the caller's frame.  But no.  So the speed calculation
  // is trivial.
  if (speed <= 0.0f) {
    [self update:0.0 node:node];
  } else {
    [self update:(incrementalTime * speed) node:node];
  }
}

- (void)update:(NSTimeInterval)incrementalTime node:(SKNode *)node
{
  // note: See note in [HLAction update] for handling action completion and removal.  In
  // short, an action must be allowed a final update call regardless of its elapsed time
  // and duration; it's only completed when its update returns NO.

  // note: It might be possible to support reverse time, but the current implementation
  // does not.  It still makes sense to perform the update, though, since any update
  // can trigger a zero-duration action.
  if (incrementalTime < 0.0) {
    incrementalTime = 0.0;
  }

  // note: Actions can execute arbitrary code, which, among other things, can add or
  // remove actions to _actions.  Considerations:
  //
  // - One general approach would be to queue up mutations to _actions while update
  //   is looping, and then apply those mutations after the loop.  I think there's
  //   usability argument against this: It would be possible for an action to be
  //   updated after it was removed or replaced.  So instead the general approach
  //   must be to allow mutations to _actions even while looping over them in update.
  //   The remainder of the considerations assume this.
  //
  // - Fast enumeration of _actions is disallowed when it might mutate.  Fine.
  //
  // - In a loop through _actions in update, the current action might add or replace
  //   an action.  It seems best to try to be consistent about whether a new action
  //   is updated in this tick or not, although there are a number of cases:
  //
  //   1. If the action has a new key, then it's natural NOT to update it.
  //
  //   2. If the action replaces an already-updated action, then it's natural NOT
  //      to update it.
  //
  //   3. If the action replaces a not-yet-updated action, then it's natural to
  //      update it.
  //
  //   4. If the action replaces the currently-updating action, then it's natural
  //      NOT to update it.
  //
  //   For good and mostly-natural consistency, then, we would choose NOT to update
  //   newly added actions, and pay special attention to handling the not-yet-updated
  //   case (3).  HOWEVER, for now don't worry about strict consistency, and instead
  //   just follow the natural course in each case.  (Someday maybe figure out what
  //   SKAction does, and immitate it.)
  //
  // - In a loop through _actions in update, the current action might remove an
  //   action.  It seems important that the removed action is not updated again,
  //   even in this tick, or else the user might (for instance) get a callback from
  //   an action that is supposed to not exist.
  //
  // - If the currently-updating action removes or replaces itself, make sure to
  //   retain the currently running action in the loop so it can finish updating.
  //
  // - When an action completes, it must be removed from _actions, but keep in mind
  //   that other actions updating in this tick might add a new action with the same
  //   key.  For that reason, delaying the removal to the end of the update loop
  //   causes troubles.
  //
  // - Combining those last two into a corner case: The currently-updating action
  //   might complete on this tick, and, as part of its final update, replace itself.
  //   Don't remove the replacement!

  NSArray *keys = [_actions allKeys];

  for (NSString *key in keys) {
    HLAction *action = _actions[key];
    // note: The key might have been removed by a previously-updated action.
    if (!action) {
      continue;
    }
    // note: As mentioned above, the action fetched by the key might not be the
    // exact action we had in mind at the beginning of this update; it might
    // instead be a replacement set by some action earlier in the loop.  But for
    // now we choose not to care (even though that seems like inconsistent treatment
    // of newly-added actions).
    NSTimeInterval extraTime;
    if (![action HL_update:incrementalTime node:node extraTime:&extraTime]) {
      // note: The action might have replaced itself before completing.
      if (action == _actions[key]) {
        [_actions removeObjectForKey:key];
      }
    }
  }
}

- (void)runAction:(HLAction *)action withKey:(NSString *)key
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
    _timingMode = HLActionTimingLinear;
    _duration = duration;
    _elapsedTimeLinear = 0.0f;
    _speed = 1.0f;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super init];
  if (self) {
    if ([aDecoder containsValueForKey:@"duration"]) {
      _duration = [aDecoder decodeDoubleForKey:@"duration"];
    } else {
      _duration = 0.0;
    }
    if ([aDecoder containsValueForKey:@"elapsedTimeLinear"]) {
      _elapsedTimeLinear = [aDecoder decodeDoubleForKey:@"elapsedTimeLinear"];
    } else {
      _elapsedTimeLinear = 0.0;
    }
    if ([aDecoder containsValueForKey:@"timingMode"]) {
      _timingMode = [aDecoder decodeIntegerForKey:@"timingMode"];
    } else {
      _timingMode = HLActionTimingLinear;
    }
    if ([aDecoder containsValueForKey:@"speed"]) {
      _speed = [aDecoder decodeIntegerForKey:@"speed"];
    } else {
      _speed = 1.0f;
    }
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  // note: A fair number of HLAction descendants are not really durational events: like
  // perform-selector, they get updated once and only once, and have duration 0.0.  It's
  // slightly galling that this base class has a number of fields relevant only to
  // durational events.  The descendants can't neglect calls to super, though, since
  // perhaps there are fields that are more relevant; they don't know.  It doesn't seem
  // worth it to me to make a descendant parent class for HLDurationalAction, though.
  // Instead, as a way to placate myself, I do a litle optimization.
  if (_duration != 0.0) {
    [aCoder encodeDouble:_duration forKey:@"duration"];
  }
  if (_elapsedTimeLinear != 0.0) {
    [aCoder encodeDouble:_elapsedTimeLinear forKey:@"elapsedTimeLinear"];
  }
  if (_timingMode != HLActionTimingLinear) {
    [aCoder encodeInteger:_timingMode forKey:@"timingMode"];
  }
  if (_speed != 1.0f) {
    [aCoder encodeInteger:_speed forKey:@"speed"];
  }
}

- (instancetype)copyWithZone:(NSZone *)zone
{
  HLAction *copy = [[[self class] allocWithZone:zone] init];
  if (copy) {
    copy->_duration = _duration;
    copy->_elapsedTimeLinear = _elapsedTimeLinear;
    copy->_timingMode = _timingMode;
    copy->_speed = _speed;
  }
  return copy;
}

- (void)setSpeed:(CGFloat)speed
{
  // note: It might be possible to support a negative speed, but the current implementation
  // is written assuming it will be non-negative.
  if (speed < 0.0f) {
    _speed = 0.0f;
  } else {
    _speed = speed;
  }
}

- (NSTimeInterval)elapsedTime
{
  return [self HL_elapsedTimeForElapsedTimeLinear:_elapsedTimeLinear];
}

- (NSTimeInterval)HL_elapsedTimeForElapsedTimeLinear:(NSTimeInterval)elapsedTimeLinear
{
  if (_elapsedTimeLinear <= 0.0 || _elapsedTimeLinear >= _duration || _timingMode == HLActionTimingLinear) {
    return _elapsedTimeLinear;
  } else {
    return HLActionApplyTiming(_timingMode, _elapsedTimeLinear / _duration) * _duration;
  }
}

- (NSTimeInterval)HL_elapsedTimeLinearForElapsedTime:(NSTimeInterval)elapsedTime
{
  if (elapsedTime <= 0.0 || elapsedTime >= _duration || _timingMode == HLActionTimingLinear) {
    return elapsedTime;
  } else {
    return HLActionApplyTimingInverse(_timingMode, elapsedTime / _duration) * _duration;
  }
}

- (BOOL)update:(NSTimeInterval)incrementalTime node:(SKNode *)node
{
  // note: It might be possible to support reverse time, but the current implementation
  // does not.  It still makes sense to perform the update, though, since any update
  // can trigger a zero-duration action.
  if (incrementalTime < 0.0) {
    incrementalTime = 0.0;
  }
  NSTimeInterval extraTime;
  return [self HL_update:incrementalTime node:node extraTime:&extraTime];
}

- (BOOL)HL_update:(NSTimeInterval)incrementalTime node:(SKNode *)node extraTime:(NSTimeInterval *)extraTime
{
  // Preconditions: incrementalTime and speed must both be non-negative.  This method may
  // not be called again after it returns NO.

  // note: Some edge cases in terms of actions, elapsed time, duration, and speed:
  //
  //   . What if an action has a duration of zero?  Does it get called once or not at all?
  //
  //   . What if incremental time is zero, or the action speed is zero?  Does the action
  //     get updated by the caller, or is it a precondition not to call it?
  //
  //   . What if a slow update rate (frame rate) causes our elapsed time to miss the
  //     duration by a large margin?
  //
  //   . What if a simple durated action (like a wait, or this base-class implementation)
  //     gets updated exactly when elapsed time equals duration?
  //
  // The general rule is this: Actions must be allowed to complete themselves regardless
  // of elapsed time and duration and speed.  The action update method gets called until
  // it returns NO, and then it is never called again.
  //
  // Examples:
  //
  //  . HLPerformSelector*Action will be updated exactly once, which means they don't have
  //    to keep track themselves whether or not they triggered.  This call should happend
  //    regardless of elapsed time.
  //
  //  . HLCustomAction wants to guarantee to invoke its selector with
  //    elapsed-time-exactly-equal-to-duration even if we miss that exact moment
  //    (allowing the owner to finalize state).  So we must update the action until it
  //    gets that chance, at which time it will return NO.  Furthermore, it shouldn't have
  //    to track whether or not it has already done so: Once it returns NO from update, it
  //    shouldn't be updated again.
  //
  //  . HLSequenceAction has special issues with speed which means that it can complete
  //    when elapsed time is less than duration.  (Perhaps it's worth noting,
  //    additionally, that floating point error alone would cause troubles when adding the
  //    durations of actions in the sequence.)
  //
  // In short:
  //
  //  . The boolean return value signifies "not yet completed"; when it is NO, the action
  //    has completed.
  //
  //  . Duration is not always relevant to completion.

  // note: Subclass must implement this method.  Consider implementing the subclass using
  // HL_advanceTime.
  assert(NO);
  return NO;
}

- (void)HL_advanceTime:(NSTimeInterval)incrementalTime
{
  _elapsedTimeLinear += (incrementalTime * _speed);
}

- (void)HL_advanceTime:(NSTimeInterval)incrementalTime extraTime:(NSTimeInterval *)extraTime notYetCompleted:(BOOL *)notYetCompleted
{
  // note: This is a general-purpose time-advancement method which can be used for pretty much the
  // entire implementation of HL_update for simple durational or non-durational actions.  Originally
  // this was, in fact, a base-class implementation of HL_update, but that doesn't make sense for
  // actions which want to advance linear elapsed time in a standard way but *don't* want to use this
  // basic idea of completion or extra time.  (As an example, say the base-class HL_update is called
  // via super and returns NO, but the derived class thinks the action is not complete, and so returns
  // YES.  In that case, according to HL_update precondition, the derived class HL_update may be called
  // again, but the superclass HL_update may not.)

  // note: This method has the same preconditions as HL_update: incrementalTime and speed must both be
  // non-negative.  This method may not be called again after it returns NO.

  _elapsedTimeLinear += (incrementalTime * _speed);
  // note: We need to compare elapsed time to duration in two ways: first to see if the
  // action is completed, and, if so, a second time to calculate extra.  For both
  // comparisons we can use linear elapsed time without having to do the .timingMode
  // translation used by self.elapsedTime: first because linear time and .timingMode both
  // complete at normal-time 1.0, and, if completed, the extrapolation of .timingMode past
  // 1.0 is always linear.
  if (_elapsedTimeLinear >= _duration) {
    if (_speed == 0.0) {
      // note: The only way to advance elapsed time to the duration with speed 0 is if duration is
      // zero.  Completion still seems appropriate; SKAction runBlock, for instance, will still run
      // the block even if speed is zero.  That helps our math, too, because if we return completion
      // regardless of speed, then we know this is the first time we've been updated, and so
      // extraTime is just the incrementalTime (that is, _elapsedTimeLinear must be zero also),
      // regardless of speed.
      assert(_duration == 0.0 && _elapsedTimeLinear == 0.0);
      *extraTime = incrementalTime;
    } else {
      *extraTime = (_elapsedTimeLinear - _duration) / _speed;
    }
    *notYetCompleted = NO;
  } else {
    *notYetCompleted = YES;
  }
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

+ (HLRepeatAction *)repeatAction:(HLAction *)action count:(NSUInteger)count
{
  return [[HLRepeatAction alloc] initWithAction:action count:count];
}

+ (HLRepeatAction *)repeatActionForever:(HLAction *)action
{
  return [[HLRepeatAction alloc] initWithAction:action];
}

+ (HLWaitAction *)waitForDuration:(NSTimeInterval)duration
{
  return [[HLWaitAction alloc] initWithDuration:duration];
}

+ (HLMoveByAction *)moveByX:(CGFloat)x y:(CGFloat)y duration:(NSTimeInterval)duration
{
  return [[HLMoveByAction alloc] initWithX:x y:y duration:duration];
}

+ (HLMoveByAction *)moveBy:(CGPoint)delta duration:(NSTimeInterval)duration
{
  return [[HLMoveByAction alloc] initWithX:delta.x y:delta.y duration:duration];
}

+ (HLMoveToAction *)moveTo:(CGPoint)destination duration:(NSTimeInterval)duration
{
  return [[HLMoveToAction alloc] initWithDestination:destination duration:duration];
}

+ (HLMoveToAction *)moveFrom:(CGPoint)origin to:(CGPoint)destination duration:(NSTimeInterval)duration
{
  return [[HLMoveToAction alloc] initWithOrigin:origin destination:destination duration:duration];
}

+ (HLRotateByAction *)rotateByAngle:(CGFloat)angleDelta duration:(NSTimeInterval)duration
{
  return [[HLRotateByAction alloc] initWithAngle:angleDelta duration:duration];
}

+ (HLRotateToAction *)rotateToAngle:(CGFloat)angleTo duration:(NSTimeInterval)duration;
{
  return [[HLRotateToAction alloc] initWithAngle:angleTo duration:duration shortestUnitArc:NO];
}

+ (HLRotateToAction *)rotateFromAngle:(CGFloat)angleFrom to:(CGFloat)angleTo duration:(NSTimeInterval)duration;
{
  return [[HLRotateToAction alloc] initWithAngleFrom:angleFrom to:angleTo duration:duration shortestUnitArc:NO];
}

+ (HLRotateToAction *)rotateToAngle:(CGFloat)angleTo duration:(NSTimeInterval)duration shortestUnitArc:(BOOL)shortestUnitArc;
{
  return [[HLRotateToAction alloc] initWithAngle:angleTo duration:duration shortestUnitArc:shortestUnitArc];
}

+ (HLRotateToAction *)rotateFromAngle:(CGFloat)angleFrom to:(CGFloat)angleTo duration:(NSTimeInterval)duration shortestUnitArc:(BOOL)shortestUnitArc;
{
  return [[HLRotateToAction alloc] initWithAngleFrom:angleFrom to:angleTo duration:duration shortestUnitArc:shortestUnitArc];
}

+ (HLScaleByAction *)scaleBy:(CGFloat)scaleDelta duration:(NSTimeInterval)duration
{
  return [[HLScaleByAction alloc] initWithDelta:scaleDelta duration:duration];
}

+ (HLScaleXYByAction *)scaleXBy:(CGFloat)scaleDeltaX y:(CGFloat)scaleDeltaY duration:(NSTimeInterval)duration
{
  return [[HLScaleXYByAction alloc] initWithX:scaleDeltaX y:scaleDeltaY duration:duration];
}

+ (HLScaleToAction *)scaleTo:(CGFloat)scaleTo duration:(NSTimeInterval)duration
{
  // note: X and y scale values are always animated independently (because they might have different original
  // values), and so this is a convenience method and not a separate HLScaleXYToAction object.
  return [[HLScaleToAction alloc] initWithXTo:scaleTo y:scaleTo duration:duration];
}

+ (HLScaleToAction *)scaleXFrom:(CGFloat)scaleXFrom y:(CGFloat)scaleYFrom to:(CGFloat)scaleTo duration:(NSTimeInterval)duration
{
  // note: X and y scale values are always animated independently (because they might have different original
  // values), and so this is a convenience method and not a separate HLScaleXYToAction object.
  return [[HLScaleToAction alloc] initWithXFrom:scaleXFrom y:scaleYFrom xTo:scaleTo y:scaleTo duration:duration];
}

+ (HLScaleToAction *)scaleXTo:(CGFloat)scaleXTo y:(CGFloat)scaleYTo duration:(NSTimeInterval)duration
{
  return [[HLScaleToAction alloc] initWithXTo:scaleXTo y:scaleYTo duration:duration];
}

+ (HLScaleToAction *)scaleXFrom:(CGFloat)scaleXFrom y:(CGFloat)scaleYFrom xTo:(CGFloat)scaleXTo y:(CGFloat)scaleYTo duration:(NSTimeInterval)duration
{
  return [[HLScaleToAction alloc] initWithXFrom:scaleXFrom y:scaleYFrom xTo:scaleXTo y:scaleYTo duration:duration];
}

+ (HLFadeAlphaByAction *)fadeAlphaBy:(CGFloat)alphaDelta duration:(NSTimeInterval)duration
{
  return [[HLFadeAlphaByAction alloc] initWithAlpha:alphaDelta duration:duration];
}

+ (HLFadeAlphaToAction *)fadeInWithDuration:(NSTimeInterval)duration
{
  return [[HLFadeAlphaToAction alloc] initWithAlphaTo:1.0f duration:duration];
}

+ (HLFadeAlphaToAction *)fadeInFrom:(CGFloat)alphaFrom duration:(NSTimeInterval)duration
{
  return [[HLFadeAlphaToAction alloc] initWithAlphaFrom:alphaFrom to:1.0f duration:duration];
}

+ (HLFadeAlphaToAction *)fadeOutWithDuration:(NSTimeInterval)duration
{
  return [[HLFadeAlphaToAction alloc] initWithAlphaTo:0.0f duration:duration];
}

+ (HLFadeAlphaToAction *)fadeOutFrom:(CGFloat)alphaFrom duration:(NSTimeInterval)duration
{
  return [[HLFadeAlphaToAction alloc] initWithAlphaFrom:alphaFrom to:0.0f duration:duration];
}

+ (HLFadeAlphaToAction *)fadeAlphaTo:(CGFloat)alphaTo duration:(NSTimeInterval)duration
{
  return [[HLFadeAlphaToAction alloc] initWithAlphaTo:alphaTo duration:duration];
}

+ (HLFadeAlphaToAction *)fadeAlphaFrom:(CGFloat)alphaFrom to:(CGFloat)alphaTo duration:(NSTimeInterval)duration
{
  return [[HLFadeAlphaToAction alloc] initWithAlphaFrom:alphaFrom to:alphaTo duration:duration];
}

+ (HLColorizeAction *)colorizeWithColor:(SKColor *)colorTo colorBlendFactor:(CGFloat)colorBlendFactorTo duration:(NSTimeInterval)duration
{
  return [[HLColorizeAction alloc] initWithColor:colorTo colorBlendFactor:colorBlendFactorTo duration:duration];
}

+ (HLColorizeAction *)colorizeWithColorFrom:(SKColor *)colorFrom to:(SKColor *)colorTo colorBlendFactorFrom:(CGFloat)colorBlendFactorFrom to:(CGFloat)colorBlendFactorTo duration:(NSTimeInterval)duration
{
  return [[HLColorizeAction alloc] initWithColorFrom:colorFrom to:colorTo colorBlendFactorFrom:colorBlendFactorFrom to:colorBlendFactorTo duration:duration];
}

+ (HLColorizeAction *)colorizeWithColorBlendFactor:(CGFloat)colorBlendFactorTo duration:(NSTimeInterval)duration
{
  return [[HLColorizeAction alloc] initWithColorBlendFactor:colorBlendFactorTo duration:duration];
}

+ (HLColorizeAction *)colorizeWithColorBlendFactorFrom:(CGFloat)colorBlendFactorFrom to:(CGFloat)colorBlendFactorTo duration:(NSTimeInterval)duration
{
  return [[HLColorizeAction alloc] initWithColorBlendFactorFrom:colorBlendFactorFrom to:colorBlendFactorTo duration:duration];
}

+ (HLAnimateTexturesAction *)animateWithTextures:(NSArray *)textures timePerFrame:(NSTimeInterval)timePerFrame
{
  return [[HLAnimateTexturesAction alloc] initWithTextures:textures timePerFrame:timePerFrame resize:NO restore:NO];
}

+ (HLAnimateTexturesAction *)animateWithTextures:(NSArray *)textures timePerFrame:(NSTimeInterval)timePerFrame resize:(BOOL)resize restore:(BOOL)restore
{
  return [[HLAnimateTexturesAction alloc] initWithTextures:textures timePerFrame:timePerFrame resize:resize restore:restore];
}

+ (HLAnimateTexturesAction *)animateWithTextures:(NSArray *)textures timePerFrame:(NSTimeInterval)timePerFrame resize:(BOOL)resize restoreTexture:(SKTexture *)restoreTexture
{
  return [[HLAnimateTexturesAction alloc] initWithTextures:textures timePerFrame:timePerFrame resize:resize restoreTexture:restoreTexture];
}

+ (HLLoopTexturesAction *)loopTextures:(NSArray *)textures timePerFrame:(NSTimeInterval)timePerFrame
{
  return [[HLLoopTexturesAction alloc] initWithTextures:textures timePerFrame:timePerFrame resize:NO startingAt:0];
}

+ (HLLoopTexturesAction *)loopTextures:(NSArray *)textures timePerFrame:(NSTimeInterval)timePerFrame resize:(BOOL)resize startingAt:(NSUInteger)startingTextureIndex
{
  return [[HLLoopTexturesAction alloc] initWithTextures:textures timePerFrame:timePerFrame resize:resize startingAt:startingTextureIndex];
}

+ (HLRemoveFromParentAction *)removeFromParent
{
  return [[HLRemoveFromParentAction alloc] init];
}

+ (HLPerformSelectorWeakAction *)performSelector:(SEL)selector onWeakTarget:(id)weakTarget
{
  return [[HLPerformSelectorWeakAction alloc] initWithWeakTarget:weakTarget selector:selector];
}

+ (HLPerformSelectorWeakSingleAction *)performSelector:(SEL)selector onWeakTarget:(id)weakTarget withArgument:(id)argument
{
  return [[HLPerformSelectorWeakSingleAction alloc] initWithWeakTarget:weakTarget selector:selector argument:argument];
}

+ (HLPerformSelectorWeakDoubleAction *)performSelector:(SEL)selector onWeakTarget:(id)weakTarget withArgument1:(id)argument1 argument2:(id)argument2
{
  return [[HLPerformSelectorWeakDoubleAction alloc] initWithWeakTarget:weakTarget selector:selector argument1:argument1 argument2:argument2];
}

+ (HLPerformSelectorStrongAction *)performSelector:(SEL)selector onStrongTarget:(id)strongTarget
{
  return [[HLPerformSelectorStrongAction alloc] initWithStrongTarget:strongTarget selector:selector];
}

+ (HLPerformSelectorStrongSingleAction *)performSelector:(SEL)selector onStrongTarget:(id)strongTarget withArgument:(id)argument
{
  return [[HLPerformSelectorStrongSingleAction alloc] initWithStrongTarget:strongTarget selector:selector argument:argument];
}

+ (HLPerformSelectorStrongDoubleAction *)performSelector:(SEL)selector onStrongTarget:(id)strongTarget withArgument1:(id)argument1 argument2:(id)argument2
{
  return [[HLPerformSelectorStrongDoubleAction alloc] initWithStrongTarget:strongTarget selector:selector argument1:argument1 argument2:argument2];
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
    [NSException raise:@"HLActionInvalid" format:@"An action group must be created with at least one action."];
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

- (instancetype)copyWithZone:(NSZone *)zone
{
  HLGroupAction *copy = [super copyWithZone:zone];
  if (copy) {
    copy->_mutableActions = [[NSMutableArray alloc] initWithArray:_mutableActions copyItems:YES];
  }
  return copy;
}

- (NSArray *)actions
{
  return _mutableActions;
}

- (BOOL)HL_update:(NSTimeInterval)incrementalTime node:(SKNode *)node extraTime:(NSTimeInterval *)extraTime
{
  // note: Since groups must be created non-empty, the only way we have no actions is if
  // we've removed them on a previous update and returned NO.  This gives us a nice way to
  // assert for ourselves a rule that should be true for all actions: that after we return
  // NO, we aren't called again.
  assert([_mutableActions count] > 0);

  NSTimeInterval elapsedTimeOld = self.elapsedTime;
  [self HL_advanceTime:incrementalTime];
  NSTimeInterval elapsedTime = self.elapsedTime;
  // note: "My frame" means adjusted for speed and timingMode.
  NSTimeInterval incrementalTimeMyFrame = elapsedTime - elapsedTimeOld;

  // note: A problem we have in HLActionRunner that we don't have here: Our actions can't
  // be modified in the middle of an update.  So iterating through them is straightforward.
  // I'm noting it here because sometimes I think I should allow adding or removing actions
  // to a running group, and if so, then it might happend during this update (because of
  // code executed by one of our actions).

  NSTimeInterval leastExtraTimeMyFrame = incrementalTimeMyFrame;
  NSUInteger i = 0;
  while (i < [_mutableActions count]) {
    HLAction *action = _mutableActions[i];
    NSTimeInterval extraTimeMyFrame;
    if (![action HL_update:incrementalTimeMyFrame node:node extraTime:&extraTimeMyFrame]) {
      [_mutableActions removeObjectAtIndex:i];
      // note: This is a logic test in place for development that can be removed if it
      // proves stable.  In the meantime, this extra-time translation is tricky, so the
      // assert helps to make sure all actions claim to have a reasonable extra time
      // remaining when completed.
      assert(extraTimeMyFrame >= 0.0 && extraTimeMyFrame <= incrementalTimeMyFrame);
      if (extraTimeMyFrame < leastExtraTimeMyFrame) {
        leastExtraTimeMyFrame = extraTimeMyFrame;
      }
    } else {
      ++i;
    }
  }

  if ([_mutableActions count] > 0) {
    return YES;
  } else {
    // note: We need to translate the extra time back into the caller's frame, which means
    // accounting for our .speed and .timingMode, just as we did when converting
    // incrementalTime into incrementalTimeMyFrame.
    // completionTimeMyFrame: The completion time of this group, as an elapsed-time value
    // measured in my frame (that is, translated by speed and timing mode).
    NSTimeInterval completionTimeMyFrame = elapsedTime - leastExtraTimeMyFrame;
    // completionTimeLinear: The completion time of this group, as an elapsed-time value
    // measured with a linear timing mode and according to my current speed.
    NSTimeInterval completionTimeLinear = [self HL_elapsedTimeLinearForElapsedTime:completionTimeMyFrame];
    CGFloat speed = self.speed;
    // note: It should not be possible to complete the action with zero speed, but a little
    // defensive programming seems appropriate here.
    if (speed == 0.0f) {
      assert(NO);
      *extraTime = incrementalTime;
    } else {
      *extraTime = (self.elapsedTimeLinear - completionTimeLinear) / speed;
      // note: Same assert as extraTimeMyFrame, above, but this time asserting our ability
      // to successfully convert to the caller's time frame.
      assert(*extraTime >= 0.0 && *extraTime <= incrementalTime);
    }
    return NO;
  }
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
    [NSException raise:@"HLActionInvalid" format:@"An action sequence must be created with at least one action."];
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

- (instancetype)copyWithZone:(NSZone *)zone
{
  HLSequenceAction *copy = [super copyWithZone:zone];
  if (copy) {
    copy->_mutableActions = [[NSMutableArray alloc] initWithArray:_mutableActions copyItems:YES];
  }
  return copy;
}

- (NSArray *)actions
{
  return _mutableActions;
}

- (BOOL)HL_update:(NSTimeInterval)incrementalTime node:(SKNode *)node extraTime:(NSTimeInterval *)extraTime
{
  // note: See note in [HLAction HL_update] for handling action completion and removal.  In
  // short, an action must be allowed a final update call regardless of its elapsed time and
  // duration; it's only completed when its update returns NO.  For collections of actions,
  // that also means we can't trust our duration and elapsed time to know when we are complete:
  // we are only completed when all our actions are completed, and our duration is approximate.

  // note: Sequences have another expectation: One action in a sequence won't get its
  // first update call until the last action has completed.

  // note: Sequences are tricky in terms of speed.  A couple tests on SKAction:
  //
  //  . A sequence running two actions at double speed or half speed runs them
  //    consecutively, without delay or overlapping, just as if the sequence speed itself
  //    were non-1.0 during the running of those actions.
  //
  //  . If that sequence has a timing mode, it proceeds through the curve without regard
  //    for its sequenced actions.  For instance, if its actions run at double speed, then
  //    the sequence will only make it through the first half of its timing curve.  If its
  //    actions run at half speed, the sequence will go through its timing curve during
  //    the first half of the sequence, and then proceed at a linear timing mode for the
  //    second half of the sequence.
  //
  // (It's worth noting that the second experiment can be done as a thought experiment for
  // groups, too: If a group adjusted its elapsed time for its actions, it would have to
  // use, what, the slowest action?  But then the timing curve wouldn't depend on the
  // speed of all the actions, just one of them.  And things would get a little crazy if
  // the speed of the grouped actions could change during runtime.)
  //
  // From these experiments, we get inferences:
  //
  //  . A sequence's internal idea of "elapsed time" is not dependent on the elapsed times
  //    or durations of its sequenced actions.
  //
  //  . The sequence probably does not try to calculate when its action will complete, but
  //    instead relies on its actions to self-report completion when done.
  //
  //  . A sequence is done when its actions are done.  The comparison of elapsed time to
  //    duration is not relevant.
  //
  // In some ways, this is nice and simple: The default idea of completion can still be
  // that elapsed time exceeds duration, but this is not true for all actions.  We only
  // trust the boolean result of an update.
  //
  // More experiments: How does an SKAction sequence carryover time from a completed
  // action into the next action?
  //
  //  . Force a slow frame rate with 600ms delay in update; run a sequence of moveByX
  //    actions with duration 400ms each.  In the initial frame, 400ms of the 600ms are
  //    used to advance the first sequenced action to completion, and then the next 200ms
  //    are applied to the next sequenced action, advancing about halway through it.
  //
  //  . If the second action in the sequence is an 800ms action running at 2x speed, then
  //    again, it is advanced about halfway (using the remainder 200ms of the first
  //    frame).
  //
  // It's a bit tricky to figure out how much of incrementalTime is leftover when an
  // action completes.  The ideal solution won't introduce delay, will minimize minimize
  // floating point error, will preserve order, won't get confused about speed, and won't
  // ever calculate a negative elapsed time.  Here are some possibilities:
  //
  //  . Could use (completedAction.elapsedTime - completedAction.duration).
  //
  //  . Could use (sequence.elapsedTime - sum(completedActions.duration)).
  //
  // The latter appealed at first because it seemed better to let the sequence decide how
  // much time had gone by, rather than just the most recent action.  However, both
  // techniques have the same complication, which is that elapsedTime and duration can't
  // be compared directly in all cases.  Current implementation has speeded actions
  // modifying their elapsed time continuously according to their speed, so that would be
  // okay, but that still leaves sequences themselves (and groups?) as the major
  // challenge, since we've already established above that a sequence is done when its
  // actions are done, without respect for duration.  Solutions:
  //
  //  . Could return a calculated extra-time from the update method; sequences would pass
  //    the buck down to their last completed action (with a self.speed multiplier).
  //
  //  . On the other side of the calculation, could povide a true-duration method, perhaps
  //    called completionTime.  This would only seem to work, though, if speeds stay
  //    constant while running.
  //
  //  . Okay, no, so provide a "remaining linear time at current speed" method.
  //    (Subsequences and subgroups can calculate it recursively.)  That's the same as the
  //    extra-time calculated after the fact, and either way you have to back it up using
  //    the inverse timing mode function, since linear time in the subaction is
  //    timing-mode time in this sequence.
  //
  //  . Could have sequences continuously adjust their elapsedTime according to the speed
  //    of the current action.  But that seems messy for groups, and goes against the
  //    inferences from the SKAction experiments above.
  //
  // Going with the first option, for now.

  // note: Since sequences must be created non-empty, the only way we have no actions is
  // if we've removed them on a previous update and returned NO.  This gives us a nice way
  // to assert the rule that actions aren't updated if they've previously returned NO.
  assert([_mutableActions count] > 0);

  // note: A problem we have in HLActionRunner that we don't have here: Our actions can't
  // be modified in the middle of an update.  So iterating through them is straightforward.
  // I'm noting it here because sometimes I think I should allow adding or removing actions
  // to a running sequence, and if so, then it might happend during this update (because of
  // code executed by one of our actions).

  NSTimeInterval elapsedTimeOld = self.elapsedTime;
  [self HL_advanceTime:incrementalTime];
  NSTimeInterval elapsedTime = self.elapsedTime;
  NSTimeInterval incrementalTimeMyFrame = elapsedTime - elapsedTimeOld;

  HLAction *currentAction = _mutableActions.firstObject;
  NSTimeInterval remainingIncrementalTimeMyFrame = incrementalTimeMyFrame;
  NSTimeInterval extraTimeMyFrame = incrementalTimeMyFrame;
  while (currentAction) {
    if ([currentAction HL_update:remainingIncrementalTimeMyFrame node:node extraTime:&extraTimeMyFrame]) {
      break;
    }
    // note: This is a logic test in place for development that can be removed if it
    // proves stable.  In the meantime, this extra-time translation is tricky, so the
    // assert helps to make sure all actions claim to have a reasonable extra time
    // remaining when completed.
    assert(extraTimeMyFrame >= 0.0 && extraTimeMyFrame <= remainingIncrementalTimeMyFrame);
    remainingIncrementalTimeMyFrame = extraTimeMyFrame;
    [_mutableActions removeObjectAtIndex:0];
    currentAction = _mutableActions.firstObject;
  }

  // note: As a sequence, we are only completed when our last action is completed, and because of the way
  // we proceed through our time frame (and calculate our duration) heedless of the speeds of our actions,
  // our elapsed time might wildly mismatch our duration upon completion.
  if (currentAction) {
    return YES;
  } else {
    // note: We need to translate the extra time back into the caller's frame, which means
    // accounting for our .speed and .timingMode, just as we did when converting
    // incrementalTime into incrementalTimeMyFrame.
    // completionTimeMyFrame: The completion time of this sequence, as an elapsed-time value
    // measured in my frame (that is, translated by speed and timing mode).
    NSTimeInterval completionTimeMyFrame = elapsedTime - extraTimeMyFrame;
    // completionTimeLinear: The completion time of this group, as an elapsed-time value
    // measured with a linear timing mode and according to my current speed.
    NSTimeInterval completionTimeLinear = [self HL_elapsedTimeLinearForElapsedTime:completionTimeMyFrame];
    CGFloat speed = self.speed;
    // note: It should not be possible to complete the action with zero speed, but a little
    // defensive programming seems appropriate here.
    if (speed == 0.0f) {
      assert(NO);
      *extraTime = incrementalTime;
    } else {
      *extraTime = (self.elapsedTimeLinear - completionTimeLinear) / speed;
      // note: Same assert as extraTimeMyFrame, above, but this time asserting our ability
      // to successfully convert to the caller's time frame.
      assert(*extraTime >= 0.0 && *extraTime <= incrementalTime);
    }
    return NO;
  }
}

@end

@implementation HLRepeatAction

- (instancetype)initWithAction:(HLAction *)prototypeAction count:(NSUInteger)count
{
  if (!prototypeAction) {
    [NSException raise:@"HLActionInvalid" format:@"A repeat action must be created with an action to repeat."];
  }
  if (count == 0 && prototypeAction.duration == 0.0) {
    [NSException raise:@"HLActionInvalid" format:@"An action to repeated forever must have a non-zero duration."];
  }
  self = [super initWithDuration:(prototypeAction.duration * count)];
  if (self) {
    _count = count;
    _prototypeAction = prototypeAction;
  }
  return self;
}

- (instancetype)initWithAction:(HLAction *)prototypeAction
{
  if (!prototypeAction) {
    [NSException raise:@"HLActionInvalid" format:@"A repeat action must be created with an action to repeat."];
  }
  if (prototypeAction.duration == 0.0) {
    [NSException raise:@"HLActionInvalid" format:@"An action to repeated forever must have a non-zero duration."];
  }
  self = [super initWithDuration:0.0];
  if (self) {
    _prototypeAction = prototypeAction;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self) {
    _count = (NSUInteger)[aDecoder decodeIntegerForKey:@"count"];
    _index = (NSUInteger)[aDecoder decodeIntegerForKey:@"index"];
    _prototypeAction = [aDecoder decodeObjectForKey:@"prototypeAction"];
    _copiedAction = [aDecoder decodeObjectForKey:@"copiedAction"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [super encodeWithCoder:aCoder];
  [aCoder encodeInteger:(NSInteger)_count forKey:@"count"];
  [aCoder encodeInteger:(NSInteger)_index forKey:@"index"];
  [aCoder encodeObject:_prototypeAction forKey:@"prototypeAction"];
  [aCoder encodeObject:_copiedAction forKey:@"copiedAction"];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
  HLRepeatAction *copy = [super copyWithZone:zone];
  if (copy) {
    copy->_count = _count;
    copy->_index = _index;
    copy->_prototypeAction = [_prototypeAction copy];
    copy->_copiedAction = [_copiedAction copy];
  }
  return copy;
}

- (BOOL)HL_update:(NSTimeInterval)incrementalTime node:(SKNode *)node extraTime:(NSTimeInterval *)extraTime
{
  NSTimeInterval elapsedTimeOld = self.elapsedTime;
  [self HL_advanceTime:incrementalTime];
  NSTimeInterval elapsedTime = self.elapsedTime;
  // note: "My frame" means adjusted for speed and timingMode.
  NSTimeInterval incrementalTimeMyFrame = elapsedTime - elapsedTimeOld;

  NSTimeInterval remainingIncrementalTimeMyFrame = incrementalTimeMyFrame;
  NSTimeInterval extraTimeMyFrame = incrementalTimeMyFrame;
  while (_count == 0 || _index < _count) {
    if (!_copiedAction) {
      _copiedAction = [_prototypeAction copy];
    }
    if ([_copiedAction HL_update:remainingIncrementalTimeMyFrame node:node extraTime:&extraTimeMyFrame]) {
      break;
    }
    // note: This is a logic test in place for development that can be removed if it
    // proves stable.  In the meantime, this extra-time translation is tricky, so the
    // assert helps to make sure all actions claim to have a reasonable extra time
    // remaining when completed.
    assert(extraTimeMyFrame >= 0.0 && extraTimeMyFrame <= remainingIncrementalTimeMyFrame);
    remainingIncrementalTimeMyFrame = extraTimeMyFrame;
    ++_index;
    _copiedAction = nil;
  }

  // note: We are completed when our action has been repeated enough times, regardless of our
  // elapsed time and duration (which don't account for the speed of our repeated action).
  if (_copiedAction) {
    return YES;
  } else {
    // note: We need to translate the extra time back into the caller's frame, which means
    // accounting for our .speed and .timingMode, just as we did when converting
    // incrementalTime into incrementalTimeMyFrame.
    // completionTimeMyFrame: The completion time of this sequence, as an elapsed-time value
    // measured in my frame (that is, translated by speed and timing mode).
    NSTimeInterval completionTimeMyFrame = elapsedTime - extraTimeMyFrame;
    // completionTimeLinear: The completion time of this group, as an elapsed-time value
    // measured with a linear timing mode and according to my current speed.
    NSTimeInterval completionTimeLinear = [self HL_elapsedTimeLinearForElapsedTime:completionTimeMyFrame];
    CGFloat speed = self.speed;
    // note: It should not be possible to complete the action with zero speed, but a little
    // defensive programming seems appropriate here.
    if (speed == 0.0f) {
      assert(NO);
      *extraTime = incrementalTime;
    } else {
      *extraTime = (self.elapsedTimeLinear - completionTimeLinear) / speed;
      // note: Same assert as extraTimeMyFrame, above, but this time asserting our ability
      // to successfully convert to the caller's time frame.
      assert(*extraTime >= 0.0 && *extraTime <= incrementalTime);
    }
    return NO;
  }
}

@end

@implementation HLWaitAction

- (BOOL)HL_update:(NSTimeInterval)incrementalTime node:(SKNode *)node extraTime:(NSTimeInterval *)extraTime
{
  BOOL notYetCompleted;
  [self HL_advanceTime:incrementalTime extraTime:extraTime notYetCompleted:&notYetCompleted];
  return notYetCompleted;
}

@end

@implementation HLMoveByAction
{
  CGFloat _deltaX;
  CGFloat _deltaY;
  CGFloat _lastCumulativeDeltaX;
  CGFloat _lastCumulativeDeltaY;
}

- (instancetype)initWithX:(CGFloat)deltaX y:(CGFloat)deltaY duration:(NSTimeInterval)duration
{
  self = [super initWithDuration:duration];
  if (self) {
    _deltaX = deltaX;
    _deltaY = deltaY;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self) {
    _deltaX = (CGFloat)[aDecoder decodeDoubleForKey:@"deltaX"];
    _deltaY = (CGFloat)[aDecoder decodeDoubleForKey:@"deltaY"];
    _lastCumulativeDeltaX = (CGFloat)[aDecoder decodeDoubleForKey:@"lastCumulativeDeltaX"];
    _lastCumulativeDeltaY = (CGFloat)[aDecoder decodeDoubleForKey:@"lastCumulativeDeltaY"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [super encodeWithCoder:aCoder];
  [aCoder encodeDouble:_deltaX forKey:@"deltaX"];
  [aCoder encodeDouble:_deltaY forKey:@"deltaY"];
  [aCoder encodeDouble:_lastCumulativeDeltaX forKey:@"lastCumulativeDeltaX"];
  [aCoder encodeDouble:_lastCumulativeDeltaY forKey:@"lastCumulativeDeltaY"];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
  HLMoveByAction *copy = [super copyWithZone:zone];
  if (copy) {
    copy->_deltaX = _deltaX;
    copy->_deltaY = _deltaY;
    copy->_lastCumulativeDeltaX = _lastCumulativeDeltaX;
    copy->_lastCumulativeDeltaY = _lastCumulativeDeltaY;
  }
  return copy;
}

- (BOOL)HL_update:(NSTimeInterval)incrementalTime node:(SKNode *)node extraTime:(NSTimeInterval *)extraTime
{
  // note: This mechanism chosen in order to avoid floating point drift (in the sum of instantaneous deltas
  // applied to the node or returned by the property) and to support calculation of property .instantaneousDelta.

  CGPoint lastInstantaneousDelta = [self HL_instantaneousDelta];
  // note: Always calculate the cumulative by adding the instantaneous, so that we can compensate for the difference
  // between "elasped delta" (normal-elapsed-time * total-delta) and "cumulative delta" (sum of a series of
  // instantaneous-delta).
  _lastCumulativeDeltaX += lastInstantaneousDelta.x;
  _lastCumulativeDeltaY += lastInstantaneousDelta.y;

  BOOL notYetCompleted;
  [self HL_advanceTime:incrementalTime extraTime:extraTime notYetCompleted:&notYetCompleted];

  if (node) {
    CGPoint instantaneousDelta = [self HL_instantaneousDelta];
    CGPoint position = node.position;
    position.x += instantaneousDelta.x;
    position.y += instantaneousDelta.y;
    node.position = position;
  }

  return notYetCompleted;
}

- (CGPoint)instantaneousDelta
{
  return [self HL_instantaneousDelta];
}

- (CGPoint)HL_instantaneousDelta
{
  NSTimeInterval elapsedTime = self.elapsedTime;
  NSTimeInterval duration = self.duration;

  CGPoint instantaneousDelta;
  if (elapsedTime >= duration) {
    instantaneousDelta.x = _deltaX - _lastCumulativeDeltaX;
    instantaneousDelta.y = _deltaY - _lastCumulativeDeltaY;
  } else {
    CGFloat normalTime = elapsedTime / duration;
    instantaneousDelta.x = _deltaX * normalTime - _lastCumulativeDeltaX;
    instantaneousDelta.y = _deltaY * normalTime - _lastCumulativeDeltaY;
  }
  return instantaneousDelta;
}

@end

@implementation HLMoveToAction
{
  BOOL _isOriginSet;
  CGPoint _origin;
  CGPoint _destination;
}

- (instancetype)initWithDestination:(CGPoint)destination duration:(NSTimeInterval)duration
{
  self = [super initWithDuration:duration];
  if (self) {
    _isOriginSet = NO;
    _destination = destination;
  }
  return self;
}

- (instancetype)initWithOrigin:(CGPoint)origin destination:(CGPoint)destination duration:(NSTimeInterval)duration
{
  self = [super initWithDuration:duration];
  if (self) {
    _isOriginSet = YES;
    _origin = origin;
    _destination = destination;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self) {
    _isOriginSet = [aDecoder decodeBoolForKey:@"isOriginSet"];
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
  [aCoder encodeBool:_isOriginSet forKey:@"isOriginSet"];
#if TARGET_OS_IPHONE
  [aCoder encodeCGPoint:_origin forKey:@"origin"];
  [aCoder encodeCGPoint:_destination forKey:@"destination"];
#else
  [aCoder encodePoint:_origin forKey:@"origin"];
  [aCoder encodePoint:_destination forKey:@"destination"];
#endif
}

- (instancetype)copyWithZone:(NSZone *)zone
{
  HLMoveToAction *copy = [super copyWithZone:zone];
  if (copy) {
    copy->_isOriginSet = _isOriginSet;
    copy->_origin = _origin;
    copy->_destination = _destination;
  }
  return copy;
}

- (BOOL)HL_update:(NSTimeInterval)incrementalTime node:(SKNode *)node extraTime:(NSTimeInterval *)extraTime
{
  // note: For reference, compare SKAction moveTo: The node's origin is remembered on the
  // first update, and then the position is set at each subsequent update absolutely on a
  // line between origin and destination (disregarding current position along the way).
  // This works similarly.

  if (!_isOriginSet) {
    if (node) {
      _origin = node.position;
      _isOriginSet = YES;
    } else {
      [NSException raise:@"HLActionUninitialized" format:@"HLMoveToAction requires an origin:"
       " either pass a node to the first update,"
       " or initialize with initWithOrigin:destination:duration:."];
    }
  }

  BOOL notYetCompleted;
  [self HL_advanceTime:incrementalTime extraTime:extraTime notYetCompleted:&notYetCompleted];

  if (node) {
    node.position = [self HL_position];
  }

  return notYetCompleted;
}

- (CGPoint)position
{
  if (!_isOriginSet) {
    [NSException raise:@"HLActionUninitialized" format:@"HLMoveToAction requires an origin:"
     " either pass a node to the first update,"
     " or initialize with initWithOrigin:destination:duration:."];
  }
  return [self HL_position];
}

- (CGPoint)HL_position
{
  NSTimeInterval elapsedTime = self.elapsedTime;
  NSTimeInterval duration = self.duration;

  if (elapsedTime >= duration) {
    return _destination;
  }

  CGFloat normalTime = elapsedTime / duration;

  CGPoint position;
  position.x = _origin.x * (1.0f - normalTime) + _destination.x * normalTime;
  position.y = _origin.y * (1.0f - normalTime) + _destination.y * normalTime;

  return position;
}

@end

@implementation HLRotateByAction
{
  CGFloat _delta;
  CGFloat _lastCumulativeDelta;
}

- (instancetype)initWithAngle:(CGFloat)angleDelta duration:(NSTimeInterval)duration
{
  self = [super initWithDuration:duration];
  if (self) {
    _delta = angleDelta;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self) {
    _delta = (CGFloat)[aDecoder decodeDoubleForKey:@"delta"];
    _lastCumulativeDelta = (CGFloat)[aDecoder decodeDoubleForKey:@"lastCumulativeDelta"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [super encodeWithCoder:aCoder];
  [aCoder encodeDouble:_delta forKey:@"delta"];
  [aCoder encodeDouble:_lastCumulativeDelta forKey:@"lastCumulativeDelta"];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
  HLRotateByAction *copy = [super copyWithZone:zone];
  if (copy) {
    copy->_delta = _delta;
    copy->_lastCumulativeDelta = _lastCumulativeDelta;
  }
  return copy;
}

- (BOOL)HL_update:(NSTimeInterval)incrementalTime node:(SKNode *)node extraTime:(NSTimeInterval *)extraTime
{
  // note: This mechanism chosen in order to avoid floating point drift (in the sum of instantaneous deltas
  // applied to the node or returned by the property) and to support calculation of property .instantaneousDelta.

  CGFloat lastInstantaneousDelta = [self HL_instantaneousDelta];
  // note: Always calculate the cumulative by adding the instantaneous, so that we can compensate for the difference
  // between "elasped delta" (normal-elapsed-time * total-delta) and "cumulative delta" (sum of a series of
  // instantaneous-delta).
  _lastCumulativeDelta += lastInstantaneousDelta;

  BOOL notYetCompleted;
  [self HL_advanceTime:incrementalTime extraTime:extraTime notYetCompleted:&notYetCompleted];

  if (node) {
    CGFloat instantaneousDelta = [self HL_instantaneousDelta];
    node.zRotation += instantaneousDelta;
  }

  return notYetCompleted;
}

- (CGFloat)instantaneousDelta
{
  CGFloat instantaneousDelta = [self HL_instantaneousDelta];
  return instantaneousDelta;
}

- (CGFloat)HL_instantaneousDelta
{
  NSTimeInterval elapsedTime = self.elapsedTime;
  NSTimeInterval duration = self.duration;

  CGFloat instantaneousDelta;
  if (elapsedTime >= duration) {
    instantaneousDelta = _delta - _lastCumulativeDelta;
  } else {
    CGFloat normalTime = elapsedTime / duration;
    instantaneousDelta = _delta * normalTime - _lastCumulativeDelta;
  }
  return instantaneousDelta;
}

@end

@implementation HLRotateToAction
{
  BOOL _isAngleFromSet;
  CGFloat _angleFrom;
  CGFloat _angleTo;
  BOOL _shortestUnitArc;
}

- (instancetype)initWithAngle:(CGFloat)angleTo duration:(NSTimeInterval)duration shortestUnitArc:(BOOL)shortestUnitArc
{
  self = [super initWithDuration:duration];
  if (self) {
    _isAngleFromSet = NO;
    _angleTo = angleTo;
    _shortestUnitArc = shortestUnitArc;
  }
  return self;
}

- (instancetype)initWithAngleFrom:(CGFloat)angleFrom to:(CGFloat)angleTo duration:(NSTimeInterval)duration shortestUnitArc:(BOOL)shortestUnitArc
{
  self = [super initWithDuration:duration];
  if (self) {
    _isAngleFromSet = YES;
    if (shortestUnitArc) {
      _angleFrom = [self HL_normalizeAngle:angleFrom closeToAngle:_angleTo];
    } else {
      _angleFrom = angleFrom;
    }
    _angleTo = angleTo;
    _shortestUnitArc = shortestUnitArc;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self) {
    _isAngleFromSet = [aDecoder decodeBoolForKey:@"isAngleFromSet"];
    _angleFrom = (CGFloat)[aDecoder decodeDoubleForKey:@"angleFrom"];
    _angleTo = (CGFloat)[aDecoder decodeDoubleForKey:@"angleTo"];
    _shortestUnitArc = [aDecoder decodeBoolForKey:@"shortestUnitArc"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [super encodeWithCoder:aCoder];
  [aCoder encodeBool:_isAngleFromSet forKey:@"isAngleFromSet"];
  [aCoder encodeDouble:_angleFrom forKey:@"angleFrom"];
  [aCoder encodeDouble:_angleTo forKey:@"angleTo"];
  [aCoder encodeBool:_shortestUnitArc forKey:@"shortestUnitArc"];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
  HLRotateToAction *copy = [super copyWithZone:zone];
  if (copy) {
    copy->_isAngleFromSet = _isAngleFromSet;
    copy->_angleFrom = _angleFrom;
    copy->_angleTo = _angleTo;
    copy->_shortestUnitArc = _shortestUnitArc;
  }
  return copy;
}

- (BOOL)HL_update:(NSTimeInterval)incrementalTime node:(SKNode *)node extraTime:(NSTimeInterval *)extraTime
{
  if (!_isAngleFromSet) {
    if (node) {
      if (_shortestUnitArc) {
        _angleFrom = [self HL_normalizeAngle:node.zRotation closeToAngle:_angleTo];
      } else {
        _angleFrom = node.zRotation;
      }
      _isAngleFromSet = YES;
    } else {
      [NSException raise:@"HLActionUninitialized" format:@"HLRotateToAction requires an angle-from:"
       " either pass a node to the first update,"
       " or initialize with initWithAngleFrom:to:duration:shortestUnitArc:."];
    }
  }

  BOOL notYetCompleted;
  [self HL_advanceTime:incrementalTime extraTime:extraTime notYetCompleted:&notYetCompleted];

  if (node) {
    node.zRotation = [self HL_angle];
  }

  return notYetCompleted;
}

- (CGFloat)angle
{
  if (!_isAngleFromSet) {
    [NSException raise:@"HLActionUninitialized" format:@"HLRotateToAction requires an angle-from:"
     " either pass a node to the first update,"
     " or initialize with initWithAngleFrom:to:duration:shortestUnitArc:."];
  }
  return [self HL_angle];
}

- (CGFloat)HL_angle
{
  NSTimeInterval elapsedTime = self.elapsedTime;
  NSTimeInterval duration = self.duration;

  if (elapsedTime >= duration) {
    return _angleTo;
  }

  CGFloat normalTime = elapsedTime / duration;

  return _angleFrom * (1.0f - normalTime) + _angleTo * normalTime;
}

- (CGFloat)HL_normalizeAngle:(CGFloat)freeAngle closeToAngle:(CGFloat)fixedAngle
{
  const CGFloat pi = (CGFloat)M_PI;
  const CGFloat twoPi = (CGFloat)(M_PI * 2.0);
  while (freeAngle <= fixedAngle - pi) {
    freeAngle += twoPi;
  }
  while (freeAngle > fixedAngle + pi) {
    freeAngle -= twoPi;
  }
  return freeAngle;
}

@end

@implementation HLScaleByAction
{
  CGFloat _delta;
  CGFloat _lastCumulativeDelta;
}

- (instancetype)initWithDelta:(CGFloat)scaleDelta duration:(NSTimeInterval)duration
{
  self = [super initWithDuration:duration];
  if (self) {
    _delta = scaleDelta;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self) {
    _delta = (CGFloat)[aDecoder decodeDoubleForKey:@"delta"];
    _lastCumulativeDelta = (CGFloat)[aDecoder decodeDoubleForKey:@"lastCumulativeDelta"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [super encodeWithCoder:aCoder];
  [aCoder encodeDouble:_delta forKey:@"delta"];
  [aCoder encodeDouble:_lastCumulativeDelta forKey:@"lastCumulativeDelta"];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
  HLScaleByAction *copy = [super copyWithZone:zone];
  if (copy) {
    copy->_delta = _delta;
    copy->_lastCumulativeDelta = _lastCumulativeDelta;
  }
  return copy;
}

- (BOOL)HL_update:(NSTimeInterval)incrementalTime node:(SKNode *)node extraTime:(NSTimeInterval *)extraTime
{
  // note: This mechanism chosen in order to avoid floating point drift (in the sum of instantaneous deltas
  // applied to the node or returned by the property) and to support calculation of property .instantaneousDelta.

  CGFloat lastInstantaneousDelta = [self HL_instantaneousDelta];
  // note: Always calculate the cumulative by adding the instantaneous, so that we can compensate for the difference
  // between "elasped delta" (normal-elapsed-time * total-delta) and "cumulative delta" (sum of a series of
  // instantaneous-delta).
  _lastCumulativeDelta += lastInstantaneousDelta;

  BOOL notYetCompleted;
  [self HL_advanceTime:incrementalTime extraTime:extraTime notYetCompleted:&notYetCompleted];

  if (node) {
    CGFloat instantaneousDelta = [self HL_instantaneousDelta];
    node.xScale += instantaneousDelta;
    node.yScale += instantaneousDelta;
  }

  return notYetCompleted;
}

- (CGFloat)instantaneousDelta
{
  CGFloat instantaneousDelta = [self HL_instantaneousDelta];
  return instantaneousDelta;
}

- (CGFloat)HL_instantaneousDelta
{
  NSTimeInterval elapsedTime = self.elapsedTime;
  NSTimeInterval duration = self.duration;

  CGFloat instantaneousDelta;
  if (elapsedTime >= duration) {
    instantaneousDelta = _delta - _lastCumulativeDelta;
  } else {
    CGFloat normalTime = elapsedTime / duration;
    instantaneousDelta = _delta * normalTime - _lastCumulativeDelta;
  }
  return instantaneousDelta;
}

@end

@implementation HLScaleXYByAction
{
  CGFloat _deltaX;
  CGFloat _deltaY;
  CGFloat _lastCumulativeDeltaX;
  CGFloat _lastCumulativeDeltaY;
}

- (instancetype)initWithX:(CGFloat)scaleDeltaX y:(CGFloat)scaleDeltaY duration:(NSTimeInterval)duration
{
  self = [super initWithDuration:duration];
  if (self) {
    _deltaX = scaleDeltaX;
    _deltaY = scaleDeltaY;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self) {
    _deltaX = (CGFloat)[aDecoder decodeDoubleForKey:@"deltaX"];
    _deltaY = (CGFloat)[aDecoder decodeDoubleForKey:@"deltaY"];
    _lastCumulativeDeltaX = (CGFloat)[aDecoder decodeDoubleForKey:@"lastCumulativeDeltaX"];
    _lastCumulativeDeltaY = (CGFloat)[aDecoder decodeDoubleForKey:@"lastCumulativeDeltaY"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [super encodeWithCoder:aCoder];
  [aCoder encodeDouble:_deltaX forKey:@"deltaX"];
  [aCoder encodeDouble:_deltaY forKey:@"deltaY"];
  [aCoder encodeDouble:_lastCumulativeDeltaX forKey:@"lastCumulativeDeltaX"];
  [aCoder encodeDouble:_lastCumulativeDeltaY forKey:@"lastCumulativeDeltaY"];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
  HLScaleXYByAction *copy = [super copyWithZone:zone];
  if (copy) {
    copy->_deltaX = _deltaX;
    copy->_deltaY = _deltaY;
    copy->_lastCumulativeDeltaX = _lastCumulativeDeltaX;
    copy->_lastCumulativeDeltaY = _lastCumulativeDeltaY;
  }
  return copy;
}

- (BOOL)HL_update:(NSTimeInterval)incrementalTime node:(SKNode *)node extraTime:(NSTimeInterval *)extraTime
{
  // note: This mechanism chosen in order to avoid floating point drift (in the sum of instantaneous deltas
  // applied to the node or returned by the property) and to support calculation of property .instantaneousDelta*.

  CGFloat lastInstantaneousDeltaX;
  CGFloat lastInstantaneousDeltaY;
  [self HL_instantaneousDeltaX:&lastInstantaneousDeltaX instantaneousDeltaY:&lastInstantaneousDeltaY];
  // note: Always calculate the cumulative by adding the instantaneous, so that we can compensate for the difference
  // between "elasped delta" (normal-elapsed-time * total-delta) and "cumulative delta" (sum of a series of
  // instantaneous-delta).
  _lastCumulativeDeltaX += lastInstantaneousDeltaX;
  _lastCumulativeDeltaY += lastInstantaneousDeltaY;

  BOOL notYetCompleted;
  [self HL_advanceTime:incrementalTime extraTime:extraTime notYetCompleted:&notYetCompleted];

  if (node) {
    CGFloat instantaneousDeltaX;
    CGFloat instantaneousDeltaY;
    [self HL_instantaneousDeltaX:&instantaneousDeltaX instantaneousDeltaY:&instantaneousDeltaY];
    node.xScale += instantaneousDeltaX;
    node.yScale += instantaneousDeltaY;
  }

  return notYetCompleted;
}

- (CGFloat)instantaneousDeltaX
{
  CGFloat instantaneousDeltaX;
  CGFloat instantaneousDeltaY;
  [self HL_instantaneousDeltaX:&instantaneousDeltaX instantaneousDeltaY:&instantaneousDeltaY];
  return instantaneousDeltaX;
}

- (CGFloat)instantaneousDeltaY
{
  CGFloat instantaneousDeltaX;
  CGFloat instantaneousDeltaY;
  [self HL_instantaneousDeltaX:&instantaneousDeltaX instantaneousDeltaY:&instantaneousDeltaY];
  return instantaneousDeltaY;
}

- (void)getInstantaneousDeltaX:(CGFloat *)instantaneousDeltaX instantaneousDeltaY:(CGFloat *)instantaneousDeltaY
{
  [self HL_instantaneousDeltaX:instantaneousDeltaX instantaneousDeltaY:instantaneousDeltaY];
}

- (void)HL_instantaneousDeltaX:(CGFloat *)instantaneousDeltaX instantaneousDeltaY:(CGFloat *)instantaneousDeltaY
{
  NSTimeInterval elapsedTime = self.elapsedTime;
  NSTimeInterval duration = self.duration;

  if (elapsedTime >= duration) {
    *instantaneousDeltaX = _deltaX - _lastCumulativeDeltaX;
    *instantaneousDeltaY = _deltaY - _lastCumulativeDeltaY;
  } else {
    CGFloat normalTime = elapsedTime / duration;
    *instantaneousDeltaX = _deltaX * normalTime - _lastCumulativeDeltaX;
    *instantaneousDeltaY = _deltaY * normalTime - _lastCumulativeDeltaY;
  }
}

@end

@implementation HLScaleToAction
{
  BOOL _isFromSet;
  CGFloat _xFrom;
  CGFloat _yFrom;
  CGFloat _xTo;
  CGFloat _yTo;
}

- (instancetype)initWithXTo:(CGFloat)scaleXTo y:(CGFloat)scaleYTo duration:(NSTimeInterval)duration
{
  self = [super initWithDuration:duration];
  if (self) {
    _isFromSet = NO;
    _xTo = scaleXTo;
    _yTo = scaleYTo;
  }
  return self;
}

- (instancetype)initWithXFrom:(CGFloat)scaleXFrom y:(CGFloat)scaleYFrom xTo:(CGFloat)scaleXTo y:(CGFloat)scaleYTo duration:(NSTimeInterval)duration
{
  self = [super initWithDuration:duration];
  if (self) {
    _isFromSet = YES;
    _xFrom = scaleXFrom;
    _yFrom = scaleYFrom;
    _xTo = scaleXTo;
    _yTo = scaleYTo;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self) {
    _isFromSet = [aDecoder decodeBoolForKey:@"isFromSet"];
    _xFrom = (CGFloat)[aDecoder decodeDoubleForKey:@"xFrom"];
    _yFrom = (CGFloat)[aDecoder decodeDoubleForKey:@"yFrom"];
    _xTo = (CGFloat)[aDecoder decodeDoubleForKey:@"xTo"];
    _yTo = (CGFloat)[aDecoder decodeDoubleForKey:@"yTo"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [super encodeWithCoder:aCoder];
  [aCoder encodeBool:_isFromSet forKey:@"isFromSet"];
  [aCoder encodeDouble:_xFrom forKey:@"xFrom"];
  [aCoder encodeDouble:_yFrom forKey:@"yFrom"];
  [aCoder encodeDouble:_xTo forKey:@"xTo"];
  [aCoder encodeDouble:_yTo forKey:@"yTo"];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
  HLScaleToAction *copy = [super copyWithZone:zone];
  if (copy) {
    copy->_isFromSet = _isFromSet;
    copy->_xFrom = _xFrom;
    copy->_yFrom = _yFrom;
    copy->_xTo = _xTo;
    copy->_yTo = _yTo;
  }
  return copy;
}

- (BOOL)HL_update:(NSTimeInterval)incrementalTime node:(SKNode *)node extraTime:(NSTimeInterval *)extraTime
{
  if (!_isFromSet) {
    if (node) {
      _xFrom = node.xScale;
      _yFrom = node.yScale;
      _isFromSet = YES;
    } else {
      [NSException raise:@"HLActionUninitialized" format:@"HLScaleToAction requires original scale values:"
       " either pass a node to the first update,"
       " or initialize with initWithXFrom:yFrom:xTo:yTo:duration:."];
    }
  }

  BOOL notYetCompleted;
  [self HL_advanceTime:incrementalTime extraTime:extraTime notYetCompleted:&notYetCompleted];

  if (node) {
    CGFloat scaleX;
    CGFloat scaleY;
    [self HL_scaleX:&scaleX scaleY:&scaleY];
    node.xScale = scaleX;
    node.yScale = scaleY;
  }

  return notYetCompleted;
}

- (CGFloat)scaleX
{
  if (!_isFromSet) {
    [NSException raise:@"HLActionUninitialized" format:@"HLScaleToAction requires original scale values:"
     " either pass a node to the first update,"
     " or initialize with initWithXFrom:yFrom:xTo:yTo:duration:."];
  }
  CGFloat scaleX;
  CGFloat scaleY;
  [self HL_scaleX:&scaleX scaleY:&scaleY];
  return scaleX;
}

- (CGFloat)scaleY
{
  if (!_isFromSet) {
    [NSException raise:@"HLActionUninitialized" format:@"HLScaleToAction requires original scale values:"
     " either pass a node to the first update,"
     " or initialize with initWithXFrom:yFrom:xTo:yTo:duration:."];
  }
  CGFloat scaleX;
  CGFloat scaleY;
  [self HL_scaleX:&scaleX scaleY:&scaleY];
  return scaleY;
}

- (void)getScaleX:(CGFloat *)scaleX scaleY:(CGFloat *)scaleY
{
  if (!_isFromSet) {
    [NSException raise:@"HLActionUninitialized" format:@"HLScaleToAction requires original scale values:"
     " either pass a node to the first update,"
     " or initialize with initWithXFrom:yFrom:xTo:yTo:duration:."];
  }
  [self HL_scaleX:scaleX scaleY:scaleY];
}

- (void)HL_scaleX:(CGFloat *)scaleX scaleY:(CGFloat *)scaleY
{
  NSTimeInterval elapsedTime = self.elapsedTime;
  NSTimeInterval duration = self.duration;

  if (elapsedTime >= duration) {
    *scaleX = _xTo;
    *scaleY = _yTo;
  } else {
    CGFloat normalTime = elapsedTime / duration;
    *scaleX = _xFrom * (1.0f - normalTime) + _xTo * normalTime;
    *scaleY = _yFrom * (1.0f - normalTime) + _yTo * normalTime;
  }
}

@end

@implementation HLFadeAlphaByAction
{
  CGFloat _delta;
  CGFloat _lastCumulativeDelta;
}

- (instancetype)initWithAlpha:(CGFloat)alphaDelta duration:(NSTimeInterval)duration
{
  self = [super initWithDuration:duration];
  if (self) {
    _delta = alphaDelta;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self) {
    _delta = (CGFloat)[aDecoder decodeDoubleForKey:@"delta"];
    _lastCumulativeDelta = (CGFloat)[aDecoder decodeDoubleForKey:@"lastCumulativeDelta"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [super encodeWithCoder:aCoder];
  [aCoder encodeDouble:_delta forKey:@"delta"];
  [aCoder encodeDouble:_lastCumulativeDelta forKey:@"lastCumulativeDelta"];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
  HLFadeAlphaByAction *copy = [super copyWithZone:zone];
  if (copy) {
    copy->_delta = _delta;
    copy->_lastCumulativeDelta = _lastCumulativeDelta;
  }
  return copy;
}

- (BOOL)HL_update:(NSTimeInterval)incrementalTime node:(SKNode *)node extraTime:(NSTimeInterval *)extraTime
{
  // note: This mechanism chosen in order to avoid floating point drift (in the sum of instantaneous deltas
  // applied to the node or returned by the property) and to support calculation of property .instantaneousDelta.

  CGFloat lastInstantaneousDelta = [self HL_instantaneousDelta];
  // note: Always calculate the cumulative by adding the instantaneous, so that we can compensate for the difference
  // between "elasped delta" (normal-elapsed-time * total-delta) and "cumulative delta" (sum of a series of
  // instantaneous-delta).
  _lastCumulativeDelta += lastInstantaneousDelta;

  BOOL notYetCompleted;
  [self HL_advanceTime:incrementalTime extraTime:extraTime notYetCompleted:&notYetCompleted];

  if (node) {
    CGFloat instantaneousDelta = [self HL_instantaneousDelta];
    node.alpha += instantaneousDelta;
  }

  return notYetCompleted;
}

- (CGFloat)instantaneousDelta
{
  CGFloat instantaneousDelta = [self HL_instantaneousDelta];
  return instantaneousDelta;
}

- (CGFloat)HL_instantaneousDelta
{
  NSTimeInterval elapsedTime = self.elapsedTime;
  NSTimeInterval duration = self.duration;

  CGFloat instantaneousDelta;
  if (elapsedTime >= duration) {
    instantaneousDelta = _delta - _lastCumulativeDelta;
  } else {
    CGFloat normalTime = elapsedTime / duration;
    instantaneousDelta = _delta * normalTime - _lastCumulativeDelta;
  }
  return instantaneousDelta;
}

@end

@implementation HLFadeAlphaToAction
{
  BOOL _isAlphaFromSet;
  CGFloat _alphaFrom;
  CGFloat _alphaTo;
}

- (instancetype)initWithAlphaTo:(CGFloat)alphaTo duration:(NSTimeInterval)duration
{
  self = [super initWithDuration:duration];
  if (self) {
    _isAlphaFromSet = NO;
    _alphaTo = alphaTo;
  }
  return self;
}

- (instancetype)initWithAlphaFrom:(CGFloat)alphaFrom to:(CGFloat)alphaTo duration:(NSTimeInterval)duration
{
  self = [super initWithDuration:duration];
  if (self) {
    _isAlphaFromSet = YES;
    _alphaFrom = alphaFrom;
    _alphaTo = alphaTo;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self) {
    _isAlphaFromSet = [aDecoder decodeBoolForKey:@"isAlphaFromSet"];
    _alphaFrom = (CGFloat)[aDecoder decodeDoubleForKey:@"alphaFrom"];
    _alphaTo = (CGFloat)[aDecoder decodeDoubleForKey:@"alphaTo"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [super encodeWithCoder:aCoder];
  [aCoder encodeBool:_isAlphaFromSet forKey:@"isAlphaFromSet"];
  [aCoder encodeDouble:_alphaFrom forKey:@"alphaFrom"];
  [aCoder encodeDouble:_alphaTo forKey:@"alphaTo"];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
  HLFadeAlphaToAction *copy = [super copyWithZone:zone];
  if (copy) {
    copy->_isAlphaFromSet = _isAlphaFromSet;
    copy->_alphaFrom = _alphaFrom;
    copy->_alphaTo = _alphaTo;
  }
  return copy;
}

- (BOOL)HL_update:(NSTimeInterval)incrementalTime node:(SKNode *)node extraTime:(NSTimeInterval *)extraTime
{
  if (!_isAlphaFromSet) {
    if (node) {
      _alphaFrom = node.alpha;
      _isAlphaFromSet = YES;
    } else {
      [NSException raise:@"HLActionUninitialized" format:@"HLFadeAlphaToAction requires an alpha-from:"
       " either pass a node to the first update,"
       " or initialize with initWithAlphaFrom:to:duration:."];
    }
  }

  BOOL notYetCompleted;
  [self HL_advanceTime:incrementalTime extraTime:extraTime notYetCompleted:&notYetCompleted];

  if (node) {
    node.alpha = [self HL_alpha];
  }

  return notYetCompleted;
}

- (CGFloat)alpha
{
  if (!_isAlphaFromSet) {
    [NSException raise:@"HLActionUninitialized" format:@"HLFadeAlphaToAction requires an alpha-from:"
     " either pass a node to the first update,"
     " or initialize with initWithAlphaFrom:to:duration:."];
  }
  return [self HL_alpha];
}

- (CGFloat)HL_alpha
{
  NSTimeInterval elapsedTime = self.elapsedTime;
  NSTimeInterval duration = self.duration;

  if (elapsedTime >= duration) {
    return _alphaTo;
  }

  CGFloat normalTime = elapsedTime / duration;

  return _alphaFrom * (1.0f - normalTime) + _alphaTo * normalTime;
}

@end

@implementation HLColorizeAction
{
  BOOL _isColorAnimated;
  SKColor *_colorFrom;
  SKColor *_colorTo;
  BOOL _isColorBlendFactorFromSet;
  CGFloat _colorBlendFactorFrom;
  CGFloat _colorBlendFactorTo;
}

- (instancetype)initWithColor:(SKColor *)colorTo
             colorBlendFactor:(CGFloat)colorBlendFactorTo
                     duration:(NSTimeInterval)duration
{
  if (!colorTo) {
    [NSException raise:@"HLActionInvalid" format:@"A colorize action created with this initializer requires non-nil colors."];
  }
  self = [super initWithDuration:duration];
  if (self) {
    _isColorAnimated = YES;
    _colorTo = colorTo;
    _isColorBlendFactorFromSet = NO;
    _colorBlendFactorTo = colorBlendFactorTo;
  }
  return self;
}

- (instancetype)initWithColorFrom:(SKColor *)colorFrom
                               to:(SKColor *)colorTo
             colorBlendFactorFrom:(CGFloat)colorBlendFactorFrom
                               to:(CGFloat)colorBlendFactorTo
                         duration:(NSTimeInterval)duration
{
  if (!colorTo) {
    [NSException raise:@"HLActionInvalid" format:@"A colorize action created with this initializer requires non-nil colors."];
  }
  self = [super initWithDuration:duration];
  if (self) {
    _isColorAnimated = YES;
    _colorFrom = colorFrom;
    _colorTo = colorTo;
    _isColorBlendFactorFromSet = YES;
    _colorBlendFactorFrom = colorBlendFactorFrom;
    _colorBlendFactorTo = colorBlendFactorTo;
  }
  return self;
}

- (instancetype)initWithColorBlendFactor:(CGFloat)colorBlendFactorTo
                                duration:(NSTimeInterval)duration
{
  self = [super initWithDuration:duration];
  if (self) {
    _isColorAnimated = NO;
    _isColorBlendFactorFromSet = NO;
    _colorBlendFactorTo = colorBlendFactorTo;
  }
  return self;
}

- (instancetype)initWithColorBlendFactorFrom:(CGFloat)colorBlendFactorFrom
                                          to:(CGFloat)colorBlendFactorTo
                                    duration:(NSTimeInterval)duration
{
  self = [super initWithDuration:duration];
  if (self) {
    _isColorAnimated = NO;
    _isColorBlendFactorFromSet = YES;
    _colorBlendFactorFrom = colorBlendFactorFrom;
    _colorBlendFactorTo = colorBlendFactorTo;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self) {
    _isColorAnimated = [aDecoder decodeBoolForKey:@"isColorAnimated"];
    if (_isColorAnimated) {
      _colorFrom = [aDecoder decodeObjectForKey:@"colorFrom"];
      _colorTo = [aDecoder decodeObjectForKey:@"colorTo"];
    }
    _isColorBlendFactorFromSet = [aDecoder decodeBoolForKey:@"isColorBlendFactorFromSet"];
    _colorBlendFactorFrom = (CGFloat)[aDecoder decodeDoubleForKey:@"colorBlendFactorFrom"];
    _colorBlendFactorTo = (CGFloat)[aDecoder decodeDoubleForKey:@"colorBlendFactorTo"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [super encodeWithCoder:aCoder];
  [aCoder encodeBool:_isColorAnimated forKey:@"isColorAnimated"];
  if (_isColorAnimated) {
    [aCoder encodeObject:_colorFrom forKey:@"colorFrom"];
    [aCoder encodeObject:_colorTo forKey:@"colorTo"];
  }
  [aCoder encodeBool:_isColorBlendFactorFromSet forKey:@"isColorBlendFactorFromSet"];
  [aCoder encodeDouble:_colorBlendFactorFrom forKey:@"colorBlendFactorFrom"];
  [aCoder encodeDouble:_colorBlendFactorTo forKey:@"colorBlendFactorTo"];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
  HLColorizeAction *copy = [super copyWithZone:zone];
  if (copy) {
    copy->_isColorAnimated = _isColorAnimated;
    copy->_colorFrom = _colorFrom;
    copy->_colorTo = _colorTo;
    copy->_isColorBlendFactorFromSet = _isColorBlendFactorFromSet;
    copy->_colorBlendFactorFrom = _colorBlendFactorFrom;
    copy->_colorBlendFactorTo = _colorBlendFactorTo;
  }
  return copy;
}

- (BOOL)HL_update:(NSTimeInterval)incrementalTime node:(SKNode *)node extraTime:(NSTimeInterval *)extraTime
{
  // note: Should use duck-typing here, or check for SKSpriteNode?
  BOOL haveSpriteNode = (node && [node isKindOfClass:[SKSpriteNode class]]);

  if (_isColorAnimated && !_colorFrom) {
    if (haveSpriteNode) {
      _colorFrom = ((SKSpriteNode *)node).color;
    } else {
      [NSException raise:@"HLActionUninitialized" format:@"HLColorizeAction requires an initial color:"
       " either pass a sprite node to the first update,"
       " or initialize with initWithColorFrom:to:colorBlendFactorFrom:to:duration."];
    }
  }
  if (!_isColorBlendFactorFromSet) {
    if (haveSpriteNode) {
      _colorBlendFactorFrom = ((SKSpriteNode *)node).colorBlendFactor;
      _isColorBlendFactorFromSet = YES;
    } else {
      [NSException raise:@"HLActionUninitialized" format:@"HLColorizeAction requires an initial color blend factor:"
       " either pass a sprite node to the first update,"
       " or initialize with initWithColorBlendFactorFrom:to:duration."];
    }
  }

  BOOL notYetCompleted;
  [self HL_advanceTime:incrementalTime extraTime:extraTime notYetCompleted:&notYetCompleted];

  if (haveSpriteNode) {
    SKColor *color;
    CGFloat colorBlendFactor;
    [self HL_colorizeWithColor:&color colorBlendFactor:&colorBlendFactor];
    if (_isColorAnimated) {
      ((SKSpriteNode *)node).color = color;
    }
    ((SKSpriteNode *)node).colorBlendFactor = colorBlendFactor;
  }

  return notYetCompleted;
}

- (SKColor *)color
{
  if (!_isColorAnimated) {
    return nil;
  }
  if (!_colorFrom) {
    [NSException raise:@"HLActionUninitialized" format:@"HLColorizeAction requires an initial color:"
     " either pass a sprite node to the first update,"
     " or initialize with initWithColorFrom:to:colorBlendFactorFrom:to:duration."];
  }
  SKColor *color;
  CGFloat colorBlendFactor;
  [self HL_colorizeWithColor:&color colorBlendFactor:&colorBlendFactor];
  return color;
}

- (CGFloat)colorBlendFactor
{
  if (!_isColorBlendFactorFromSet) {
    [NSException raise:@"HLActionUninitialized" format:@"HLColorizeAction requires an initial color blend factor:"
     " either pass a sprite node to the first update,"
     " or initialize with initWithColorBlendFactorFrom:to:duration."];
  }
  SKColor *color;
  CGFloat colorBlendFactor;
  [self HL_colorizeWithColor:&color colorBlendFactor:&colorBlendFactor];
  return colorBlendFactor;
}

- (void)getColor:(SKColor * __autoreleasing *)color colorBlendFactor:(CGFloat *)colorBlendFactor
{
  if (!_isColorAnimated && !_colorFrom) {
    [NSException raise:@"HLActionUninitialized" format:@"HLColorizeAction requires an initial color:"
     " either pass a sprite node to the first update,"
     " or initialize with initWithColorFrom:to:colorBlendFactorFrom:to:duration."];
  }
  if (!_isColorBlendFactorFromSet) {
    [NSException raise:@"HLActionUninitialized" format:@"HLColorizeAction requires an initial color blend factor:"
     " either pass a sprite node to the first update,"
     " or initialize with initWithColorBlendFactorFrom:to:duration."];
  }
  [self HL_colorizeWithColor:color colorBlendFactor:colorBlendFactor];
}

- (void)HL_colorizeWithColor:(SKColor * __autoreleasing *)color colorBlendFactor:(CGFloat *)colorBlendFactor
{
  NSTimeInterval elapsedTime = self.elapsedTime;
  NSTimeInterval duration = self.duration;

  if (elapsedTime >= duration) {
    *colorBlendFactor = _colorBlendFactorTo;
    *color = _colorTo;
    return;
  }

  CGFloat normalTime = elapsedTime / duration;

  *colorBlendFactor = _colorBlendFactorFrom * (1.0f - normalTime) + _colorBlendFactorTo * normalTime;
  if (_isColorAnimated) {
    assert(_colorTo);
    CGFloat colorToRed;
    CGFloat colorToGreen;
    CGFloat colorToBlue;
    CGFloat colorToAlpha;
    [_colorTo getRed:&colorToRed green:&colorToGreen blue:&colorToBlue alpha:&colorToAlpha];
    assert(_colorFrom);
    CGFloat colorFromRed;
    CGFloat colorFromGreen;
    CGFloat colorFromBlue;
    CGFloat colorFromAlpha;
    [_colorFrom getRed:&colorFromRed green:&colorFromGreen blue:&colorFromBlue alpha:&colorFromAlpha];
    *color = [SKColor colorWithRed:(colorFromRed * (1.0f - normalTime) + colorToRed * normalTime)
                             green:(colorFromGreen * (1.0f - normalTime) + colorToGreen * normalTime)
                              blue:(colorFromBlue * (1.0f - normalTime) + colorToBlue * normalTime)
                             alpha:(colorFromAlpha * (1.0f - normalTime) + colorToAlpha * normalTime)];
  }
}

@end

@implementation HLAnimateTexturesAction
{
  NSTimeInterval _timePerFrame;
  BOOL _resize;
  BOOL _restore;
  SKTexture *_restoreTexture;
  BOOL _isRestoreTextureSpecified;
}

- (instancetype)initWithTextures:(NSArray *)textures timePerFrame:(CGFloat)timePerFrame resize:(BOOL)resize restore:(BOOL)restore
{
  NSUInteger texturesCount = [textures count];
  if (!textures || texturesCount == 0) {
    [NSException raise:@"HLActionInvalid" format:@"An animate-textures action must be created with at least one texture."];
  }
  if (timePerFrame <= 0.0) {
    [NSException raise:@"HLActionInvalid" format:@"An animate-textures action must have a positive time per frame."];
  }
  self = [super initWithDuration:(timePerFrame * texturesCount)];
  if (self) {
    _textures = textures;
    _timePerFrame = timePerFrame;
    _resize = resize;
    _restore = restore;
    _restoreTexture = nil;
    _isRestoreTextureSpecified = NO;
  }
  return self;
}

- (instancetype)initWithTextures:(NSArray *)textures timePerFrame:(CGFloat)timePerFrame resize:(BOOL)resize restoreTexture:(SKTexture *)restoreTexture
{
  NSUInteger texturesCount = [textures count];
  if (!textures || texturesCount == 0) {
    [NSException raise:@"HLActionInvalid" format:@"An animate-textures action must be created with at least one texture."];
  }
  if (timePerFrame <= 0.0) {
    [NSException raise:@"HLActionInvalid" format:@"An animate-textures action must have a positive time per frame."];
  }
  self = [super initWithDuration:(timePerFrame * texturesCount)];
  if (self) {
    _textures = textures;
    _timePerFrame = timePerFrame;
    _resize = resize;
    _restore = YES;
    _restoreTexture = restoreTexture;
    // note: Can't just use a nil test of _restoreTexture, since _restoreTexture might intentionally be nil.
    _isRestoreTextureSpecified = YES;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self) {
    _textures = [aDecoder decodeObjectForKey:@"textures"];
    _timePerFrame = [aDecoder decodeDoubleForKey:@"timePerFrame"];
    if ([aDecoder containsValueForKey:@"resize"]) {
      _resize = [aDecoder decodeBoolForKey:@"resize"];
    } else {
      _resize = NO;
    }
    if ([aDecoder containsValueForKey:@"restore"]) {
      _restore = [aDecoder decodeBoolForKey:@"restore"];
      _restoreTexture = [aDecoder decodeObjectForKey:@"restoreTexture"];
      _isRestoreTextureSpecified = [aDecoder decodeBoolForKey:@"isRestoreTextureSpecified"];
    } else {
      _restore = NO;
      _restoreTexture = nil;
    }
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [super encodeWithCoder:aCoder];
  [aCoder encodeObject:_textures forKey:@"textures"];
  [aCoder encodeDouble:_timePerFrame forKey:@"timePerFrame"];
  if (_resize) {
    [aCoder encodeBool:_resize forKey:@"resize"];
  }
  if (_restore) {
    [aCoder encodeBool:_restore forKey:@"restore"];
    [aCoder encodeObject:_restoreTexture forKey:@"restoreTexture"];
    [aCoder encodeBool:_isRestoreTextureSpecified forKey:@"isRestoreTextureSpecified"];
  }
}

- (instancetype)copyWithZone:(NSZone *)zone
{
  HLAnimateTexturesAction *copy = [super copyWithZone:zone];
  if (copy) {
    // note: I can't think of a reason to copy either the textures array or
    // the textures themselves.
    copy->_textures = _textures;
    copy->_timePerFrame = _timePerFrame;
    copy->_resize = _resize;
    copy->_restore = _restore;
    copy->_restoreTexture = _restoreTexture;
    copy->_isRestoreTextureSpecified = _isRestoreTextureSpecified;
  }
  return copy;
}

- (BOOL)HL_update:(NSTimeInterval)incrementalTime node:(SKNode *)node extraTime:(NSTimeInterval *)extraTime
{
  // note: Should use duck-typing here, or check for SKSpriteNode?
  BOOL haveTexturedNode = (node && [node isKindOfClass:[SKSpriteNode class]]);

  // note: The intention is that we restore texture to `nil` if the node originally had no texture,
  // so can't use nil-state of _restoreTexture to mean anything here; need separate flag.
  if (_restore && !_isRestoreTextureSpecified) {
    if (haveTexturedNode) {
      _restoreTexture = ((SKSpriteNode *)node).texture;
      _isRestoreTextureSpecified = YES;
    } else {
      [NSException raise:@"HLActionUninitialized" format:@"The restore feature of HLAnimateTexturesAction requires an original texture:"
       " either pass a sprite node to the first update,"
       " or initialize with initWithTextures:timePerFrame:resize:restoreTexture:."];
    }
  }

  BOOL notYetCompleted;
  [self HL_advanceTime:incrementalTime extraTime:extraTime notYetCompleted:&notYetCompleted];

  // note: There's a tradeoff for calculating and storing textureIndex.  If we calculate and store on update, then
  // it will have to be stored for .texture and .textureIndex, and then explicitly recomputed if .timingMode changes
  // (or else wait until the next update).  If we do it on-demand, then it will have to be done on-demand for node
  // here and .textureIndex and .texture.  A bit sloppy and unnecessary-feeling either way.

  // note: A related problem: If last-set texture/index is not remembered from call to call, then node.texture gets
  // set on every update, resetting the same texture repeatedly during a frame.  This seems unpleasant, and yet from
  // tests it appears that's what SKAction animateWithTextures does.  A good way to avoid that behavior, if desired,
  // would be to calculate and store textureIndex, and not set texture unless textureIndex changes.  (A _hasBeenUpdated
  // variable would also be necessary, or else a sentinel value for _textureIndex, so that the texture is set on the
  // first update.)

  if (haveTexturedNode) {
    SKTexture *texture;
    if (notYetCompleted || !_restore) {
      NSUInteger textureIndex = [self HL_textureIndex];
      texture = _textures[textureIndex];
    } else {
      texture = _restoreTexture;
    }
    if (texture != ((SKSpriteNode *)node).texture) {
      ((SKSpriteNode *)node).texture = texture;
      if (_resize) {
        ((SKSpriteNode *)node).size = texture.size;
      }
    }
  }

  return notYetCompleted;
}

- (SKTexture *)texture
{
  // note: I resent this check, which should only be relevant for the single call when this action has
  // completed but before it is discarded by the owner.  Can we put the responsibility for this on the
  // caller, something like requiring she writes:
  //
  //         if ([action update:incrementalTime node:nil] || !action.restore) {
  //           // use action.texture
  //         } else {
  //           // use action.restoreTexture
  //         }
  //
  // After all, that's required for a caller who uses .textureIndex rather than .texture, right?
  // Unless we start returning a special value for .textureIndex (like equal to the textures count
  // when we've completed).
  if (_restoreTexture && self.elapsedTimeLinear >= self.duration) {
    return _restoreTexture;
  } else {
    NSUInteger textureIndex = [self HL_textureIndex];
    return _textures[textureIndex];
  }
}

- (NSUInteger)textureIndex
{
  NSUInteger textureIndex = [self HL_textureIndex];
  return textureIndex;
}

- (NSUInteger)HL_textureIndex
{
  NSTimeInterval elapsedTime = self.elapsedTime;

  // note: elapsedTime is constrained to be non-negative, and _timePerFrame is constrained to be positive,
  // which makes this calculation remarkably free of edge cases.
  assert(elapsedTime >= 0.0 && _timePerFrame > 0.0);
  NSUInteger textureIndex = (NSUInteger)(elapsedTime / _timePerFrame);

  // note: Slight preference for using textures count rather than duration to do the bounds check here.
  // After all, our duration was derived from the count, not the other way around.
  NSUInteger texturesCount = [_textures count];
  if (textureIndex >= texturesCount) {
    textureIndex = texturesCount - 1;
  }

  return textureIndex;
}

@end

@implementation HLLoopTexturesAction
{
  NSTimeInterval _timePerFrame;
  BOOL _resize;
  NSUInteger _startingTextureIndex;
}

- (instancetype)initWithTextures:(NSArray *)textures timePerFrame:(CGFloat)timePerFrame resize:(BOOL)resize startingAt:(NSUInteger)startingTextureIndex
{
  NSUInteger texturesCount = [textures count];
  if (!textures || texturesCount == 0) {
    [NSException raise:@"HLActionInvalid" format:@"A loop-textures action must be created with at least one texture."];
  }
  if (timePerFrame <= 0.0) {
    [NSException raise:@"HLActionInvalid" format:@"A loop-textures action must have a positive time per frame."];
  }
  self = [super initWithDuration:0.0];
  if (self) {
    _textures = textures;
    _timePerFrame = timePerFrame;
    _resize = resize;
    _startingTextureIndex = startingTextureIndex;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self) {
    _textures = [aDecoder decodeObjectForKey:@"textures"];
    _timePerFrame = [aDecoder decodeDoubleForKey:@"timePerFrame"];
    if ([aDecoder containsValueForKey:@"resize"]) {
      _resize = [aDecoder decodeBoolForKey:@"resize"];
    } else {
      _resize = NO;
    }
    if ([aDecoder containsValueForKey:@"startingTextureIndex"]) {
      _startingTextureIndex = (NSUInteger)[aDecoder decodeIntegerForKey:@"startingTextureIndex"];
    } else {
      _startingTextureIndex = 0;
    }
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [super encodeWithCoder:aCoder];
  [aCoder encodeObject:_textures forKey:@"textures"];
  [aCoder encodeDouble:_timePerFrame forKey:@"timePerFrame"];
  if (_resize) {
    [aCoder encodeBool:_resize forKey:@"resize"];
  }
  if (_startingTextureIndex != 0) {
    [aCoder encodeInteger:(NSInteger)_startingTextureIndex forKey:@"startingTextureIndex"];
  }
}

- (instancetype)copyWithZone:(NSZone *)zone
{
  HLLoopTexturesAction *copy = [super copyWithZone:zone];
  if (copy) {
    // note: I can't think of a reason to copy either the textures array or
    // the textures themselves.
    copy->_textures = _textures;
    copy->_timePerFrame = _timePerFrame;
    copy->_resize = _resize;
    copy->_startingTextureIndex = _startingTextureIndex;
  }
  return copy;
}

- (BOOL)HL_update:(NSTimeInterval)incrementalTime node:(SKNode *)node extraTime:(NSTimeInterval *)extraTime
{
  [self HL_advanceTime:incrementalTime];

  // note: See note in HLAnimateTexturesAction HL_update; for now, calculate texture index on-demand.

  // note: Should use duck-typing here, or check for SKSpriteNode?
  if (node && [node isKindOfClass:[SKSpriteNode class]]) {
    NSUInteger textureIndex = [self HL_textureIndex];
    SKTexture *texture = _textures[textureIndex];
    if (texture != ((SKSpriteNode *)node).texture) {
      ((SKSpriteNode *)node).texture = texture;
      if (_resize) {
        ((SKSpriteNode *)node).size = texture.size;
      }
    }
  }

  *extraTime = 0.0;
  return YES;
}

- (SKTexture *)texture
{
  NSUInteger textureIndex = [self HL_textureIndex];
  return _textures[textureIndex];
}

- (NSUInteger)textureIndex
{
  NSUInteger textureIndex = [self HL_textureIndex];
  return textureIndex;
}

- (NSUInteger)HL_textureIndex
{
  NSTimeInterval elapsedTime = self.elapsedTime;

  // note: elapsedTime is constrained to be non-negative, and _timePerFrame is constrained to be positive,
  // which makes this calculation remarkably free of edge cases.
  assert(elapsedTime >= 0.0 && _timePerFrame > 0.0);
  NSUInteger elapsedTextureIndex = (NSUInteger)(elapsedTime / _timePerFrame);
  NSUInteger textureIndex = (elapsedTextureIndex + _startingTextureIndex) % [_textures count];

  return textureIndex;
}

@end

@implementation HLRemoveFromParentAction

- (instancetype)init
{
  self = [super initWithDuration:0.0];
  return self;
}

- (BOOL)HL_update:(NSTimeInterval)incrementalTime node:(SKNode *)node extraTime:(NSTimeInterval *)extraTime
{
  [self HL_advanceTime:incrementalTime];
  if (node && node.parent) {
    [node removeFromParent];
  }
  *extraTime = incrementalTime;
  return NO;
}

@end

@implementation HLPerformSelectorWeakAction
{
  __weak id _weakTarget;
  SEL _selector;
}

- (instancetype)initWithWeakTarget:(id)weakTarget selector:(SEL)selector
{
  self = [super initWithDuration:0.0];
  if (self) {
    _weakTarget = weakTarget;
    _selector = selector;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self) {
    _weakTarget = [aDecoder decodeObjectForKey:@"weakTarget"];
    _selector = NSSelectorFromString([aDecoder decodeObjectForKey:@"selector"]);
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [super encodeWithCoder:aCoder];
  [aCoder encodeConditionalObject:_weakTarget forKey:@"weakTarget"];
  [aCoder encodeObject:NSStringFromSelector(_selector) forKey:@"selector"];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
  HLPerformSelectorWeakAction *copy = [super copyWithZone:zone];
  if (copy) {
    copy->_weakTarget = _weakTarget;
    copy->_selector = _selector;
  }
  return copy;
}

- (BOOL)HL_update:(NSTimeInterval)incrementalTime node:(SKNode *)node extraTime:(NSTimeInterval *)extraTime
{
  // note: See note in [HLAction HL_update] for handling action completion and removal.  In
  // short, an action must be allowed a final update call regardless of its elapsed time
  // and duration; it's only completed when its update returns NO.  Further, when it
  // returns NO, then it won't be called again.  For our purposes, we take advantage of
  // this to assert that we'll do one (and only one) callback to our target.
  assert(self.elapsedTime == 0.0);

  [self HL_advanceTime:incrementalTime];

  id target = _weakTarget;
  if (target) {
    IMP imp = [target methodForSelector:_selector];
    void (*func)(id, SEL) = (void (*)(id, SEL))imp;
    func(target, _selector);
  }

  *extraTime = incrementalTime;
  return NO;
}

@end

@implementation HLPerformSelectorWeakSingleAction
{
  __weak id _weakTarget;
  SEL _selector;
  id _argument;
}

- (instancetype)initWithWeakTarget:(id)weakTarget selector:(SEL)selector argument:(id)argument
{
  self = [super initWithDuration:0.0];
  if (self) {
    _weakTarget = weakTarget;
    _selector = selector;
    _argument = argument;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self) {
    _weakTarget = [aDecoder decodeObjectForKey:@"weakTarget"];
    _selector = NSSelectorFromString([aDecoder decodeObjectForKey:@"selector"]);
    _argument = [aDecoder decodeObjectForKey:@"argument"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [super encodeWithCoder:aCoder];
  [aCoder encodeConditionalObject:_weakTarget forKey:@"weakTarget"];
  [aCoder encodeObject:NSStringFromSelector(_selector) forKey:@"selector"];
  [aCoder encodeObject:_argument forKey:@"argument"];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
  HLPerformSelectorWeakSingleAction *copy = [super copyWithZone:zone];
  if (copy) {
    copy->_weakTarget = _weakTarget;
    copy->_selector = _selector;
    copy->_argument = _argument;
  }
  return copy;
}

- (BOOL)HL_update:(NSTimeInterval)incrementalTime node:(SKNode *)node extraTime:(NSTimeInterval *)extraTime
{
  // note: See note in [HLAction HL_update] for handling action completion and removal.  In
  // short, an action must be allowed a final update call regardless of its elapsed time
  // and duration; it's only completed when its update returns NO.  Further, when it
  // returns NO, then it won't be called again.  For our purposes, we take advantage of
  // this to assert that we'll do one (and only one) callback to our target.
  assert(self.elapsedTime == 0.0);

  [self HL_advanceTime:incrementalTime];

  id target = _weakTarget;
  if (target) {
    IMP imp = [target methodForSelector:_selector];
    void (*func)(id, SEL, id) = (void (*)(id, SEL, id))imp;
    func(target, _selector, _argument);
  }

  *extraTime = incrementalTime;
  return NO;
}

@end

@implementation HLPerformSelectorWeakDoubleAction
{
  __weak id _weakTarget;
  SEL _selector;
  id _argument1;
  id _argument2;
}

- (instancetype)initWithWeakTarget:(id)weakTarget selector:(SEL)selector argument1:(id)argument1 argument2:(id)argument2
{
  self = [super initWithDuration:0.0];
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
  self = [super initWithCoder:aDecoder];
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
  [super encodeWithCoder:aCoder];
  [aCoder encodeConditionalObject:_weakTarget forKey:@"weakTarget"];
  [aCoder encodeObject:NSStringFromSelector(_selector) forKey:@"selector"];
  [aCoder encodeObject:_argument1 forKey:@"argument1"];
  [aCoder encodeObject:_argument2 forKey:@"argument2"];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
  HLPerformSelectorWeakDoubleAction *copy = [super copyWithZone:zone];
  if (copy) {
    copy->_weakTarget = _weakTarget;
    copy->_selector = _selector;
    copy->_argument1 = _argument1;
    copy->_argument2 = _argument2;
  }
  return copy;
}

- (BOOL)HL_update:(NSTimeInterval)incrementalTime node:(SKNode *)node extraTime:(NSTimeInterval *)extraTime
{
  // note: See note in [HLAction HL_update] for handling action completion and removal.  In
  // short, an action must be allowed a final update call regardless of its elapsed time
  // and duration; it's only completed when its update returns NO.  Further, when it
  // returns NO, then it won't be called again.  For our purposes, we take advantage of
  // this to assert that we'll do one (and only one) callback to our target.
  assert(self.elapsedTime == 0.0);

  [self HL_advanceTime:incrementalTime];

  id target = _weakTarget;
  if (target) {
    IMP imp = [target methodForSelector:_selector];
    void (*func)(id, SEL, id, id) = (void (*)(id, SEL, id, id))imp;
    func(target, _selector, _argument1, _argument2);
  }

  *extraTime = incrementalTime;
  return NO;
}

@end

@implementation HLPerformSelectorStrongAction
{
  id _strongTarget;
  SEL _selector;
}

- (instancetype)initWithStrongTarget:(id)strongTarget selector:(SEL)selector
{
  self = [super initWithDuration:0.0];
  if (self) {
    _strongTarget = strongTarget;
    _selector = selector;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self) {
    _strongTarget = [aDecoder decodeObjectForKey:@"strongTarget"];
    _selector = NSSelectorFromString([aDecoder decodeObjectForKey:@"selector"]);
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [super encodeWithCoder:aCoder];
  [aCoder encodeObject:_strongTarget forKey:@"strongTarget"];
  [aCoder encodeObject:NSStringFromSelector(_selector) forKey:@"selector"];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
  HLPerformSelectorStrongAction *copy = [super copyWithZone:zone];
  if (copy) {
    copy->_strongTarget = _strongTarget;
    copy->_selector = _selector;
  }
  return copy;
}

- (BOOL)HL_update:(NSTimeInterval)incrementalTime node:(SKNode *)node extraTime:(NSTimeInterval *)extraTime
{
  // note: See note in [HLAction HL_update] for handling action completion and removal.  In
  // short, an action must be allowed a final update call regardless of its elapsed time
  // and duration; it's only completed when its update returns NO.  Further, when it
  // returns NO, then it won't be called again.  For our purposes, we take advantage of
  // this to assert that we'll do one (and only one) callback to our target.
  assert(self.elapsedTime == 0.0);

  [self HL_advanceTime:incrementalTime];

  id target = _strongTarget;
  if (target) {
    IMP imp = [target methodForSelector:_selector];
    void (*func)(id, SEL) = (void (*)(id, SEL))imp;
    func(target, _selector);
  }

  *extraTime = incrementalTime;
  return NO;
}

@end

@implementation HLPerformSelectorStrongSingleAction
{
  id _strongTarget;
  SEL _selector;
  id _argument;
}

- (instancetype)initWithStrongTarget:(id)strongTarget selector:(SEL)selector argument:(id)argument
{
  self = [super initWithDuration:0.0];
  if (self) {
    _strongTarget = strongTarget;
    _selector = selector;
    _argument = argument;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self) {
    _strongTarget = [aDecoder decodeObjectForKey:@"strongTarget"];
    _selector = NSSelectorFromString([aDecoder decodeObjectForKey:@"selector"]);
    _argument = [aDecoder decodeObjectForKey:@"argument"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [super encodeWithCoder:aCoder];
  [aCoder encodeObject:_strongTarget forKey:@"strongTarget"];
  [aCoder encodeObject:NSStringFromSelector(_selector) forKey:@"selector"];
  [aCoder encodeObject:_argument forKey:@"argument"];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
  HLPerformSelectorStrongSingleAction *copy = [super copyWithZone:zone];
  if (copy) {
    copy->_strongTarget = _strongTarget;
    copy->_selector = _selector;
    copy->_argument = _argument;
  }
  return copy;
}

- (BOOL)HL_update:(NSTimeInterval)incrementalTime node:(SKNode *)node extraTime:(NSTimeInterval *)extraTime
{
  // note: See note in [HLAction HL_update] for handling action completion and removal.  In
  // short, an action must be allowed a final update call regardless of its elapsed time
  // and duration; it's only completed when its update returns NO.  Further, when it
  // returns NO, then it won't be called again.  For our purposes, we take advantage of
  // this to assert that we'll do one (and only one) callback to our target.
  assert(self.elapsedTime == 0.0);

  [self HL_advanceTime:incrementalTime];

  id target = _strongTarget;
  if (target) {
    IMP imp = [target methodForSelector:_selector];
    void (*func)(id, SEL, id) = (void (*)(id, SEL, id))imp;
    func(target, _selector, _argument);
  }

  *extraTime = incrementalTime;
  return NO;
}

@end

@implementation HLPerformSelectorStrongDoubleAction
{
  id _strongTarget;
  SEL _selector;
  id _argument1;
  id _argument2;
}

- (instancetype)initWithStrongTarget:(id)strongTarget selector:(SEL)selector argument1:(id)argument1 argument2:(id)argument2
{
  self = [super initWithDuration:0.0];
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
  self = [super initWithCoder:aDecoder];
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
  [super encodeWithCoder:aCoder];
  [aCoder encodeObject:_strongTarget forKey:@"strongTarget"];
  [aCoder encodeObject:NSStringFromSelector(_selector) forKey:@"selector"];
  [aCoder encodeObject:_argument1 forKey:@"argument1"];
  [aCoder encodeObject:_argument2 forKey:@"argument2"];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
  HLPerformSelectorStrongDoubleAction *copy = [super copyWithZone:zone];
  if (copy) {
    copy->_strongTarget = _strongTarget;
    copy->_selector = _selector;
    copy->_argument1 = _argument1;
    copy->_argument2 = _argument2;
  }
  return copy;
}

- (BOOL)HL_update:(NSTimeInterval)incrementalTime node:(SKNode *)node extraTime:(NSTimeInterval *)extraTime
{
  // note: See note in [HLAction HL_update] for handling action completion and removal.  In
  // short, an action must be allowed a final update call regardless of its elapsed time
  // and duration; it's only completed when its update returns NO.  Further, when it
  // returns NO, then it won't be called again.  For our purposes, we take advantage of
  // this to assert that we'll do one (and only one) callback to our target.
  assert(self.elapsedTime == 0.0);

  [self HL_advanceTime:incrementalTime];

  id target = _strongTarget;
  if (target) {
    IMP imp = [target methodForSelector:_selector];
    void (*func)(id, SEL, id, id) = (void (*)(id, SEL, id, id))imp;
    func(target, _selector, _argument1, _argument2);
  }

  *extraTime = incrementalTime;
  return NO;
}

@end

@implementation HLCustomAction
{
  __weak id _weakTarget;
  SEL _selector;
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

- (instancetype)copyWithZone:(NSZone *)zone
{
  HLCustomAction *copy = [super copyWithZone:zone];
  if (copy) {
    copy->_weakTarget = _weakTarget;
    copy->_selector = _selector;
    copy->_userData = [_userData copy];
  }
  return copy;
}

- (BOOL)HL_update:(NSTimeInterval)incrementalTime node:(SKNode *)node extraTime:(NSTimeInterval *)extraTime
{
  // note: See note in [HLAction HL_update] for handling action completion and removal.  In
  // short, an action must be allowed a final update call regardless of its elapsed time
  // and duration; it's only completed when its update returns NO.  Further, when it
  // returns NO, then it won't be called again.  For our purposes, we take advantage of
  // this to guarantee that we'll do one (and only one) final callback to our target where
  // elapsed time is equal to duration (as a way of saying, "this action is complete").
  // This is the same behavior as SKAction's customActionWithDuration:actionBlock:., and
  // is true even when this last call comes quite a bit after the action should have
  // completed (due to slow update calls).

  // note: A test of SKAction customActionWithDuration:actionBlock: shows it executes the block
  // even when speed is 0.0.

  BOOL notYetCompleted;
  [self HL_advanceTime:incrementalTime extraTime:extraTime notYetCompleted:&notYetCompleted];

  id target = _weakTarget;
  if (target) {
    NSTimeInterval duration = self.duration;
    IMP imp = [target methodForSelector:_selector];
    void (*func)(id, SEL, SKNode *, CGFloat, NSTimeInterval, id) = (void (*)(id, SEL, SKNode *, CGFloat, NSTimeInterval, id))imp;
    if (notYetCompleted) {
      func(target, _selector, node, (CGFloat)self.elapsedTime, duration, _userData);
    } else {
      func(target, _selector, node, (CGFloat)duration, duration, _userData);
    }
  }

  return notYetCompleted;
}

@end

@implementation HLCustomActionTwoValues

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super init];
  if (self) {
    _start = (CGFloat)[aDecoder decodeDoubleForKey:@"start"];
    _finish = (CGFloat)[aDecoder decodeDoubleForKey:@"finish"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [aCoder encodeDouble:_start forKey:@"start"];
  [aCoder encodeDouble:_finish forKey:@"finish"];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
  HLCustomActionTwoValues *copy = [[[self class] allocWithZone:zone] init];
  if (copy) {
    copy->_start = _start;
    copy->_finish = _finish;
  }
  return copy;
}

@end

@implementation HLCustomActionTwoPoints

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super init];
  if (self) {
#if TARGET_OS_IPHONE
    _start = [aDecoder decodeCGPointForKey:@"start"];
    _finish = [aDecoder decodeCGPointForKey:@"finish"];
#else
    _start = [aDecoder decodePointForKey:@"start"];
    _finish = [aDecoder decodePointForKey:@"finish"];
#endif
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
#if TARGET_OS_IPHONE
  [aCoder encodeCGPoint:_start forKey:@"start"];
  [aCoder encodeCGPoint:_finish forKey:@"finish"];
#else
  [aCoder encodePoint:_start forKey:@"start"];
  [aCoder encodePoint:_finish forKey:@"finish"];
#endif
}

- (instancetype)copyWithZone:(NSZone *)zone
{
  HLCustomActionTwoPoints *copy = [[[self class] allocWithZone:zone] init];
  if (copy) {
    copy->_start = _start;
    copy->_finish = _finish;
  }
  return copy;
}

@end
