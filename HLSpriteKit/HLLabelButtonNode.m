//
//  HLLabelButtonNode.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 5/2/14.
//  Copyright (c) 2014 Hilo. All rights reserved.
//

#import "HLLabelButtonNode.h"

@implementation HLLabelButtonNode
{
  // note: In the first draft, the HLLabelButtonNode *was* the background node.
  // However, I split it out due to a limitation in the current iOS 7.1 SDK:
  // namely, that centerRect is not supported with changes to the size property
  // (but only the scale properties).  If that's ever changed in the future,
  // it would probably be easier to merge the background node and the HLLabelButtonNode
  // again (so that fewer properties need to be wrapped in accessors/mutators).
  SKSpriteNode *_backgroundNode;
  SKLabelNode *_labelNode;
}

- (id)initWithColor:(UIColor *)color size:(CGSize)size
{
  self = [super init];
  if (self) {
    _backgroundNode = [SKSpriteNode spriteNodeWithColor:color size:size];
    [self addChild:_backgroundNode];
    [self HL_labelButtonNodeInitCommon];
  }
  return self;
}

- (id)initWithTexture:(SKTexture *)texture
{
  self = [super init];
  if (self) {
    _backgroundNode = [SKSpriteNode spriteNodeWithTexture:texture];
    [self addChild:_backgroundNode];
    [self HL_labelButtonNodeInitCommon];
  }
  return self;
}

- (id)initWithImageNamed:(NSString *)name
{
  self = [super init];
  if (self) {
    _backgroundNode = [SKSpriteNode spriteNodeWithImageNamed:name];
    [self addChild:_backgroundNode];
    [self HL_labelButtonNodeInitCommon];
  }
  return self;
}

