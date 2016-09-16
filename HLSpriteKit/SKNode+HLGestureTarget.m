//
//  SKNode+HLGestureTarget.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 7/10/14.
//  Copyright (c) 2014 Hilo Games. All rights reserved.
//

#import "SKNode+HLGestureTarget.h"

#if HLGESTURETARGET_AVAILABLE

static NSString * const HLGestureTargetUserDataKey = @"HLGestureTarget";

@implementation SKNode (HLGestureTarget)

- (id <HLGestureTarget>)hlGestureTarget
{
  NSDictionary *userData = self.userData;
  if (!userData) {
    return nil;
  }
  id value = userData[HLGestureTargetUserDataKey];
  if (!value) {
    return nil;
  } else if (value == [NSNull null]) {
    // note: What is the best sentinel to use here?  It should be fast (runtime) and
    // simple (code-wise).  It should survive encoding and decoding in userData.
    //
    // . Since the userData dictionary must hold an object, could use a custom class
    //   (defined here, HLGestureTargetSelfSentinelClass).  The value of the sentinel
    //   would be nil, but the test would just be isKindOfClass: (and not the value).
    //   (This seems better, by the way, than using some random class like NSNumber which
    //   we never expect to be subclassed for an HLGestureTarget.  That would work, but
    //   there seems no reason not to reserve our own class for the purpose.)  (This also
    //   seems better than relying on a value comparison, for example if we encoded an
    //   NSString as our sentinel. In that case we'd be doing a class comparison AND a
    //   value comparison.)
    //
    // . A singleton might be better: If it encodes and decodes properly, then a pointer
    //   comparison will be sufficient for the test.  [NSNull null] singleton works for
    //   this; easier than writing our own.
    return (id <HLGestureTarget>)self;
  } else {
    return (id <HLGestureTarget>)value;
  }
}

- (void)hlSetGestureTarget:(id <HLGestureTarget>)gestureTarget
{
  if (!gestureTarget) {
    NSMutableDictionary *userData = self.userData;
    if (userData) {
      [userData removeObjectForKey:HLGestureTargetUserDataKey];
    }
  } else {
    if (!self.userData) {
      self.userData = [NSMutableDictionary dictionary];
    }
    if ((id)gestureTarget == self) {
      self.userData[HLGestureTargetUserDataKey] = [NSNull null];
    } else {
      self.userData[HLGestureTargetUserDataKey] = gestureTarget;
    }
  }
}

@end

#endif
