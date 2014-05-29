//
//  HLMenuScene.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 5/29/14.
//  Copyright (c) 2014 Hilo. All rights reserved.
//

#import "HLMenuScene.h"

static const CGFloat HLZPositionBackground = 0.0f;
static const CGFloat HLZPositionMenu = 1.0f;

@implementation HLMenuScene

- (id)initWithSize:(CGSize)size
{
  self = [super initWithSize:size];
  if (self) {
    self.anchorPoint = CGPointMake(0.5f, 0.5f);
  }
  return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self) {
    self.anchorPoint = CGPointMake(0.5f, 0.5f);
    // note: Nodes already decoded by super; these are just pointers.
    _menuNode = [aDecoder decodeObjectForKey:@"menuNode"];
    _backgroundNode = [aDecoder decodeObjectForKey:@"backgroundNode"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [super encodeWithCoder:aCoder];
  // note: Nodes already encoded by super; these are just pointers.
  [aCoder encodeObject:_menuNode forKey:@"menuNode"];
  [aCoder encodeObject:_backgroundNode forKey:@"backgroundNode"];
}

- (void)setMenuNode:(HLMenuNode *)menuNode
{
  if (_menuNode) {
    [_menuNode removeFromParent];
  }
  _menuNode = menuNode;
  _menuNode.zPosition = HLZPositionMenu;
  if (_menuNode) {
    [self addChild:_menuNode];
  }
}

- (void)setBackgroundNode:(SKSpriteNode *)backgroundNode
{
  if (_backgroundNode) {
    [_backgroundNode removeFromParent];
  }
  _backgroundNode = backgroundNode;
  _backgroundNode.zPosition = HLZPositionBackground;
  _backgroundNode.size = self.size;
  if (_backgroundNode) {
    [self addChild:_backgroundNode];
  }
}

- (void)didChangeSize:(CGSize)oldSize
{
  if (_backgroundNode) {
    _backgroundNode.size = self.size;
  }
}

@end
