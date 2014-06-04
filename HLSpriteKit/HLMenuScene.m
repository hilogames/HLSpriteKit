//
//  HLMenuScene.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 5/29/14.
//  Copyright (c) 2014 Hilo. All rights reserved.
//

#import "HLMenuScene.h"

#import "HLMenuNode.h"
#import "HLMessageNode.h"

static const CGFloat HLZPositionBackground = 0.0f;
static const CGFloat HLZPositionMenu = 1.0f;
static const CGFloat HLZPositionMessage = 2.0f;

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
    _backgroundNode = [aDecoder decodeObjectForKey:@"backgroundNode"];
    _menuNode = [aDecoder decodeObjectForKey:@"menuNode"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  // Remove nodes that should not be encoded by super.
  BOOL messageNodeAddedToParent = (_messageNode && _messageNode.parent);
  if (messageNodeAddedToParent) {
    [_messageNode removeFromParent];
  }

  [super encodeWithCoder:aCoder];

  // Restore nodes that were removed.
  if (messageNodeAddedToParent) {
    [self addChild:_messageNode];
  }

  // note: Nodes already encoded by super; these are just pointers.
  [aCoder encodeObject:_menuNode forKey:@"menuNode"];
  [aCoder encodeObject:_backgroundNode forKey:@"backgroundNode"];
}

- (void)setBackgroundNode:(SKSpriteNode *)backgroundNode
{
  if (_backgroundNode) {
    [_backgroundNode removeFromParent];
  }
  _backgroundNode = backgroundNode;
  if (_backgroundNode) {
    _backgroundNode.zPosition = HLZPositionBackground;
    _backgroundNode.size = self.size;
    [self addChild:_backgroundNode];
  }
}

- (void)setMenuNode:(HLMenuNode *)menuNode
{
  if (_menuNode) {
    [_menuNode removeFromParent];
  }
  _menuNode = menuNode;
  if (_menuNode) {
    _menuNode.zPosition = HLZPositionMenu;
    [self addChild:_menuNode];
  }
}

- (void)setMessageNode:(HLMessageNode *)messageNode
{
  if (_messageNode && _messageNode.parent) {
    [_messageNode removeFromParent];
  }
  _messageNode = messageNode;
  if (_messageNode) {
    _messageNode.zPosition = HLZPositionMessage;
    // note: Message node adds itself to parent when instructed to show a message.
  }
}

- (void)didChangeSize:(CGSize)oldSize
{
  if (_backgroundNode) {
    _backgroundNode.size = self.size;
  }
}

@end
