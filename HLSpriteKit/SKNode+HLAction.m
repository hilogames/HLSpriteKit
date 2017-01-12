//
//  SKNode+HLAction.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 1/9/2017.
//  Copyright (c) 2017 Hilo Games. All rights reserved.
//

#import "SKNode+HLAction.h"

static NSString * const HLActionRunnerUserDataKey = @"HLActionRunner";

@implementation SKNode (HLAction)

#pragma mark - Managing the Action Runner

- (HLActionRunner *)hlActionRunner
{
  if (!self.userData) {
    self.userData = [NSMutableDictionary dictionary];
  }
  HLActionRunner *actionRunner = self.userData[HLActionRunnerUserDataKey];
  if (!actionRunner) {
    actionRunner = [[HLActionRunner alloc] init];
    self.userData[HLActionRunnerUserDataKey] = actionRunner;
  }
  return actionRunner;
}

- (BOOL)hlHasActionRunner
{
  NSMutableDictionary *userData = self.userData;
  if (!userData) {
    return NO;
  }
  return (userData[HLActionRunnerUserDataKey] != nil);
}

- (void)hlSetActionRunner:(HLActionRunner *)actionRunner
{
  if (!actionRunner) {
    NSMutableDictionary *userData = self.userData;
    if (userData) {
      [userData removeObjectForKey:HLActionRunnerUserDataKey];
    }
  } else {
    if (!self.userData) {
      self.userData = [NSMutableDictionary dictionary];
    }
    self.userData[HLActionRunnerUserDataKey] = actionRunner;
  }
}

- (void)hlActionRunnerUpdate:(NSTimeInterval)incrementalTime
{
  NSMutableDictionary *userData = self.userData;
  if (!userData) {
    return;
  }
  HLActionRunner *actionRunner = userData[HLActionRunnerUserDataKey];
  if (!actionRunner) {
    return;
  }
  [actionRunner update:incrementalTime node:self speed:self.speed];
}

#pragma mark - Managing Actions

- (void)hlRunAction:(HLAction *)action withKey:(NSString *)key
{
  [self.hlActionRunner runAction:action withKey:key];
}

- (BOOL)hlHasActions
{
  if (!self.userData) {
    return NO;
  }
  HLActionRunner *actionRunner = self.userData[HLActionRunnerUserDataKey];
  if (!actionRunner) {
    return NO;
  }
  return [actionRunner hasActions];
}

- (HLAction *)hlActionForKey:(NSString *)key
{
  NSMutableDictionary *userData = self.userData;
  if (!userData) {
    return nil;
  }
  HLActionRunner *actionRunner = userData[HLActionRunnerUserDataKey];
  if (!actionRunner) {
    return nil;
  }
  return [actionRunner actionForKey:key];
}

- (void)hlRemoveActionForKey:(NSString *)key
{
  NSMutableDictionary *userData = self.userData;
  if (!userData) {
    return;
  }
  HLActionRunner *actionRunner = userData[HLActionRunnerUserDataKey];
  if (!actionRunner) {
    return;
  }
  [actionRunner removeActionForKey:key];
}

- (void)hlRemoveAllActions
{
  NSMutableDictionary *userData = self.userData;
  if (!userData) {
    return;
  }
  HLActionRunner *actionRunner = userData[HLActionRunnerUserDataKey];
  if (!actionRunner) {
    return;
  }
  [actionRunner removeAllActions];
}

@end
