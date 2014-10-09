//
//  HLComponentNode.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 10/6/14.
//  Copyright (c) 2014 Hilo. All rights reserved.
//

#import "HLComponentNode.h"

@implementation HLComponentNode
{
  __weak id <HLGestureTargetDelegate> _gestureTargetDelegateWeak;
  id <HLGestureTargetDelegate> _gestureTargetDelegateStrong;
}

- (instancetype)init
{
  self = [super init];
  if (self) {
    _zPositionScale = 1.0f;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self) {
    _gestureTargetDelegateWeak = [aDecoder decodeObjectForKey:@"gestureTargetDelegateWeak"];
    _gestureTargetDelegateStrong = [aDecoder decodeObjectForKey:@"gestureTargetDelegateStrong"];
    _zPositionScale = (CGFloat)[aDecoder decodeDoubleForKey:@"zPositionScale"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [super encodeWithCoder:aCoder];
  [aCoder encodeObject:_gestureTargetDelegateWeak forKey:@"gestureTargetDelegateWeak"];
  [aCoder encodeObject:_gestureTargetDelegateStrong forKey:@"gestureTargetDelegateStrong"];
  [aCoder encodeDouble:_zPositionScale forKey:@"zPositionScale"];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
  HLComponentNode *copy = [super copyWithZone:zone];
  if (copy) {
    // note: For now, copying means sharing a gesture target delegate; that seems like
    // the least-dangerous option.  Perhaps a good compromise would be doing a deep-copy
    // of a strongly-held delegate and sharing a weakly-held delegate, but that seems
    // so conditional and potentially confusing to the owner.
    copy->_gestureTargetDelegateWeak = _gestureTargetDelegateWeak;
    copy->_gestureTargetDelegateStrong = _gestureTargetDelegateStrong;
    copy->_zPositionScale = _zPositionScale;
  }
  return copy;
}

- (void)setGestureTargetDelegateWeak:(id<HLGestureTargetDelegate>)delegate
{
  _gestureTargetDelegateWeak = delegate;
  _gestureTargetDelegateStrong = nil;
}

- (void)setGestureTargetDelegateStrong:(id<HLGestureTargetDelegate>)delegate
{
  _gestureTargetDelegateStrong = delegate;
  _gestureTargetDelegateWeak = nil;
}

- (id<HLGestureTargetDelegate>)gestureTargetDelegate
{
  if (_gestureTargetDelegateWeak) {
    return _gestureTargetDelegateWeak;
  } else {
    return _gestureTargetDelegateStrong;
  }
}

@end
