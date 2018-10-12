//
//  HLItemContentNode.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 4/13/15.
//  Copyright (c) 2015 Hilo Games. All rights reserved.
//

#import "HLItemContentNode.h"

enum {
  HLItemContentBackHighlightNodeZPositionLayerBackHighlight = 0,
  HLItemContentBackHighlightNodeZPositionLayerContent,
  HLItemContentBackHighlightNodeZPositionLayerCount
};

@implementation HLItemContentBackHighlightNode
{
  SKNode *_backHighlightNode;
}

- (instancetype)initWithContentNode:(SKNode *)contentNode backHighlightNode:(SKNode *)backHighlightNode
{
  self = [super init];
  if (self) {
    contentNode.name = @"content";
    [self addChild:contentNode];
    backHighlightNode.name = @"backHighlight";
    _backHighlightNode = backHighlightNode;
    [self HL_layoutZ];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self) {
    _backHighlightNode = [aDecoder decodeObjectForKey:@"backHighlightNode"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [super encodeWithCoder:aCoder];
  [aCoder encodeObject:_backHighlightNode forKey:@"backHighlightNode"];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
  HLItemContentBackHighlightNode *copy = [super copyWithZone:zone];
  if (copy) {
    if (_backHighlightNode.parent) {
      copy->_backHighlightNode = [copy childNodeWithName:@"backHighlightNode"];
    } else {
      copy->_backHighlightNode = [_backHighlightNode copy];
    }
  }
  return copy;
}

- (CGSize)size
{
  SKNode *contentNode = [self childNodeWithName:@"content"];
  SEL selector = @selector(size);
  NSMethodSignature *sizeMethodSignature = [contentNode methodSignatureForSelector:selector];
  if (!sizeMethodSignature
      || strcmp(sizeMethodSignature.methodReturnType, @encode(CGSize)) != 0) {
    return CGSizeZero;
  }
  NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sizeMethodSignature];
  [invocation setSelector:selector];
  [invocation invokeWithTarget:contentNode];
  CGSize contentNodeSize;
  [invocation getReturnValue:&contentNodeSize];
  return contentNodeSize;
}

- (void)setZPositionScale:(CGFloat)zPositionScale
{
  [super setZPositionScale:zPositionScale];
  [self HL_layoutZ];
}

- (SKNode *)backHighlightNode
{
  return _backHighlightNode;
}

- (void)hlItemContentSetHighlight:(BOOL)highlight
{
  [_backHighlightNode removeActionForKey:@"setHighlight"];

  if (highlight) {
    if (!_backHighlightNode.parent) {
      _backHighlightNode.alpha = 1.0f;
      [self addChild:_backHighlightNode];
    }
  } else {
    if (_backHighlightNode.parent) {
      [_backHighlightNode removeFromParent];
    }
  }
}

- (void)hlItemContentSetHighlight:(BOOL)finalHighlight
                       blinkCount:(int)blinkCount
                halfCycleDuration:(NSTimeInterval)halfCycleDuration
                       completion:(void (^)(void))completion
{
  [_backHighlightNode removeActionForKey:@"setHighlight"];

  if (!_backHighlightNode.parent) {
    [self addChild:_backHighlightNode];
  }
  _backHighlightNode.alpha = (finalHighlight ? 0.0f : 1.0f );

  SKAction *blinkInAction;
  if (finalHighlight) {
    blinkInAction = [SKAction fadeInWithDuration:halfCycleDuration];
    blinkInAction.timingMode = SKActionTimingEaseIn;
  } else {
    blinkInAction = [SKAction fadeOutWithDuration:halfCycleDuration];
    blinkInAction.timingMode = SKActionTimingEaseOut;
  }

  NSMutableArray *blinkActions = [NSMutableArray array];
  if (blinkCount > 0) {
    SKAction *blinkOutAction;
    if (finalHighlight) {
      blinkOutAction = [SKAction fadeOutWithDuration:halfCycleDuration];
      blinkOutAction.timingMode = SKActionTimingEaseOut;
    } else {
      blinkOutAction = [SKAction fadeInWithDuration:halfCycleDuration];
      blinkOutAction.timingMode = SKActionTimingEaseIn;
    }
    SKAction *blinkAction = [SKAction sequence:@[ blinkInAction, blinkOutAction ]];
    [blinkActions addObject:[SKAction repeatAction:blinkAction count:(NSUInteger)blinkCount]];
  }

  [blinkActions addObject:blinkInAction];

  if (!finalHighlight) {
    [blinkActions addObject:[SKAction removeFromParent]];
  }

  if (completion) {
    [blinkActions addObject:[SKAction runBlock:completion]];
  }

  [_backHighlightNode runAction:[SKAction sequence:blinkActions] withKey:@"setHighlight"];
}

- (void)HL_layoutZ
{
  CGFloat zPositionLayerIncrement = self.zPositionScale / HLItemContentBackHighlightNodeZPositionLayerCount;
  SKNode *contentNode = [self childNodeWithName:@"content"];
  contentNode.zPosition = HLItemContentBackHighlightNodeZPositionLayerContent * zPositionLayerIncrement;
  if ([contentNode isKindOfClass:[HLComponentNode class]]) {
    ((HLComponentNode *)contentNode).zPositionScale = zPositionLayerIncrement;
  }
  _backHighlightNode.zPosition = HLItemContentBackHighlightNodeZPositionLayerBackHighlight * zPositionLayerIncrement;
  if ([_backHighlightNode isKindOfClass:[HLComponentNode class]]) {
    ((HLComponentNode *)_backHighlightNode).zPositionScale = zPositionLayerIncrement;
  }
}

@end

enum {
  HLItemContentFrontHighlightNodeZPositionLayerContent = 0,
  HLItemContentFrontHighlightNodeZPositionLayerFrontHighlight,
  HLItemContentFrontHighlightNodeZPositionLayerCount
};

@implementation HLItemContentFrontHighlightNode
{
  SKNode *_frontHighlightNode;
}

- (instancetype)initWithContentNode:(SKNode *)contentNode frontHighlightNode:(SKNode *)frontHighlightNode
{
  self = [super init];
  if (self) {
    contentNode.name = @"content";
    [self addChild:contentNode];
    frontHighlightNode.name = @"frontHighlight";
    _frontHighlightNode = frontHighlightNode;
    [self HL_layoutZ];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self) {
    _frontHighlightNode = [aDecoder decodeObjectForKey:@"frontHighlightNode"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [super encodeWithCoder:aCoder];
  [aCoder encodeObject:_frontHighlightNode forKey:@"frontHighlightNode"];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
  HLItemContentFrontHighlightNode *copy = [super copyWithZone:zone];
  if (copy) {
    if (_frontHighlightNode.parent) {
      copy->_frontHighlightNode = [copy childNodeWithName:@"frontHighlightNode"];
    } else {
      copy->_frontHighlightNode = [_frontHighlightNode copy];
    }
  }
  return copy;
}

- (CGSize)size
{
  SKNode *contentNode = [self childNodeWithName:@"content"];
  SEL selector = @selector(size);
  NSMethodSignature *sizeMethodSignature = [contentNode methodSignatureForSelector:selector];
  if (!sizeMethodSignature
      || strcmp(sizeMethodSignature.methodReturnType, @encode(CGSize)) != 0) {
    return CGSizeZero;
  }
  NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sizeMethodSignature];
  [invocation setSelector:selector];
  [invocation invokeWithTarget:contentNode];
  CGSize contentNodeSize;
  [invocation getReturnValue:&contentNodeSize];
  return contentNodeSize;
}

- (void)setZPositionScale:(CGFloat)zPositionScale
{
  [super setZPositionScale:zPositionScale];
  [self HL_layoutZ];
}

- (SKNode *)frontHighlightNode
{
  return _frontHighlightNode;
}

- (void)hlItemContentSetHighlight:(BOOL)highlight
{
  [_frontHighlightNode removeActionForKey:@"setHighlight"];

  if (highlight) {
    if (!_frontHighlightNode.parent) {
      _frontHighlightNode.alpha = 1.0f;
      [self addChild:_frontHighlightNode];
    }
  } else {
    if (_frontHighlightNode.parent) {
      [_frontHighlightNode removeFromParent];
    }
  }
}

- (void)hlItemContentSetHighlight:(BOOL)finalHighlight
                       blinkCount:(int)blinkCount
                halfCycleDuration:(NSTimeInterval)halfCycleDuration
                       completion:(void (^)(void))completion
{
  [_frontHighlightNode removeActionForKey:@"setHighlight"];

  if (!_frontHighlightNode.parent) {
    [self addChild:_frontHighlightNode];
  }
  _frontHighlightNode.alpha = (finalHighlight ? 0.0f : 1.0f );

  SKAction *blinkInAction;
  if (finalHighlight) {
    blinkInAction = [SKAction fadeInWithDuration:halfCycleDuration];
    blinkInAction.timingMode = SKActionTimingEaseIn;
  } else {
    blinkInAction = [SKAction fadeOutWithDuration:halfCycleDuration];
    blinkInAction.timingMode = SKActionTimingEaseOut;
  }

  NSMutableArray *blinkActions = [NSMutableArray array];
  if (blinkCount > 0) {
    SKAction *blinkOutAction;
    if (finalHighlight) {
      blinkOutAction = [SKAction fadeOutWithDuration:halfCycleDuration];
      blinkOutAction.timingMode = SKActionTimingEaseOut;
    } else {
      blinkOutAction = [SKAction fadeInWithDuration:halfCycleDuration];
      blinkOutAction.timingMode = SKActionTimingEaseIn;
    }
    SKAction *blinkAction = [SKAction sequence:@[ blinkInAction, blinkOutAction ]];
    [blinkActions addObject:[SKAction repeatAction:blinkAction count:(NSUInteger)blinkCount]];
  }

  [blinkActions addObject:blinkInAction];

  if (!finalHighlight) {
    [blinkActions addObject:[SKAction removeFromParent]];
  }

  if (completion) {
    [blinkActions addObject:[SKAction runBlock:completion]];
  }

  [_frontHighlightNode runAction:[SKAction sequence:blinkActions] withKey:@"setHighlight"];
}

- (void)HL_layoutZ
{
  CGFloat zPositionLayerIncrement = self.zPositionScale / HLItemContentFrontHighlightNodeZPositionLayerCount;
  SKNode *contentNode = [self childNodeWithName:@"content"];
  contentNode.zPosition = HLItemContentFrontHighlightNodeZPositionLayerContent * zPositionLayerIncrement;
  if ([contentNode isKindOfClass:[HLComponentNode class]]) {
    ((HLComponentNode *)contentNode).zPositionScale = zPositionLayerIncrement;
  }
  _frontHighlightNode.zPosition = HLItemContentFrontHighlightNodeZPositionLayerFrontHighlight * zPositionLayerIncrement;
  if ([_frontHighlightNode isKindOfClass:[HLComponentNode class]]) {
    ((HLComponentNode *)_frontHighlightNode).zPositionScale = zPositionLayerIncrement;
  }
}

@end
