//
//  HLTiledNode.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 10/8/14.
//  Copyright (c) 2014 Hilo Games. All rights reserved.
//

#import "HLTiledNode.h"

#import <TargetConditionals.h>

@implementation HLTiledNode
{
  CGSize _size;
}

+ (instancetype)tiledNodeWithImageNamed:(NSString *)name size:(CGSize)size
{
  return [[HLTiledNode alloc] initWithImageNamed:name size:size];
}

+ (instancetype)tiledNodeWithTexture:(SKTexture *)texture size:(CGSize)size
{
  return [[HLTiledNode alloc] initWithTexture:texture size:size];
}

+ (instancetype)tiledNodeWithTexture:(SKTexture *)texture color:(SKColor *)color size:(CGSize)size
{
  return [[HLTiledNode alloc] initWithTexture:texture color:color size:size];
}

- (instancetype)init
{
  return [self initWithTexture:nil color:[SKColor whiteColor] size:CGSizeZero];
}

- (instancetype)initWithImageNamed:(NSString *)name size:(CGSize)size
{
  SKTexture *texture = [SKTexture textureWithImageNamed:name];
  return [self initWithTexture:texture color:[SKColor whiteColor] size:size];
}

- (instancetype)initWithTexture:(SKTexture *)texture size:(CGSize)size
{
  return [self initWithTexture:texture color:[SKColor whiteColor] size:size];
}

- (instancetype)initWithTexture:(SKTexture *)texture color:(SKColor *)color size:(CGSize)size
{
  self = [super init];
  if (self) {
    _size = size;
    _anchorPoint = CGPointMake(0.5f, 0.5f);
    [self HL_createTileNodesWithTexture:texture color:color];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self) {
#if TARGET_OS_IPHONE
    _size = [aDecoder decodeCGSizeForKey:@"size"];
    _anchorPoint = [aDecoder decodeCGPointForKey:@"anchorPoint"];
#else
    _size = [aDecoder decodeSizeForKey:@"size"];
    _anchorPoint = [aDecoder decodePointForKey:@"anchorPoint"];
#endif
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [super encodeWithCoder:aCoder];
#if TARGET_OS_IPHONE
  [aCoder encodeCGSize:_size forKey:@"size"];
  [aCoder encodeCGPoint:_anchorPoint forKey:@"anchorPoint"];
#else
  [aCoder encodeSize:_size forKey:@"size"];
  [aCoder encodePoint:_anchorPoint forKey:@"anchorPoint"];
#endif
}

- (instancetype)copyWithZone:(NSZone *)zone
{
  HLTiledNode *copy = [super copyWithZone:zone];
  if (copy) {
    copy->_size = _size;
    copy->_anchorPoint = _anchorPoint;
  }
  return copy;
}

- (void)setSize:(CGSize)size
{
  _size = size;
  SKSpriteNode *firstChild = (SKSpriteNode *)[self.children firstObject];
  // note: Could attempt to preserve already-created tile nodes that fit
  // into the new size, for the sake of a (small?) performance gain.
  [self HL_createTileNodesWithTexture:firstChild.texture color:firstChild.color];
}

- (void)setAnchorPoint:(CGPoint)anchorPoint
{
  CGFloat deltaX = (_anchorPoint.x - anchorPoint.x) * _size.width;
  CGFloat deltaY = (_anchorPoint.y - anchorPoint.y) * _size.height;
  _anchorPoint = anchorPoint;
  for (SKSpriteNode *child in self.children) {
    CGPoint childPosition = child.position;
    childPosition.x += deltaX;
    childPosition.y += deltaY;
    child.position = childPosition;
  }
}

- (void)setTexture:(SKTexture *)texture
{
  if (!texture) {
    for (SKSpriteNode *child in self.children) {
      child.texture = nil;
    }
    return;
  }

  SKSpriteNode *firstChild = (SKSpriteNode *)[self.children firstObject];
  if (firstChild.texture && CGSizeEqualToSize(firstChild.texture.size, texture.size)) {
    for (SKSpriteNode *child in self.children) {
      child.texture = texture;
    }
  } else {
    [self HL_createTileNodesWithTexture:texture color:firstChild.color];
  }
}

- (SKTexture *)texture
{
  SKSpriteNode *firstChild = (SKSpriteNode *)[self.children firstObject];
  return firstChild.texture;
}

- (void)setColorBlendFactor:(CGFloat)colorBlendFactor
{
  for (SKSpriteNode *child in self.children) {
    child.colorBlendFactor = colorBlendFactor;
  }
}

- (CGFloat)colorBlendFactor
{
  SKSpriteNode *firstChild = (SKSpriteNode *)[self.children firstObject];
  return firstChild.colorBlendFactor;
}

- (void)setColor:(SKColor *)color
{
  for (SKSpriteNode *child in self.children) {
    child.color = color;
  }
}

- (SKColor *)color
{
  SKSpriteNode *firstChild = (SKSpriteNode *)[self.children firstObject];
  return firstChild.color;
}

- (void)setBlendMode:(SKBlendMode)blendMode
{
  for (SKSpriteNode *child in self.children) {
    child.blendMode = blendMode;
  }
}

- (SKBlendMode)blendMode
{
  SKSpriteNode *firstChild = (SKSpriteNode *)[self.children firstObject];
  return firstChild.blendMode;
}

#pragma mark -
#pragma mark Private

- (void)HL_createTileNodesWithTexture:(SKTexture *)texture color:(SKColor *)color
{
  [self removeAllChildren];

  if (texture.size.width == 0.0f || texture.size.height == 0.0f) {
    // note: Add one child anyway: Need a placeholder to hold properties.
    SKSpriteNode *tileNode = [[SKSpriteNode alloc] initWithTexture:texture color:color size:texture.size];
    [self addChild:tileNode];
    return;
  }

  CGPoint origin = CGPointMake(_anchorPoint.x * -1.0f * _size.width,
                               _anchorPoint.y * -1.0f * _size.height);
  CGSize textureSize = texture.size;
  CGFloat leftX = 0.0f;
  CGFloat bottomY = 0.0f;
  while (YES) {

    SKTexture *tileTexture = texture;

    CGFloat cropUnitHeight = 1.0f;
    if (bottomY + textureSize.height > _size.height) {
      cropUnitHeight = (_size.height - bottomY) / textureSize.height;
      tileTexture = [SKTexture textureWithRect:CGRectMake(0.0f, 0.0f, 1.0f, cropUnitHeight) inTexture:texture];
    }

    while (YES) {

      if (leftX + textureSize.width > _size.width) {
        CGFloat cropUnitWidth = (_size.width - leftX) / textureSize.width;
        tileTexture = [SKTexture textureWithRect:CGRectMake(0.0f, 0.0f, cropUnitWidth, cropUnitHeight) inTexture:texture];
      }

      SKSpriteNode *tileNode = [[SKSpriteNode alloc] initWithTexture:tileTexture color:color size:tileTexture.size];
      tileNode.anchorPoint = CGPointMake(0.0f, 0.0f);
      tileNode.position = CGPointMake(leftX + origin.x, bottomY + origin.y);
      [self addChild:tileNode];

      leftX += textureSize.width;
      if (leftX > _size.width - 0.5f) {
        leftX = 0.0f;
        break;
      }
    }

    bottomY += textureSize.height;
    if (bottomY > _size.height - 0.5f) {
      break;
    }
  }
}

@end
