//
//  NSGestureRecognizer+MultipleActions.m
//  HLSpriteKit
//
//  Created by Brent Traut on 10/3/16.
//  Copyright © 2016 Hilo Games. All rights reserved.
//

#import "NSGestureRecognizer+MultipleActions.h"

#if ! TARGET_OS_IPHONE

#import <objc/runtime.h>
static char targetActionPairsKey;

/**
 When developers register targets+actions on NSGestureRecognizer, we need to save the
 entries into an NSMutableArray, and as such, must have a class that holds them.
*/
@interface TargetActionPair : NSObject {
@public
  id target;
  SEL action;
}
- (id)initWithTarget:(id)target action:(SEL)action;
@end

@implementation TargetActionPair
- (id)initWithTarget:(id)_target action:(SEL)_action;
{
  self = [super init];
  if (self) {
    target = _target;
    action = _action;
  }
  return self;
}
@end

@implementation NSGestureRecognizer (NSGestureRecognizer_MultipleActions)

- (NSMutableArray *)targetActionPairs
{
  NSMutableArray *targetActionPairs = objc_getAssociatedObject(self, &targetActionPairsKey);

  if (targetActionPairs != nil) {
    return targetActionPairs;
  }

  targetActionPairs = [NSMutableArray array];
  objc_setAssociatedObject(self, &targetActionPairsKey, targetActionPairs, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

  return targetActionPairs;
}

- (void)setTargetActionPairs:(NSMutableArray *)targetActionPairs
{
  objc_setAssociatedObject(self, &targetActionPairsKey, targetActionPairs, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)addTarget:(id)target action:(SEL)action
{
  NSMutableArray *targetActionPairs = [NSMutableArray arrayWithArray:self.targetActionPairs];

  TargetActionPair *pair = [[TargetActionPair alloc] initWithTarget:target action:action];
  [targetActionPairs addObject:pair];

  objc_setAssociatedObject(self, &targetActionPairsKey, targetActionPairs, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)removeTarget:(id)target action:(SEL)action
{
  NSMutableArray *targetActionPairs = [NSMutableArray arrayWithArray:self.targetActionPairs];

  for (NSUInteger i = 0; i < targetActionPairs.count; i++) {
    TargetActionPair *targetActionPair = targetActionPairs[i];

    BOOL removeTargetActionPair = NO;

    if (targetActionPair->target == target && targetActionPair->action == action) {
      removeTargetActionPair = YES;
    } else if (target == nil && targetActionPair->action == action) {
      removeTargetActionPair = YES;
    } else if (targetActionPair->target == target && action == nil) {
      removeTargetActionPair = YES;
    }

    if (removeTargetActionPair) {
      [targetActionPairs removeObjectAtIndex:i];
      i--;
    }
  }

  objc_setAssociatedObject(self, &targetActionPairsKey, targetActionPairs, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)handleGesture:(NSGestureRecognizer *)gestureRecognizer
{
  for (TargetActionPair *targetActionPair in self.targetActionPairs) {
    // We need to determine which form of the selector the user has provided.
    NSMethodSignature *msig = [targetActionPair->target methodSignatureForSelector:targetActionPair->action];

    if (msig != nil) {
      NSUInteger nargs = [msig numberOfArguments];

      if (nargs == 2) {
        IMP imp = [targetActionPair->target methodForSelector:targetActionPair->action];
        void (*func)(id, SEL) = (void *)imp;
        func(targetActionPair->target, targetActionPair->action);
      } else if (nargs == 3) {
        IMP imp = [targetActionPair->target methodForSelector:targetActionPair->action];
        void (*func)(id, SEL, NSGestureRecognizer *) = (void *)imp;
        func(targetActionPair->target, targetActionPair->action, gestureRecognizer);
      }
    }
  }
}

@end

#endif
