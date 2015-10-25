//
//  HLItemNode.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 6/5/15.
//  Copyright (c) 2015 Hilo Games. All rights reserved.
//

#import "HLItemNode.h"

#import "HLItemContentNode.h"

@implementation HLItemNode

- (instancetype)init
{
  self = [super init];
  if (self) {
    _enabled = YES;
    _highlight = NO;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self) {
    _enabled = [aDecoder decodeBoolForKey:@"enabled"];
    _highlight = [aDecoder decodeBoolForKey:@"highlight"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [super encodeWithCoder:aCoder];
  // note: Content node already encoded by super; encode the reference.
  [aCoder encodeBool:_enabled forKey:@"enabled"];
  [aCoder encodeBool:_highlight forKey:@"highlight"];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
  HLItemNode *copy = [super copyWithZone:zone];
  if (copy) {
    copy->_enabled = _enabled;
    copy->_highlight = _highlight;
  }
  return copy;
}

- (void)setZPositionScale:(CGFloat)zPositionScale
{
  [super setZPositionScale:zPositionScale];
  SKNode *contentNode = [self childNodeWithName:@"content"];
  if (contentNode) {
    if ([contentNode isKindOfClass:[HLComponentNode class]]) {
      ((HLComponentNode *)contentNode).zPositionScale = zPositionScale;
    }
  }
}

- (void)setContent:(SKNode *)contentNode
{
  SKNode *oldContentNode = [self childNodeWithName:@"content"];
  if (oldContentNode) {
    [oldContentNode removeFromParent];
  }
  if (contentNode) {
    contentNode.name = @"content";
    contentNode.zPosition = 0.0f;
    if ([contentNode isKindOfClass:[HLComponentNode class]]) {
      ((HLComponentNode *)contentNode).zPositionScale = self.zPositionScale;
    }
    if ([contentNode conformsToProtocol:@protocol(HLItemContentNode)]) {
      if ([contentNode respondsToSelector:@selector(hlItemContentSetEnabled:)]) {
        [(SKNode <HLItemContentNode> *)contentNode hlItemContentSetEnabled:_enabled];
      }
      if ([contentNode respondsToSelector:@selector(hlItemContentSetHighlight:)]) {
        [(SKNode <HLItemContentNode> *)contentNode hlItemContentSetHighlight:_highlight];
      }
    }
    [self addChild:contentNode];
  }
}

- (SKNode *)content
{
  return [self childNodeWithName:@"content"];
}

- (void)setEnabled:(BOOL)enabled
{
  _enabled = enabled;
  SKNode *contentNode = [self childNodeWithName:@"content"];
  if (contentNode
      && [contentNode conformsToProtocol:@protocol(HLItemContentNode)]
      && [contentNode respondsToSelector:@selector(hlItemContentSetEnabled:)]) {
    [(SKNode <HLItemContentNode> *)contentNode hlItemContentSetEnabled:enabled];
  }
}

- (void)setEnabled:(BOOL)enabled contentDidSetEnabled:(BOOL *)contentDidSetEnabled
{
  _enabled = enabled;
  SKNode *contentNode = [self childNodeWithName:@"content"];
  if (contentNode
      && [contentNode conformsToProtocol:@protocol(HLItemContentNode)]
      && [contentNode respondsToSelector:@selector(hlItemContentSetEnabled:)]) {
    [(SKNode <HLItemContentNode> *)contentNode hlItemContentSetEnabled:enabled];
    *contentDidSetEnabled = YES;
  } else {
    *contentDidSetEnabled = NO;
  }
}

- (void)setHighlight:(BOOL)highlight
{
  _highlight = highlight;
  SKNode *contentNode = [self childNodeWithName:@"content"];
  if (contentNode
      && [contentNode conformsToProtocol:@protocol(HLItemContentNode)]
      && [contentNode respondsToSelector:@selector(hlItemContentSetHighlight:)]) {
    [(SKNode <HLItemContentNode> *)contentNode hlItemContentSetHighlight:highlight];
  }
}

- (void)setHighlight:(BOOL)highlight contentDidSetHighlight:(BOOL *)contentDidSetHighlight
{
  _highlight = highlight;
  SKNode *contentNode = [self childNodeWithName:@"content"];
  if (contentNode
      && [contentNode conformsToProtocol:@protocol(HLItemContentNode)]
      && [contentNode respondsToSelector:@selector(hlItemContentSetHighlight:)]) {
    [(SKNode <HLItemContentNode> *)contentNode hlItemContentSetHighlight:highlight];
    *contentDidSetHighlight = YES;
  } else {
    *contentDidSetHighlight = NO;
  }
}

- (void)setHighlight:(BOOL)finalHighlight
          blinkCount:(int)blinkCount
   halfCycleDuration:(NSTimeInterval)halfCycleDuration
          completion:(void (^)(void))completion
{
  _highlight = finalHighlight;
  SKNode *contentNode = [self childNodeWithName:@"content"];
  if (contentNode
      && [contentNode conformsToProtocol:@protocol(HLItemContentNode)]
      && [contentNode respondsToSelector:@selector(hlItemContentSetHighlight:blinkCount:halfCycleDuration:completion:)]) {
    [(SKNode <HLItemContentNode> *)contentNode hlItemContentSetHighlight:finalHighlight
                                                              blinkCount:blinkCount
                                                       halfCycleDuration:halfCycleDuration
                                                              completion:completion];
  }
}

- (void)setHighlight:(BOOL)finalHighlight
          blinkCount:(int)blinkCount
   halfCycleDuration:(NSTimeInterval)halfCycleDuration
          completion:(void (^)(void))completion
contentDidSetHighlight:(BOOL *)contentDidSetHighlight
{
  _highlight = finalHighlight;
  SKNode *contentNode = [self childNodeWithName:@"content"];
  if (contentNode
      && [contentNode conformsToProtocol:@protocol(HLItemContentNode)]
      && [contentNode respondsToSelector:@selector(hlItemContentSetHighlight:blinkCount:halfCycleDuration:completion:)]) {
    [(SKNode <HLItemContentNode> *)contentNode hlItemContentSetHighlight:finalHighlight
                                                              blinkCount:blinkCount
                                                       halfCycleDuration:halfCycleDuration
                                                              completion:completion];
    *contentDidSetHighlight = YES;
  } else {
    *contentDidSetHighlight = NO;
  }
}

@end

enum {
  HLBackdropItemNodeZPositionLayerBackdrop = 0,
  HLBackdropItemNodeZPositionLayerContent,
  HLBackdropItemNodeZPositionLayerCount
};

@implementation HLBackdropItemNode

- (instancetype)initWithSize:(CGSize)size
{
  self = [super init];
  if (self) {
    _normalColor = [SKColor colorWithWhite:0.5f alpha:1.0f];
    _highlightColor = [SKColor colorWithWhite:1.0f alpha:1.0f];
    _enabledAlpha = 1.0f;
    _disabledAlpha = 0.4f;
    SKSpriteNode *backdropNode = [SKSpriteNode spriteNodeWithColor:_normalColor size:size];
    backdropNode.name = @"backdrop";
    backdropNode.alpha = _enabledAlpha;
    [self addChild:backdropNode];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self) {
    _normalColor = [aDecoder decodeObjectForKey:@"normalColor"];
    _highlightColor = [aDecoder decodeObjectForKey:@"highlightColor"];
    _enabledAlpha = (CGFloat)[aDecoder decodeDoubleForKey:@"enabledAlpha"];
    _disabledAlpha = (CGFloat)[aDecoder decodeDoubleForKey:@"disabledAlpha"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [aCoder encodeObject:_normalColor forKey:@"normalColor"];
  [aCoder encodeObject:_highlightColor forKey:@"highlightColor"];
  [aCoder encodeDouble:_enabledAlpha forKey:@"enabledAlpha"];
  [aCoder encodeDouble:_disabledAlpha forKey:@"disabledAlpha"];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
  HLBackdropItemNode *copy = [super copyWithZone:zone];
  if (copy) {
    copy->_normalColor = _normalColor;
    copy->_highlightColor = _highlightColor;
    copy->_enabledAlpha = _enabledAlpha;
    copy->_disabledAlpha = _disabledAlpha;
  }
  return copy;
}

- (void)setContent:(SKNode *)contentNode
{
  [super setContent:contentNode];
  if (contentNode) {
    if (self.enabled) {
      contentNode.alpha = _enabledAlpha;
    } else {
      contentNode.alpha = _disabledAlpha;
    }
  }
}

- (void)setEnabled:(BOOL)enabled
{
  BOOL contentDidSetEnabled;
  [super setEnabled:enabled contentDidSetEnabled:&contentDidSetEnabled];
  if (contentDidSetEnabled) {
    return;
  }
  SKSpriteNode *backdropNode = (SKSpriteNode *)[self childNodeWithName:@"backdrop"];
  if (enabled) {
    backdropNode.alpha = _enabledAlpha;
  } else {
    backdropNode.alpha = _disabledAlpha;
  }
  SKSpriteNode *contentNode = (SKSpriteNode *)[self childNodeWithName:@"content"];
  if (contentNode) {
    if (enabled) {
      contentNode.alpha = _enabledAlpha;
    } else {
      contentNode.alpha = _disabledAlpha;
    }
  }
}

- (void)setHighlight:(BOOL)highlight
{
  BOOL contentDidSetHighlight;
  [super setHighlight:highlight contentDidSetHighlight:&contentDidSetHighlight];
  if (contentDidSetHighlight) {
    return;
  }
  SKSpriteNode *backdropNode = (SKSpriteNode *)[self childNodeWithName:@"backdrop"];
  [backdropNode removeActionForKey:@"setHighlight"];
  if (highlight) {
    backdropNode.color = _highlightColor;
  } else {
    backdropNode.color = _normalColor;
  }
}

- (void)setHighlight:(BOOL)finalHighlight
          blinkCount:(int)blinkCount
   halfCycleDuration:(NSTimeInterval)halfCycleDuration
          completion:(void (^)(void))completion
{
  BOOL contentDidSetHighlight;
  BOOL startingHighlight = self.highlight;
  [super setHighlight:finalHighlight
           blinkCount:blinkCount
    halfCycleDuration:halfCycleDuration
           completion:completion
contentDidSetHighlight:&contentDidSetHighlight];
  if (contentDidSetHighlight) {
    return;
  }

  SKSpriteNode *backdropNode = (SKSpriteNode *)[self childNodeWithName:@"backdrop"];

  [backdropNode removeActionForKey:@"setHighlight"];

  SKAction *blinkIn;
  blinkIn = [SKAction colorizeWithColor:(startingHighlight ? _normalColor : _highlightColor) colorBlendFactor:1.0f duration:halfCycleDuration];
  blinkIn.timingMode = (startingHighlight ? SKActionTimingEaseOut : SKActionTimingEaseIn);
  SKAction *blinkOut;
  blinkOut = [SKAction colorizeWithColor:(startingHighlight ? _highlightColor : _normalColor) colorBlendFactor:1.0f duration:halfCycleDuration];
  blinkOut.timingMode = (startingHighlight ? SKActionTimingEaseIn : SKActionTimingEaseOut);

  NSMutableArray *blinkActions = [NSMutableArray array];
  for (int b = 0; b < blinkCount; ++b) {
    [blinkActions addObject:blinkIn];
    [blinkActions addObject:blinkOut];
  }
  if (startingHighlight != finalHighlight) {
    [blinkActions addObject:blinkIn];
  }
  if (completion) {
    [blinkActions addObject:[SKAction runBlock:completion]];
  }

  [backdropNode runAction:[SKAction sequence:blinkActions] withKey:@"setHighlight"];
}

- (CGSize)size
{
  SKSpriteNode *backdropNode = (SKSpriteNode *)[self childNodeWithName:@"backdrop"];
  return backdropNode.size;
}

- (void)setSize:(CGSize)size
{
  SKSpriteNode *backdropNode = (SKSpriteNode *)[self childNodeWithName:@"backdrop"];
  backdropNode.size = size;
}

- (void)setNormalColor:(SKColor *)normalColor
{
  _normalColor = normalColor;
  if (!self.highlight) {
    SKSpriteNode *backdropNode = (SKSpriteNode *)[self childNodeWithName:@"backdrop"];
    backdropNode.color = normalColor;
  }
}

- (void)setHighlightColor:(UIColor *)highlightColor
{
  _highlightColor = highlightColor;
  if (self.highlight) {
    SKSpriteNode *backdropNode = (SKSpriteNode *)[self childNodeWithName:@"backdrop"];
    backdropNode.color = highlightColor;
  }
}

- (void)setEnabledAlpha:(CGFloat)enabledAlpha
{
  _enabledAlpha = enabledAlpha;
  if (self.enabled) {
    SKSpriteNode *backdropNode = (SKSpriteNode *)[self childNodeWithName:@"backdrop"];
    backdropNode.alpha = enabledAlpha;
    SKSpriteNode *contentNode = (SKSpriteNode *)[self childNodeWithName:@"content"];
    if (contentNode) {
      contentNode.alpha = enabledAlpha;
    }
  }
}

- (void)setDisabledAlpha:(CGFloat)disabledAlpha
{
  _disabledAlpha = disabledAlpha;
  if (!self.enabled) {
    SKSpriteNode *backdropNode = (SKSpriteNode *)[self childNodeWithName:@"backdrop"];
    backdropNode.alpha = disabledAlpha;
    SKSpriteNode *contentNode = (SKSpriteNode *)[self childNodeWithName:@"content"];
    if (contentNode) {
      contentNode.alpha = disabledAlpha;
    }
  }
}

@end
