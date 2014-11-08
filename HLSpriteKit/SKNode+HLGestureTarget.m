//
//  SKNode+HLGestureTarget.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 7/10/14.
//  Copyright (c) 2014 Hilo Games. All rights reserved.
//

#import "SKNode+HLGestureTarget.h"

static NSString * const HLGestureTargetUserDataKey = @"HLGestureTarget";

@implementation SKNode (HLGestureTarget)

- (id <HLGestureTarget>)hlGestureTarget
{
  NSDictionary *userData = self.userData;
  if (!userData) {
    return nil;
  }
  id value = self.userData[HLGestureTargetUserDataKey];
  if (!value) {
    return nil;
  } else if (value == HLGestureTargetUserDataKey) {
    return (id <HLGestureTarget>)self;
  } else {
    return (id <HLGestureTarget>)value;
  }
}

- (void)hlSetGestureTarget:(id <HLGestureTarget>)gestureTarget
{
  if (!self.userData) {
    self.userData = [NSMutableDictionary dictionary];
  }
  if ((id)gestureTarget == self) {
    self.userData[HLGestureTargetUserDataKey] = HLGestureTargetUserDataKey;
  } else {
    self.userData[HLGestureTargetUserDataKey] = gestureTarget;
  }
}

@end
