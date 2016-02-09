//
//  HLAction.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 2/4/16.
//  Copyright (c) 2016 Hilo Games. All rights reserved.
//

#import "HLAction.h"

@implementation HLPerformSelectorStrongSingle

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

@end

@implementation HLPerformSelectorStrongDouble

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

@end

@implementation HLPerformSelectorWeakSingle

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
  [aCoder encodeObject:_weakTarget forKey:@"weakTarget"];
  [aCoder encodeObject:NSStringFromSelector(_selector) forKey:@"selector"];
  [aCoder encodeObject:_argument forKey:@"argument"];
}

- (void)execute
{
  id target = _weakTarget;
  if (!target) {
    return;
  }
  IMP imp = [_weakTarget methodForSelector:_selector];
  void (*func)(id, SEL, id) = (void (*)(id, SEL, id))imp;
  func(target, _selector, _argument);
}

@end

@implementation HLPerformSelectorWeakDouble

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
  [aCoder encodeObject:_weakTarget forKey:@"weakTarget"];
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
  IMP imp = [_weakTarget methodForSelector:_selector];
  void (*func)(id, SEL, id, id) = (void (*)(id, SEL, id, id))imp;
  func(target, _selector, _argument1, _argument2);
}

@end
