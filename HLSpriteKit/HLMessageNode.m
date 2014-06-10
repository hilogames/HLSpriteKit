//
//  HLMessageNode.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 6/2/14.
//  Copyright (c) 2014 Hilo. All rights reserved.
//

#import "HLMessageNode.h"

@implementation HLMessageNode
{
  SKLabelNode *_labelNode;
}

- (id)initWithColor:(UIColor *)color size:(CGSize)size
{
  self = [super initWithColor:color size:size];
  if (self) {
    [self HL_messageNodeInitCommon];
  }
  return self;
}

- (id)initWithImageNamed:(NSString *)name
{
  self = [super initWithImageNamed:name];
  if (self) {
    [self HL_messageNodeInitCommon];
  }
  return self;
}

- (id)initWithTexture:(SKTexture *)texture
{
  self = [super initWithTexture:texture];
  if (self) {
    [self HL_messageNodeInitCommon];
  }
  return self;
}

- (id)initWithTexture:(SKTexture *)texture color:(UIColor *)color size:(CGSize)size
{
  self = [super initWithTexture:texture color:color size:size];
  if (self) {
    [self HL_messageNodeInitCommon];
  }
  return self;
}

- (void)HL_messageNodeInitCommon
{
  _verticalAlignmentMode = HLLabelNodeVerticalAlignFont;

  _messageAnimationDuration = 0.1;
  _messageLingerDuration = 2.0;

  _labelNode = [SKLabelNode labelNodeWithFontNamed:@"Courier"];
  _labelNode.fontSize = 14.0f;
  _labelNode.fontColor = [UIColor whiteColor];
  [self addChild:_labelNode];

  [self HL_layoutLabelNode];
}

- (id)copyWithZone:(NSZone *)zone
{
  HLMessageNode *copy = [super copyWithZone:zone];
  for (SKNode *child in copy.children) {
    if ([child isKindOfClass:[SKLabelNode class]]) {
      copy->_labelNode = (SKLabelNode *)child;
    }
  }
  copy->_verticalAlignmentMode = _verticalAlignmentMode;
  copy->_messageAnimationDuration = _messageAnimationDuration;
  copy->_messageLingerDuration = _messageLingerDuration;
  return nil;
}

- (void)setVerticalAlignmentMode:(HLLabelNodeVerticalAlignmentMode)verticalAlignmentMode
{
  _verticalAlignmentMode = verticalAlignmentMode;
  [self HL_layoutLabelNode];
}

- (NSString *)fontName
{
  return _labelNode.fontName;
}

- (void)setFontName:(NSString *)fontName
{
  _labelNode.fontName = fontName;
  [self HL_layoutLabelNode];
}

- (CGFloat)fontSize
{
  return _labelNode.fontSize;
}

- (void)setFontSize:(CGFloat)fontSize
{
  _labelNode.fontSize = fontSize;
  [self HL_layoutLabelNode];
}

- (SKColor *)fontColor
{
  return _labelNode.fontColor;
}

- (void)setFontColor:(SKColor *)fontColor
{
  _labelNode.fontColor = fontColor;
}

- (void)showMessage:(NSString *)message parent:(SKNode *)parent
{
  _labelNode.text = message;
    
  if (!self.parent || self.parent != parent) {
    [parent addChild:self];
    CGPoint messageNodePosition = self.position;
    messageNodePosition.x = self.size.width;
    self.position = messageNodePosition;
    SKAction *slideIn = [SKAction moveToX:0.0f duration:_messageAnimationDuration];
    SKAction *wait = [SKAction waitForDuration:_messageLingerDuration];
    SKAction *slideOut = [SKAction moveToX:-self.size.width duration:_messageAnimationDuration];
    SKAction *remove = [SKAction removeFromParent];
    SKAction *show = [SKAction sequence:@[slideIn, wait, slideOut, remove ]];
    [self runAction:show withKey:@"show"];
  } else {
    [self removeActionForKey:@"show"];
    SKAction *wait = [SKAction waitForDuration:_messageLingerDuration];
    SKAction *slideOut = [SKAction moveToX:-self.size.width duration:_messageAnimationDuration];
    SKAction *remove = [SKAction removeFromParent];
    SKAction *show = [SKAction sequence:@[ wait, slideOut, remove ]];
    [self runAction:show withKey:@"show"];
  }
}

- (void)hideMessage
{
  if (self.parent) {
    [self removeActionForKey:@"show"];
    [self removeFromParent];
  }
}

- (void)HL_layoutLabelNode
{
  SKLabelVerticalAlignmentMode skVerticalAlignmentMode;
  CGFloat alignedYPosition;
  [_labelNode getAlignmentInNode:self
      forHLVerticalAlignmentMode:_verticalAlignmentMode
         skVerticalAlignmentMode:&skVerticalAlignmentMode
                     labelHeight:nil
                       yPosition:&alignedYPosition];

  _labelNode.verticalAlignmentMode = skVerticalAlignmentMode;
  _labelNode.position = CGPointMake(0.0f, alignedYPosition);
}

@end
