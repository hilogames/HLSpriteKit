//
//  HLMessageNode.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 6/2/14.
//  Copyright (c) 2014 Hilo Games. All rights reserved.
//

#import "HLMessageNode.h"

enum {
  HLMessageNodeZPositionLayerBackground = 0,
  HLMessageNodeZPositionLayerLabel,
  HLMessageNodeZPositionLayerCount
};

@implementation HLMessageNode
{
  SKSpriteNode *_backgroundNode;
  SKLabelNode *_labelNode;
}

- (instancetype)init
{
  return [self initWithColor:[SKColor whiteColor] size:CGSizeMake(320.0f, 40.0f)];
}

- (instancetype)initWithColor:(SKColor *)color size:(CGSize)size
{
  self = [super init];
  if (self) {
    SKSpriteNode *backgroundNode = [[SKSpriteNode alloc] initWithColor:color size:size];
    [self HL_messageNodeInitCommon:backgroundNode];
  }
  return self;
}

- (instancetype)initWithImageNamed:(NSString *)name
{
  self = [super init];
  if (self) {
    SKSpriteNode *backgroundNode = [[SKSpriteNode alloc] initWithImageNamed:name];
    [self HL_messageNodeInitCommon:backgroundNode];
  }
  return self;
}

- (instancetype)initWithTexture:(SKTexture *)texture
{
  self = [super init];
  if (self) {
    SKSpriteNode *backgroundNode = [[SKSpriteNode alloc] initWithTexture:texture];
    [self HL_messageNodeInitCommon:backgroundNode];
  }
  return self;
}

- (instancetype)initWithTexture:(SKTexture *)texture color:(UIColor *)color size:(CGSize)size
{
  self = [super init];
  if (self) {
    SKSpriteNode *backgroundNode = [[SKSpriteNode alloc] initWithTexture:texture color:color size:size];
    [self HL_messageNodeInitCommon:backgroundNode];
  }
  return self;
}

- (void)HL_messageNodeInitCommon:(SKSpriteNode *)backgroundNode
{
  _backgroundNode = backgroundNode;
  [self addChild:_backgroundNode];

  _verticalAlignmentMode = HLLabelNodeVerticalAlignFont;

  _messageAnimationDuration = 0.1;
  _messageLingerDuration = 2.0;

  _labelNode = [SKLabelNode labelNodeWithFontNamed:@"Courier"];
  _labelNode.zPosition = self.zPositionScale / HLMessageNodeZPositionLayerCount;
  _labelNode.fontSize = 14.0f;
  _labelNode.fontColor = [UIColor whiteColor];
  [_backgroundNode addChild:_labelNode];
  
  [self HL_layoutLabelNode];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  [NSException raise:@"HLCodingNotImplemented" format:@"Coding not implemented for this descendant of an NSCoding parent."];
  // note: Call [init] for the sake of the compiler trying to detect problems with designated initializers.
  return [self init];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
  HLMessageNode *copy = [super copyWithZone:zone];
  for (SKNode *child in copy.children) {
    if ([child isKindOfClass:[SKSpriteNode class]]) {
      copy->_backgroundNode = (SKSpriteNode *)child;
      for (SKNode *childChild in child.children) {
        if ([childChild isKindOfClass:[SKLabelNode class]]) {
          copy->_labelNode = (SKLabelNode *)childChild;
        }
      }
    }
  }
  copy->_verticalAlignmentMode = _verticalAlignmentMode;
  copy->_messageAnimationDuration = _messageAnimationDuration;
  copy->_messageLingerDuration = _messageLingerDuration;
  copy->_messageSoundFile = _messageSoundFile;
  return copy;
}

- (CGSize)size
{
  return _backgroundNode.size;
}

- (void)setSize:(CGSize)size
{
  _backgroundNode.size = size;
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
    _backgroundNode.position = CGPointMake(_backgroundNode.size.width, 0.0f);
    SKAction *slideIn = [SKAction moveToX:0.0f duration:_messageAnimationDuration];
    SKAction *wait = [SKAction waitForDuration:_messageLingerDuration];
    SKAction *slideOut = [SKAction moveToX:-_backgroundNode.size.width duration:_messageAnimationDuration];
    SKAction *remove = [SKAction runBlock:^{
      [self removeFromParent];
    }];
    SKAction *show = [SKAction sequence:@[slideIn, wait, slideOut, remove ]];
    [_backgroundNode runAction:show withKey:@"show"];
  } else {
    // note: Remove animation and reset position to home (in case the animation was in the middle of running).
    [_backgroundNode removeActionForKey:@"show"];
    _backgroundNode.position = CGPointZero;
    SKAction *wait = [SKAction waitForDuration:_messageLingerDuration];
    SKAction *slideOut = [SKAction moveToX:-_backgroundNode.size.width duration:_messageAnimationDuration];
    SKAction *remove = [SKAction runBlock:^{
      [self removeFromParent];
    }];
    SKAction *show = [SKAction sequence:@[ wait, slideOut, remove ]];
    [_backgroundNode runAction:show withKey:@"show"];
  }
  if (_messageSoundFile) {
    [_backgroundNode runAction:[SKAction playSoundFileNamed:_messageSoundFile waitForCompletion:NO]];
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
  [_labelNode getAlignmentInNode:_backgroundNode
      forHLVerticalAlignmentMode:_verticalAlignmentMode
         skVerticalAlignmentMode:&skVerticalAlignmentMode
                     labelHeight:nil
                       yPosition:&alignedYPosition];

  _labelNode.verticalAlignmentMode = skVerticalAlignmentMode;
  _labelNode.position = CGPointMake(0.0f, alignedYPosition);
}

@end
