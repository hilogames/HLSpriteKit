//
//  HLItemNode.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 6/5/15.
//  Copyright (c) 2015 Hilo Games. All rights reserved.
//

#import "HLItemNode.h"

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
  super.zPositionScale = zPositionScale;
  SKNode *contentNode = self.children.firstObject;
  if (contentNode) {
    if ([contentNode isKindOfClass:[HLComponentNode class]]) {
      ((HLComponentNode *)contentNode).zPositionScale = zPositionScale;
    }
  }
}

- (void)setContent:(SKNode *)contentNode
{
  [self removeAllChildren];
  if (contentNode) {
    [self addChild:contentNode];
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
  }
}

- (void)setEnabled:(BOOL)enabled
{
  _enabled = enabled;
  SKNode *contentNode = self.children.firstObject;
  if (contentNode
      && [contentNode conformsToProtocol:@protocol(HLItemContentNode)]
      && [contentNode respondsToSelector:@selector(hlItemContentSetEnabled:)]) {
    [(SKNode <HLItemContentNode> *)contentNode hlItemContentSetEnabled:enabled];
  }
}

- (void)setHighlight:(BOOL)highlight
{
  _highlight = highlight;
  SKNode *contentNode = self.children.firstObject;
  if (contentNode
      && [contentNode conformsToProtocol:@protocol(HLItemContentNode)]
      && [contentNode respondsToSelector:@selector(hlItemContentSetHighlight:)]) {
    [(SKNode <HLItemContentNode> *)contentNode hlItemContentSetHighlight:highlight];
  }
}

@end

enum {
  HLBackdropItemNodeZPositionLayerBackdrop = 0,
  HLBackdropItemNodeZPositionLayerContent,
  HLBackdropItemNodeZPositionLayerCount
};

@implementation HLBackdropItemNode
{
  SKSpriteNode *_backdropNode;
}

- (instancetype)initWithSize:(CGSize)size
{
  self = [super init];
  if (self) {
    _normalColor = [SKColor colorWithWhite:0.5f alpha:1.0f];
    _highlightColor = [SKColor colorWithWhite:1.0f alpha:1.0f];
    _enabledAlpha = 1.0f;
    _disabledAlpha = 0.4f;
    _backdropNode = [SKSpriteNode spriteNodeWithColor:_normalColor size:size];
    _backdropNode.alpha = _enabledAlpha;
  }
  return self;
}

- (CGSize)size
{
  return _backdropNode.size;
}

- (void)setSize:(CGSize)size
{
  _backdropNode.size = size;
}

- (void)setNormalColor:(SKColor *)normalColor
{
  _normalColor = normalColor;
  if (!self.highlight) {
    _backdropNode.color = normalColor;
  }
}

- (void)setHighlightColor:(UIColor *)highlightColor
{
  _highlightColor = highlightColor;
  if (self.highlight) {
    _backdropNode.color = highlightColor;
  }
}

- (void)setEnabledAlpha:(CGFloat)enabledAlpha
{
  _enabledAlpha = enabledAlpha;
  if (self.enabled) {
    _backdropNode.alpha = enabledAlpha;
  }
}

- (void)setDisabledAlpha:(CGFloat)disabledAlpha
{
  _disabledAlpha = disabledAlpha;
  if (!self.enabled) {
    _backdropNode.alpha = disabledAlpha;
  }
}

@end
