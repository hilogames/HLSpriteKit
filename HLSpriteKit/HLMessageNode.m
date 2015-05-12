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
  return [self initWithColor:[SKColor blackColor] size:CGSizeMake(320.0f, 40.0f)];
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
  CGFloat zPositionLayerIncrement = self.zPositionScale / HLMessageNodeZPositionLayerCount;

  _backgroundNode = backgroundNode;
  _backgroundNode.zPosition = HLMessageNodeZPositionLayerBackground * zPositionLayerIncrement;
  [self addChild:_backgroundNode];

  _verticalAlignmentMode = HLLabelNodeVerticalAlignFont;

  _messageAnimation = HLMessageNodeAnimationSlideLeft;
  _messageAnimationDuration = 0.1;
  _messageLingerDuration = 2.0;

  _labelNode = [SKLabelNode labelNodeWithFontNamed:@"Courier"];
  _labelNode.zPosition = (HLMessageNodeZPositionLayerLabel - HLMessageNodeZPositionLayerBackground) * zPositionLayerIncrement;
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
  [self HL_layoutLabelNode];
}

- (CGPoint)anchorPoint
{
  return _backgroundNode.anchorPoint;
}

- (void)setAnchorPoint:(CGPoint)anchorPoint
{
  _backgroundNode.anchorPoint = anchorPoint;
  [self HL_layoutLabelNode];
}

- (void)setZPositionScale:(CGFloat)zPositionScale
{
  [super setZPositionScale:zPositionScale];
  CGFloat zPositionLayerIncrement = zPositionScale / HLMessageNodeZPositionLayerCount;
  _backgroundNode.zPosition = HLMessageNodeZPositionLayerBackground * zPositionLayerIncrement;
  _labelNode.zPosition = HLMessageNodeZPositionLayerLabel * zPositionLayerIncrement;
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
  BOOL newlyAdded;
  if (!self.parent) {
    [parent addChild:self];
    newlyAdded = YES;
  } else if (self.parent != parent) {
    [self removeFromParent];
    [parent addChild:self];
    newlyAdded = YES;
  } else {
    newlyAdded = NO;
  }

  const NSTimeInterval GLTimingEpsilon = 0.001;
  BOOL lingerForever = (_messageLingerDuration < GLTimingEpsilon);

  _labelNode.text = message;
  
  // note: Reset state for ALL possible animation types; the _messageAnimation
  // type could have changed since it was last animated.  If this gets too crazy,
  // though, then another solution can be found.
  if (!newlyAdded) {
    [_backgroundNode removeActionForKey:@"show"];
    _backgroundNode.position = CGPointZero;
    _backgroundNode.alpha = 1.0f;
  }

  NSMutableArray *showActions = [NSMutableArray array];
  switch (_messageAnimation) {
    case HLMessageNodeAnimationSlideLeft: {
      if (newlyAdded) {
        _backgroundNode.position = CGPointMake(_backgroundNode.size.width, 0.0f);
        [showActions addObject:[SKAction moveToX:0.0f duration:_messageAnimationDuration]];
      }
      if (!lingerForever) {
        [showActions addObject:[SKAction waitForDuration:_messageLingerDuration]];
        [showActions addObject:[SKAction moveToX:-_backgroundNode.size.width duration:_messageAnimationDuration]];
      }
      break;
    }
    case HLMessageNodeAnimationSlideRight: {
      if (newlyAdded) {
        _backgroundNode.position = CGPointMake(-_backgroundNode.size.width, 0.0f);
        [showActions addObject:[SKAction moveToX:0.0f duration:_messageAnimationDuration]];
      }
      if (!lingerForever) {
        [showActions addObject:[SKAction waitForDuration:_messageLingerDuration]];
        [showActions addObject:[SKAction moveToX:_backgroundNode.size.width duration:_messageAnimationDuration]];
      }
      break;
    }
    case HLMessageNodeAnimationFade: {
      if (newlyAdded) {
        _backgroundNode.alpha = 0.0f;
        [showActions addObject:[SKAction fadeInWithDuration:_messageAnimationDuration]];
      }
      if (!lingerForever) {
        [showActions addObject:[SKAction waitForDuration:_messageLingerDuration]];
        [showActions addObject:[SKAction fadeOutWithDuration:_messageAnimationDuration]];
      }
      break;
    }
  }
  if (!lingerForever) {
    // note: As of iOS8, doing the remove using an [SKAction removeFromParent] causes EXC_BAD_ACCESS.
    [showActions addObject:[SKAction runBlock:^{
      [self removeFromParent];
    }]];
  }
  if ([showActions count] > 0) {
    [_backgroundNode runAction:[SKAction sequence:showActions] withKey:@"show"];
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
  _labelNode.position = CGPointMake((0.5f - _backgroundNode.anchorPoint.x) * _backgroundNode.size.width,
                                    (0.5f - _backgroundNode.anchorPoint.y) * _backgroundNode.size.height);
  [_labelNode alignForHLVerticalAlignmentMode:_verticalAlignmentMode];
}

@end