- (void)HL_labelButtonNodeInitCommon
{
  _automaticWidth = NO;
  _automaticHeight = NO;
  _verticalAlignmentMode = HLLabelButtonNodeVerticalAlignText;
  _labelPadX = 0.0f;
  _labelPadY = 0.0f;
  _labelNode = [SKLabelNode labelNodeWithFontNamed:@"Helvetica"];
  _labelNode.zPosition = 1.0f;
  [self addChild:_labelNode];
  [self HL_layout];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
  // note: '"Error loading image resource: "MissingResource.png"' during this call to super;
  // it happens when decoding a SKLabelNode on 7.1 devices/simulator.  (If you set Deployment
  // Target to 7.0 and run on a 7.0 simulator, then there is no error.)  Ignore for now, since
  // everything seems to work okay; issue is recorded on StackOverflow here:
  // http://stackoverflow.com/questions/22701029/ios-keyed-archive-sprite-kit-decode-error-sktexture-error-loading-image-resour
  self = [super initWithCoder:aDecoder];
  if (self) {
    // note: Child nodes already decoded in super.  Here we're just hooking up
    // the pointers.
    _backgroundNode = [aDecoder decodeObjectForKey:@"backgroundNode"];
    _labelNode = [aDecoder decodeObjectForKey:@"labelNode"];
    _automaticWidth = [aDecoder decodeBoolForKey:@"automaticWidth"];
    _automaticHeight = [aDecoder decodeBoolForKey:@"automaticHeight"];
    _verticalAlignmentMode = (HLLabelButtonNodeVerticalAlignmentMode)[aDecoder decodeIntForKey:@"verticalAlignmentMode"];
    _labelPadX = [aDecoder decodeFloatForKey:@"labelPadX"];
    _labelPadY = [aDecoder decodeFloatForKey:@"labelPadY"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [super encodeWithCoder:aCoder];
  // note: Child nodes already decoded in super.  Here we're just recording the pointers.
  [aCoder encodeObject:_backgroundNode forKey:@"backgroundNode"];
  [aCoder encodeObject:_labelNode forKey:@"labelNode"];
  [aCoder encodeBool:_automaticWidth forKey:@"automaticWidth"];
  [aCoder encodeBool:_automaticHeight forKey:@"automaticHeight"];
  [aCoder encodeInt:(int)_verticalAlignmentMode forKey:@"verticalAlignmentMode"];
  [aCoder encodeFloat:_labelPadX forKey:@"labelPadX"];
  [aCoder encodeFloat:_labelPadY forKey:@"labelPadY"];
}

- (id)copyWithZone:(NSZone *)zone
{
  HLLabelButtonNode *copy = [[[self class] allocWithZone:zone] init];
  if (_backgroundNode) {
    copy->_backgroundNode = [_backgroundNode copyWithZone:zone];
    [copy addChild:copy->_backgroundNode];
  } else {
    copy->_backgroundNode = nil;
  }
  if (_labelNode) {
    copy->_labelNode = [_labelNode copyWithZone:zone];
    [copy addChild:copy->_labelNode];
  } else {
    copy->_labelNode = nil;
  }
  copy->_automaticHeight = _automaticHeight;
  copy->_automaticWidth = _automaticWidth;
  copy->_verticalAlignmentMode = _verticalAlignmentMode;
  copy->_labelPadX = _labelPadX;
  copy->_labelPadY = _labelPadY;
  return copy;
}

- (void)setText:(NSString *)text
{
  _labelNode.text = text;
  [self HL_layout];
}

- (NSString *)text
{
  return _labelNode.text;
}

- (void)setSize:(CGSize)size
{
  if (_backgroundNode.texture) {
    // note: Background node is the important node in terms of overall size.
    // Translate size into scaling because this button supports non-uniform
    // scaling with centerRect and size, but (currently) SKSpriteNode doesn't
    // do non-uniform scaling with the size property.
    if (_backgroundNode.texture.size.width > 0.0f) {
      _backgroundNode.xScale = size.width / _backgroundNode.texture.size.width;
    }
    if (_backgroundNode.texture.size.height > 0.0f) {
      _backgroundNode.yScale = size.height / _backgroundNode.texture.size.height;
    }
  } else {
    _backgroundNode.size = size;
  }
  [self HL_layout];
}

- (CGSize)size
{
  if (_backgroundNode.texture) {
    return CGSizeMake(_backgroundNode.texture.size.width * _backgroundNode.xScale,
                      _backgroundNode.texture.size.height * _backgroundNode.yScale);
  } else {
    return _backgroundNode.size;
  }
}

- (void)setAutomaticWidth:(BOOL)automaticWidth
{
  _automaticWidth = automaticWidth;
  [self HL_layout];
}

- (void)setAutomaticHeight:(BOOL)automaticHeight
{
  _automaticHeight = automaticHeight;
  [self HL_layout];
}

- (void)setVerticalAlignmentMode:(HLLabelButtonNodeVerticalAlignmentMode)verticalAlignmentMode
{
  _verticalAlignmentMode = verticalAlignmentMode;
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

- (void)setCenterRect:(CGRect)centerRect
{
  _backgroundNode.centerRect = centerRect;
}

- (CGRect)centerRect
{
  return _backgroundNode.centerRect;
}

- (void)HL_layout
{
  CGSize newSize;
  // note: Support non-uniform scaling of texture according to the size property
  // (of this object) by setting the scale property of _backgroundNode rather
  // than the size property.
  if (_backgroundNode.texture) {
    newSize.width = _backgroundNode.texture.size.width * _backgroundNode.xScale;
    newSize.height = _backgroundNode.texture.size.height * _backgroundNode.yScale;
  } else {
    newSize = _backgroundNode.size;
  }

  if (_automaticWidth) {
    newSize.width = _labelNode.frame.size.width + _labelPadX * 2.0f;
  }

  if (_verticalAlignmentMode == HLLabelButtonNodeVerticalAlignText) {
    _labelNode.verticalAlignmentMode = SKLabelVerticalAlignmentModeCenter;
    if (_automaticHeight) {
      newSize.height = _labelNode.frame.size.height + _labelPadY * 2.0f;
    }
    _labelNode.position = CGPointMake(0.0f, 0.0f);
  } else if (_verticalAlignmentMode == HLLabelButtonNodeVerticalAlignFont) {
    _labelNode.verticalAlignmentMode = SKLabelVerticalAlignmentModeBaseline;
    UIFont *font = [UIFont fontWithName:_labelNode.fontName size:_labelNode.fontSize];
    if (_automaticHeight) {
      newSize.height = font.lineHeight + _labelPadY * 2.0f;
    }
    _labelNode.position = CGPointMake(0.0f, -font.lineHeight / 2.0f - font.descender);
  } else if (_verticalAlignmentMode == HLLabelButtonNodeVerticalAlignFontAscender) {
    _labelNode.verticalAlignmentMode = SKLabelVerticalAlignmentModeBaseline;
    UIFont *font = [UIFont fontWithName:_labelNode.fontName size:_labelNode.fontSize];
    if (_automaticHeight) {
      newSize.height = font.ascender + _labelPadY * 2.0f;
    }
    _labelNode.position = CGPointMake(0.0f, -font.ascender / 2.0f);
  } else {
    [NSException raise:@"HLLabelButtonNodeUnknownVerticalAlignmentMode" format:@"Unknown vertical alignment mode %d.", _verticalAlignmentMode];
  }

  if (_automaticWidth || _automaticHeight) {
    if (_backgroundNode.texture) {
      _backgroundNode.xScale = newSize.width / _backgroundNode.texture.size.width;
      _backgroundNode.yScale = newSize.height / _backgroundNode.texture.size.height;
    } else {
      _backgroundNode.size = newSize;
    }
  }
}

@end
