//
//  SKNode+HLLayoutManager.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 10/27/14.
//  Copyright (c) 2014 Hilo. All rights reserved.
//

#import "SKNode+HLLayoutManager.h"

static NSString * const HLLayoutManagerUserDataKey = @"HLLayoutManager";

@implementation SKNode (HLLayoutManager)

- (id <HLLayoutManager>)hlLayoutManager
{
  id value = self.userData[HLLayoutManagerUserDataKey];
  if (!value) {
    return nil;
  } else if (value == HLLayoutManagerUserDataKey) {
    return (id <HLLayoutManager>)self;
  } else {
    return (id <HLLayoutManager>)value;
  }
}

- (void)setHLLayoutManager:(id <HLLayoutManager>)layoutManager
{
  if (!self.userData) {
    self.userData = [NSMutableDictionary dictionary];
  }
  if (layoutManager == self) {
    self.userData[HLLayoutManagerUserDataKey] = HLLayoutManagerUserDataKey;
  } else {
    self.userData[HLLayoutManagerUserDataKey] = layoutManager;
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
