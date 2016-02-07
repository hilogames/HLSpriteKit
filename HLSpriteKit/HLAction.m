//
//  HLAction.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 2/4/16.
//  Copyright (c) 2016 Hilo Games. All rights reserved.
//

#import "HLAction.h"

@implementation HLPerformSelector

- (instancetype)initWithTarget:(id)target selector:(SEL)selector argument:(id)argument
{
  self = [super init];
  if (self) {
    _target = target;
    _selector = selector;
    _argument = argument;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super init];
  if (self) {
    _target = [aDecoder decodeObjectForKey:@"target"];
    _selector = NSSelectorFromString([aDecoder decodeObjectForKey:@"selector"]);
    _argument = [aDecoder decodeObjectForKey:@"argument"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [aCoder encodeObject:_target forKey:@"target"];
  [aCoder encodeObject:NSStringFromSelector(_selector) forKey:@"selector"];
  [aCoder encodeObject:_argument forKey:@"argument"];
}

- (void)execute
{
  if (!_target) {
    return;
  }
  IMP imp = [_target methodForSelector:_selector];
  void (*func)(id, SEL, id) = (void (*)(id, SEL, id))imp;
  func(_target, _selector, _argument);
}

@end
