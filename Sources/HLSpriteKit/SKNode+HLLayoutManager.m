//
//  SKNode+HLLayoutManager.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 10/27/14.
//  Copyright (c) 2014 Hilo Games. All rights reserved.
//

#import "SKNode+HLLayoutManager.h"

static NSString * const HLLayoutManagerUserDataKey = @"HLLayoutManager";

@implementation SKNode (HLLayoutManager)

- (id <HLLayoutManager>)hlLayoutManager
{
  NSDictionary *userData = self.userData;
  if (!userData) {
    return nil;
  }
  id value = userData[HLLayoutManagerUserDataKey];
  if (!value) {
    return nil;
  } else if (value == [NSNull null]) {
    return (id <HLLayoutManager>)self;
  } else {
    return (id <HLLayoutManager>)value;
  }
}

- (void)hlSetLayoutManager:(id <HLLayoutManager>)layoutManager
{
  if (!layoutManager) {
    NSMutableDictionary *userData = self.userData;
    if (userData) {
      [userData removeObjectForKey:HLLayoutManagerUserDataKey];
    }
  } else {
    if (!self.userData) {
      self.userData = [NSMutableDictionary dictionary];
    }
    if ((id)layoutManager == self) {
      self.userData[HLLayoutManagerUserDataKey] = [NSNull null];
    } else {
      self.userData[HLLayoutManagerUserDataKey] = layoutManager;
    }
  }
}

- (void)hlLayoutChildren
{
  id <HLLayoutManager> layoutManager = self.hlLayoutManager;
  if (layoutManager) {
    [layoutManager layout:self.children];
  }
}

@end
