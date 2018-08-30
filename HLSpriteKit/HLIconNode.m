//
//  HLIconNode.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 8/6/18.
//  Copyright (c) 2018 Hilo Games. All rights reserved.
//

#import "HLIconNode.h"

@implementation HLIconNode
{
  SKSpriteNode *_spriteNode;
  SKLabelNode *_labelNode;
}

- (instancetype)initWithTexture:(SKTexture *)texture
{
  self = [super init];
  if (self) {
    _spriteNode = [SKSpriteNode spriteNodeWithTexture:texture];
    [self addChild:_spriteNode];
    [self HL_iconNodeInitCommon];
  }
  return self;
}

- (instancetype)initWithImageNamed:(NSString *)name
{
  self = [super init];
  if (self) {
    _spriteNode = [SKSpriteNode spriteNodeWithImageNamed:name];
    [self addChild:_spriteNode];
    [self HL_iconNodeInitCommon];
  }
  return self;
}

- (void)HL_iconNodeInitCommon
{
  _heightMode = HLLabelHeightModeText;
  _labelPadY = 0.0f;
  _labelNode = [SKLabelNode labelNodeWithFontNamed:@"Helvetica"];
  [self HL_layout];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self) {
    // note: Child nodes already decoded in super.  Here we're just hooking up
    // the pointers.
    _spriteNode = [aDecoder decodeObjectForKey:@"spriteNode"];
    _labelNode = [aDecoder decodeObjectForKey:@"labelNode"];
    _heightMode = (HLLabelHeightMode)[aDecoder decodeIntegerForKey:@"heightMode"];
    _labelPadY = (CGFloat)[aDecoder decodeDoubleForKey:@"labelPadY"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [super encodeWithCoder:aCoder];
  // note: Child nodes already decoded in super.  Here we're just recording the pointers.
  [aCoder encodeObject:_spriteNode forKey:@"spriteNode"];
  [aCoder encodeObject:_labelNode forKey:@"labelNode"];
  [aCoder encodeInteger:_heightMode forKey:@"heightMode"];
  [aCoder encodeDouble:_labelPadY forKey:@"labelPadY"];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
  HLIconNode *copy = [super copyWithZone:zone];
  // noob: SKNode copy deep-copies all children; need to hook up our pointers, though.  (I
  // guess this is why finding nodes by name is recommended.)
  for (SKNode *child in copy.children) {
    if ([child isKindOfClass:[SKSpriteNode class]]) {
      copy->_spriteNode = (SKSpriteNode *)child;
    } else if ([child isKindOfClass:[SKLabelNode class]]) {
      copy->_labelNode = (SKLabelNode *)child;
    }
  }
  copy->_heightMode = _heightMode;
  copy->_labelPadY = _labelPadY;
  return copy;
}

- (SKTexture *)texture
{
  return _spriteNode.texture;
}

- (void)setTexture:(SKTexture *)texture
{
  _spriteNode.texture = texture;
}

- (void)setText:(NSString *)text
{
  _labelNode.text = text;
  if (text) {
    if (!_labelNode.parent) {
      [self addChild:_labelNode];
    }
    [self HL_layout];
  } else {
    if (_labelNode.parent) {
      [_labelNode removeFromParent];
    }
  }
}

- (NSString *)text
{
  return _labelNode.text;
}

- (void)setSize:(CGSize)size
{
  _spriteNode.size = size;
  [self HL_layout];
}

- (CGSize)size
{
  return _spriteNode.size;
}

- (void)setAnchorPoint:(CGPoint)anchorPoint
{
  _spriteNode.anchorPoint = anchorPoint;
  [self HL_layout];
}

- (CGPoint)anchorPoint
{
  return _spriteNode.anchorPoint;
}

- (void)setHeightMode:(HLLabelHeightMode)heightMode
{
  _heightMode = heightMode;
  [self HL_layout];
}

- (void)setLabelPadY:(CGFloat)labelPadY
{
  _labelPadY = labelPadY;
  [self HL_layout];
}

- (NSString *)fontName
{
  return _labelNode.fontName;
}

- (void)setFontName:(NSString *)fontName
{
  _labelNode.fontName = fontName;
  [self HL_layout];
}

- (CGFloat)fontSize
{
  return _labelNode.fontSize;
}

- (void)setFontSize:(CGFloat)fontSize
{
  _labelNode.fontSize = fontSize;
  [self HL_layout];
}

- (SKColor *)fontColor
{
  return _labelNode.fontColor;
}

- (void)setFontColor:(SKColor *)fontColor
{
  _labelNode.fontColor = fontColor;
}

- (SKColor *)color
{
  return _spriteNode.color;
}

- (void)setColor:(SKColor *)color
{
  _spriteNode.color = color;
}

- (CGFloat)colorBlendFactor
{
  return _spriteNode.colorBlendFactor;
}

- (void)setColorBlendFactor:(CGFloat)colorBlendFactor
{
  _spriteNode.colorBlendFactor = colorBlendFactor;
}

- (void)HL_layout
{
  // note: All layout concerns the label node relative to the sprite node; if no
  // text, then no need for layout.
  if (!_labelNode.text) {
    assert(!_labelNode.parent);
    return;
  }

  SKLabelVerticalAlignmentMode useVerticalAlignmentMode;
  CGFloat alignedOffsetY;
  [_labelNode getVerticalAlignmentForAlignmentMode:SKLabelVerticalAlignmentModeTop
                                        heightMode:_heightMode
                                  useAlignmentMode:&useVerticalAlignmentMode
                                       labelHeight:nil
                                           offsetY:&alignedOffsetY];
  _labelNode.verticalAlignmentMode = useVerticalAlignmentMode;
  _labelNode.position = CGPointMake((0.5f - _spriteNode.anchorPoint.x) * _spriteNode.size.width,
                                    -_spriteNode.anchorPoint.y * _spriteNode.size.height - _labelPadY + alignedOffsetY);
}

@end
