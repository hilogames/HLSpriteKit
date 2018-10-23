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
  SKTexture *_texture;
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

+ (instancetype)tiledNodeWithTexture:(SKTexture *)texture
                                size:(CGSize)size
                            sizeMode:(HLTiledNodeSizeMode)sizeMode
                         anchorPoint:(CGPoint)anchorPoint
                          centerRect:(CGRect)centerRect
{
  return [[HLTiledNode alloc] initWithTexture:texture size:size sizeMode:sizeMode anchorPoint:anchorPoint centerRect:centerRect];
}

- (instancetype)init
{
  self = [super init];
  if (self) {
    _texture = nil;
    _anchorPoint = CGPointMake(0.5f, 0.5f);
    _centerRect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    _sizeMode = HLTiledNodeSizeModeCrop;
    [self HL_createTileNodesWithSize:CGSizeZero];
  }
  return self;
}

- (instancetype)initWithImageNamed:(NSString *)name size:(CGSize)size
{
  self = [super init];
  if (self) {
    _texture = [SKTexture textureWithImageNamed:name];
    _anchorPoint = CGPointMake(0.5f, 0.5f);
    _centerRect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    _sizeMode = HLTiledNodeSizeModeCrop;
    [self HL_createTileNodesWithSize:size];
  }
  return self;
}

- (instancetype)initWithTexture:(SKTexture *)texture size:(CGSize)size
{
  self = [super init];
  if (self) {
    _texture = texture;
    _anchorPoint = CGPointMake(0.5f, 0.5f);
    _centerRect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    _sizeMode = HLTiledNodeSizeModeCrop;
    [self HL_createTileNodesWithSize:size];
  }
  return self;
}

- (instancetype)initWithTexture:(SKTexture *)texture color:(SKColor *)color size:(CGSize)size
{
  self = [super init];
  if (self) {
    _texture = texture;
    _anchorPoint = CGPointMake(0.5f, 0.5f);
    _centerRect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    _sizeMode = HLTiledNodeSizeModeCrop;
    [self HL_createTileNodesWithSize:size];
    [self HL_updateTileNodePropertiesWithColor:color
                              colorBlendFactor:1.0f
                                     blendMode:SKBlendModeAlpha];
  }
  return self;
}

- (instancetype)initWithTexture:(SKTexture *)texture
                           size:(CGSize)size
                       sizeMode:(HLTiledNodeSizeMode)sizeMode
                    anchorPoint:(CGPoint)anchorPoint
                     centerRect:(CGRect)centerRect
{
  self = [super init];
  if (self) {
    _texture = texture;
    _anchorPoint = anchorPoint;
    _centerRect = centerRect;
    _sizeMode = sizeMode;
    [self HL_createTileNodesWithSize:size];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self) {
    _texture = [aDecoder decodeObjectForKey:@"texture"];
    _sizeMode = [aDecoder decodeIntegerForKey:@"sizeMode"];
#if TARGET_OS_IPHONE
    _size = [aDecoder decodeCGSizeForKey:@"size"];
    _anchorPoint = [aDecoder decodeCGPointForKey:@"anchorPoint"];
    _centerRect = [aDecoder decodeCGRectForKey:@"centerRect"];
#else
    _size = [aDecoder decodeSizeForKey:@"size"];
    _anchorPoint = [aDecoder decodePointForKey:@"anchorPoint"];
    _centerRect = [aDecoder decodeRectForKey:@"centerRect"];
#endif
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [super encodeWithCoder:aCoder];
  [aCoder encodeObject:_texture forKey:@"texture"];
  [aCoder encodeInteger:_sizeMode forKey:@"sizeMode"];
#if TARGET_OS_IPHONE
  [aCoder encodeCGSize:_size forKey:@"size"];
  [aCoder encodeCGPoint:_anchorPoint forKey:@"anchorPoint"];
  [aCoder encodeCGRect:_centerRect forKey:@"centerRect"];
#else
  [aCoder encodeSize:_size forKey:@"size"];
  [aCoder encodePoint:_anchorPoint forKey:@"anchorPoint"];
  [aCoder encodeRect:_centerRect forKey:@"centerRect"];
#endif
}

- (instancetype)copyWithZone:(NSZone *)zone
{
  HLTiledNode *copy = [super copyWithZone:zone];
  if (copy) {
    copy->_texture = _texture;
    copy->_size = _size;
    copy->_sizeMode = _sizeMode;
    copy->_anchorPoint = _anchorPoint;
    copy->_centerRect = _centerRect;
  }
  return copy;
}

- (void)setSize:(CGSize)size
{
  SKSpriteNode *firstChild = (SKSpriteNode *)[self.children firstObject];
  [self HL_createTileNodesWithSize:size];
  [self HL_updateTileNodePropertiesWithColor:firstChild.color
                            colorBlendFactor:firstChild.colorBlendFactor
                                   blendMode:firstChild.blendMode];
}

- (void)setSizeMode:(HLTiledNodeSizeMode)sizeMode
{
  _sizeMode = sizeMode;
  SKSpriteNode *firstChild = (SKSpriteNode *)[self.children firstObject];
  [self HL_createTileNodesWithSize:_size];
  [self HL_updateTileNodePropertiesWithColor:firstChild.color
                            colorBlendFactor:firstChild.colorBlendFactor
                                   blendMode:firstChild.blendMode];
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
  _texture = texture;
  SKSpriteNode *firstChild = (SKSpriteNode *)[self.children firstObject];
  [self HL_createTileNodesWithSize:_size];
  [self HL_updateTileNodePropertiesWithColor:firstChild.color
                            colorBlendFactor:firstChild.colorBlendFactor
                                   blendMode:firstChild.blendMode];
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

- (void)HL_createTileNodesWithSize:(CGSize)size
{
  // note: Sets _size as a side effect, based on _sizeMode.

  [self removeAllChildren];

  const CGFloat HLTileFitEpsilon = 0.01f;

  if (!_texture
      || _texture.size.width < HLTileFitEpsilon
      || _texture.size.height < HLTileFitEpsilon) {
    // note: Might have a color, in which case we should fill the space.  And anyway we
    // need at least one node to remember our properties.  Also, set _size to the
    // intended, in order to remember if for later if a texture gets set.
    SKSpriteNode *tileNode = [[SKSpriteNode alloc] initWithTexture:_texture];
    tileNode.size = size;
    tileNode.anchorPoint = _anchorPoint;
    [self addChild:tileNode];
    _size = size;
    return;
  }

  CGFloat textureWidth = _texture.size.width;
  CGFloat textureHeight = _texture.size.height;

  const CGFloat HLCenterRectEpsilon = 0.001;
  CGFloat centerRectRightX = _centerRect.origin.x + _centerRect.size.width;
  CGFloat centerRectTopY = _centerRect.origin.y + _centerRect.size.height;
  BOOL hasCenterRectLeft = (_centerRect.origin.x > HLCenterRectEpsilon);
  BOOL hasCenterRectRight = (centerRectRightX + HLCenterRectEpsilon < 1.0f);
  BOOL hasCenterRectBottom = (_centerRect.origin.y > HLCenterRectEpsilon);
  BOOL hasCenterRectTop = (centerRectTopY + HLCenterRectEpsilon < 1.0f);
  BOOL hasCenterRect = (hasCenterRectLeft || hasCenterRectRight || hasCenterRectBottom || hasCenterRectTop);

  if (hasCenterRect
      && (_centerRect.size.width < HLCenterRectEpsilon || _centerRect.size.height < HLCenterRectEpsilon)) {
    // note: Texture has borders defined by centerRect, but no middle tile.  Similar to
    // the situation above where texture size is zero.
    SKSpriteNode *tileNode = [[SKSpriteNode alloc] initWithTexture:_texture];
    tileNode.size = size;
    tileNode.anchorPoint = _anchorPoint;
    [self addChild:tileNode];
    _size = size;
    return;
  }

  // With or without centerRect, tile a "fill area" with the part of the texture used
  // for tiling.  (With centerRect, also add edges and corners.)

  CGFloat fillLeftX = 0.0f;
  CGFloat fillBottomY = 0.0f;
  CGFloat fillWidth = size.width;
  CGFloat fillHeight = size.height;
  CGFloat tileWidth = textureWidth;
  CGFloat tileHeight = textureHeight;
  CGFloat borderWidth = 0.0f;
  CGFloat borderHeight = 0.0f;
  if (hasCenterRectLeft || hasCenterRectRight) {
    fillLeftX += _centerRect.origin.x * textureWidth;
    tileWidth = _centerRect.size.width * textureWidth;
    borderWidth = (1.0f - _centerRect.size.width) * textureWidth;
    fillWidth -= borderWidth;
  }
  if (hasCenterRectBottom || hasCenterRectTop) {
    fillBottomY += _centerRect.origin.y * textureHeight;
    tileHeight = _centerRect.size.height * textureHeight;
    borderHeight = (1.0f - _centerRect.size.height) * textureHeight;
    fillHeight -= borderHeight;
  }

  if (fillWidth <= HLTileFitEpsilon || fillHeight <= HLTileFitEpsilon) {
    // note: Not enough overall size to do any tiling.  In all cases we need at least one
    // node to remember properties, but in no case do we need to continue with any more
    // logic about cropping or whatnot.
    SKSpriteNode *tileNode = nil;
    switch (_sizeMode) {
      case HLTiledNodeSizeModeWholeMinimum:
        tileNode = [[SKSpriteNode alloc] initWithTexture:_texture];
        _size = _texture.size;
        break;
      case HLTiledNodeSizeModeCrop:
      case HLTiledNodeSizeModeWholeMaximum:
        tileNode = [[SKSpriteNode alloc] initWithTexture:_texture];
        tileNode.size = size;
        _size = size;
        break;
    }
    tileNode.anchorPoint = _anchorPoint;
    [self addChild:tileNode];
    return;
  }

  NSInteger fillWidthUncroppedTileCount;
  NSInteger fillHeightUncroppedTileCount;
  CGFloat centerRectCroppedHeight = 0.0f;
  CGFloat centerRectCroppedWidth = 0.0f;
  switch (_sizeMode) {
    case HLTiledNodeSizeModeCrop: {
      fillWidthUncroppedTileCount = fillWidth / tileWidth;
      fillHeightUncroppedTileCount = fillHeight / tileHeight;
      CGFloat croppedFillWidth = fillWidth - fillWidthUncroppedTileCount * tileWidth;
      CGFloat croppedFillHeight = fillHeight - fillHeightUncroppedTileCount * tileHeight;
      if (croppedFillWidth > HLTileFitEpsilon) {
        centerRectCroppedWidth = croppedFillWidth / textureWidth;
      }
      if (croppedFillHeight > HLTileFitEpsilon) {
        centerRectCroppedHeight = croppedFillHeight / textureHeight;
      }
      _size = size;
      break;
    }
    case HLTiledNodeSizeModeWholeMinimum:
      // note: If fillWidth 10.0 and tileWidth 4.99999999, don't do three tiles.
      fillWidthUncroppedTileCount = (fillWidth - HLTileFitEpsilon) / tileWidth + 1;
      fillHeightUncroppedTileCount = (fillHeight - HLTileFitEpsilon) / tileHeight + 1;
      fillWidth = fillWidthUncroppedTileCount * tileWidth;
      fillHeight = fillHeightUncroppedTileCount * tileHeight;
      _size = CGSizeMake(borderWidth + fillWidth, borderHeight + fillHeight);
      break;
    case HLTiledNodeSizeModeWholeMaximum:
      // note: If fillWidth 10.0 and tileWidth 5.00000001, don't do just one tile.
      fillWidthUncroppedTileCount = (fillWidth + HLTileFitEpsilon) / tileWidth;
      fillHeightUncroppedTileCount = (fillHeight + HLTileFitEpsilon) / tileHeight;
      fillWidth = fillWidthUncroppedTileCount * tileWidth;
      fillHeight = fillHeightUncroppedTileCount * tileHeight;
      _size = CGSizeMake(borderWidth + fillWidth, borderHeight + fillHeight);
      break;
  }
  fillLeftX += _size.width * -_anchorPoint.x;
  fillBottomY += _size.height * -_anchorPoint.y;

  if (hasCenterRect) {

    // Corners
    if (hasCenterRectLeft) {
      if (hasCenterRectBottom) {
        SKTexture *cornerTexture = [SKTexture textureWithRect:CGRectMake(0.0f, 0.0f, _centerRect.origin.x, _centerRect.origin.y) inTexture:_texture];
        SKSpriteNode *cornerNode = [SKSpriteNode spriteNodeWithTexture:cornerTexture];
        cornerNode.anchorPoint = CGPointMake(1.0f, 1.0f);
        cornerNode.position = CGPointMake(fillLeftX, fillBottomY);
        [self addChild:cornerNode];
      }
      if (hasCenterRectTop) {
        SKTexture *cornerTexture = [SKTexture textureWithRect:CGRectMake(0.0f, centerRectTopY, _centerRect.origin.x, (1.0f - centerRectTopY)) inTexture:_texture];
        SKSpriteNode *cornerNode = [SKSpriteNode spriteNodeWithTexture:cornerTexture];
        cornerNode.anchorPoint = CGPointMake(1.0f, 0.0f);
        cornerNode.position = CGPointMake(fillLeftX, fillBottomY + fillHeight);
        [self addChild:cornerNode];
      }
    }
    if (hasCenterRectRight) {
      if (hasCenterRectBottom) {
        SKTexture *cornerTexture = [SKTexture textureWithRect:CGRectMake(centerRectRightX, 0.0f, (1.0f - centerRectRightX), _centerRect.origin.y) inTexture:_texture];
        SKSpriteNode *cornerNode = [SKSpriteNode spriteNodeWithTexture:cornerTexture];
        cornerNode.anchorPoint = CGPointMake(0.0f, 1.0f);
        cornerNode.position = CGPointMake(fillLeftX + fillWidth, fillBottomY);
        [self addChild:cornerNode];
      }
      if (hasCenterRectTop) {
        SKTexture *cornerTexture = [SKTexture textureWithRect:CGRectMake(centerRectRightX, centerRectTopY, (1.0f - centerRectRightX), (1.0f - centerRectTopY)) inTexture:_texture];
        SKSpriteNode *cornerNode = [SKSpriteNode spriteNodeWithTexture:cornerTexture];
        cornerNode.anchorPoint = CGPointMake(0.0f, 0.0f);
        cornerNode.position = CGPointMake(fillLeftX + fillWidth, fillBottomY + fillHeight);
        [self addChild:cornerNode];
      }
    }

    // Edges
    if (hasCenterRectLeft) {
      SKTexture *edgeTexture = [SKTexture textureWithRect:CGRectMake(0.0f, _centerRect.origin.y, _centerRect.origin.x, _centerRect.size.height) inTexture:_texture];
      CGFloat edgeY = fillBottomY;
      for (NSInteger t = 0; t < fillHeightUncroppedTileCount; ++t) {
        SKSpriteNode *edgeNode = [SKSpriteNode spriteNodeWithTexture:edgeTexture];
        edgeNode.anchorPoint = CGPointMake(1.0f, 0.0f);
        edgeNode.position = CGPointMake(fillLeftX, edgeY);
        [self addChild:edgeNode];
        edgeY += tileHeight;
      }
      if (centerRectCroppedHeight > HLCenterRectEpsilon) {
        SKTexture *croppedEdgeTexture = [SKTexture textureWithRect:CGRectMake(0.0f, _centerRect.origin.y, _centerRect.origin.x, centerRectCroppedHeight) inTexture:_texture];
        SKSpriteNode *croppedEdgeNode = [SKSpriteNode spriteNodeWithTexture:croppedEdgeTexture];
        croppedEdgeNode.anchorPoint = CGPointMake(1.0f, 0.0f);
        croppedEdgeNode.position = CGPointMake(fillLeftX, edgeY);
        [self addChild:croppedEdgeNode];
      }
    }
    if (hasCenterRectBottom) {
      SKTexture *edgeTexture = [SKTexture textureWithRect:CGRectMake(_centerRect.origin.x, 0.0f, _centerRect.size.width, _centerRect.origin.y) inTexture:_texture];
      CGFloat edgeX = fillLeftX;
      for (NSInteger t = 0; t < fillWidthUncroppedTileCount; ++t) {
        SKSpriteNode *edgeNode = [SKSpriteNode spriteNodeWithTexture:edgeTexture];
        edgeNode.anchorPoint = CGPointMake(0.0f, 1.0f);
        edgeNode.position = CGPointMake(edgeX, fillBottomY);
        [self addChild:edgeNode];
        edgeX += tileWidth;
      }
      if (centerRectCroppedWidth > HLCenterRectEpsilon) {
        SKTexture *croppedEdgeTexture = [SKTexture textureWithRect:CGRectMake(_centerRect.origin.x, 0.0f, centerRectCroppedWidth, _centerRect.origin.y) inTexture:_texture];
        SKSpriteNode *croppedEdgeNode = [SKSpriteNode spriteNodeWithTexture:croppedEdgeTexture];
        croppedEdgeNode.anchorPoint = CGPointMake(0.0f, 1.0f);
        croppedEdgeNode.position = CGPointMake(edgeX, fillBottomY);
        [self addChild:croppedEdgeNode];
      }
    }
    if (hasCenterRectRight) {
      SKTexture *edgeTexture = [SKTexture textureWithRect:CGRectMake(centerRectRightX, _centerRect.origin.y, (1.0f - centerRectRightX), _centerRect.size.height) inTexture:_texture];
      CGFloat edgeX = fillLeftX + fillWidth;
      CGFloat edgeY = fillBottomY;
      for (NSInteger t = 0; t < fillHeightUncroppedTileCount; ++t) {
        SKSpriteNode *edgeNode = [SKSpriteNode spriteNodeWithTexture:edgeTexture];
        edgeNode.anchorPoint = CGPointMake(0.0f, 0.0f);
        edgeNode.position = CGPointMake(edgeX, edgeY);
        [self addChild:edgeNode];
        edgeY += tileHeight;
      }
      if (centerRectCroppedHeight > HLCenterRectEpsilon) {
        SKTexture *croppedEdgeTexture = [SKTexture textureWithRect:CGRectMake(centerRectRightX, _centerRect.origin.y, (1.0f - centerRectRightX), centerRectCroppedHeight) inTexture:_texture];
        SKSpriteNode *croppedEdgeNode = [SKSpriteNode spriteNodeWithTexture:croppedEdgeTexture];
        croppedEdgeNode.anchorPoint = CGPointMake(0.0f, 0.0f);
        croppedEdgeNode.position = CGPointMake(edgeX, edgeY);
        [self addChild:croppedEdgeNode];
      }
    }
    if (hasCenterRectTop) {
      SKTexture *edgeTexture = [SKTexture textureWithRect:CGRectMake(_centerRect.origin.x, centerRectTopY, _centerRect.size.width, (1.0f - centerRectTopY)) inTexture:_texture];
      CGFloat edgeX = fillLeftX;
      CGFloat edgeY = fillBottomY + fillHeight;
      for (NSInteger t = 0; t < fillWidthUncroppedTileCount; ++t) {
        SKSpriteNode *edgeNode = [SKSpriteNode spriteNodeWithTexture:edgeTexture];
        edgeNode.anchorPoint = CGPointMake(0.0f, 0.0f);
        edgeNode.position = CGPointMake(edgeX, edgeY);
        [self addChild:edgeNode];
        edgeX += tileWidth;
      }
      if (centerRectCroppedWidth > HLCenterRectEpsilon) {
        SKTexture *croppedEdgeTexture = [SKTexture textureWithRect:CGRectMake(_centerRect.origin.x, centerRectTopY, centerRectCroppedWidth, (1.0f - centerRectTopY)) inTexture:_texture];
        SKSpriteNode *croppedEdgeNode = [SKSpriteNode spriteNodeWithTexture:croppedEdgeTexture];
        croppedEdgeNode.anchorPoint = CGPointMake(0.0f, 0.0f);
        croppedEdgeNode.position = CGPointMake(edgeX, edgeY);
        [self addChild:croppedEdgeNode];
      }
    }
  }

  // Tiles
  SKTexture *tileTexture;
  if (hasCenterRect) {
    tileTexture = [SKTexture textureWithRect:_centerRect inTexture:_texture];
  } else {
    tileTexture = _texture;
  }
  for (NSInteger t = 0; t < fillHeightUncroppedTileCount; ++t) {
    CGFloat tileY = fillBottomY + t * tileHeight;
    for (NSInteger u = 0; u < fillWidthUncroppedTileCount; ++u) {
      SKSpriteNode *tileNode = [SKSpriteNode spriteNodeWithTexture:tileTexture];
      tileNode.anchorPoint = CGPointMake(0.0f, 0.0f);
      tileNode.position = CGPointMake(fillLeftX + u * tileWidth, tileY);
      [self addChild:tileNode];
    }
    if (centerRectCroppedWidth > HLCenterRectEpsilon) {
      SKTexture *croppedTileTexture = [SKTexture textureWithRect:CGRectMake(_centerRect.origin.x, _centerRect.origin.y, centerRectCroppedWidth, _centerRect.size.height) inTexture:_texture];
      SKSpriteNode *croppedTileNode = [SKSpriteNode spriteNodeWithTexture:croppedTileTexture];
      croppedTileNode.anchorPoint = CGPointMake(0.0f, 0.0f);
      croppedTileNode.position = CGPointMake(fillLeftX + fillWidthUncroppedTileCount * tileWidth, tileY);
      [self addChild:croppedTileNode];
    }
  }
  if (centerRectCroppedHeight > HLCenterRectEpsilon) {
    SKTexture *croppedTileTexture = [SKTexture textureWithRect:CGRectMake(_centerRect.origin.x, _centerRect.origin.y, _centerRect.size.width, centerRectCroppedHeight) inTexture:_texture];
    CGFloat tileY = fillBottomY + fillHeightUncroppedTileCount * tileHeight;
    for (NSInteger u = 0; u < fillWidthUncroppedTileCount; ++u) {
      SKSpriteNode *croppedTileNode = [SKSpriteNode spriteNodeWithTexture:croppedTileTexture];
      croppedTileNode.anchorPoint = CGPointMake(0.0f, 0.0f);
      croppedTileNode.position = CGPointMake(fillLeftX + u * tileWidth, tileY);
      [self addChild:croppedTileNode];
    }
    if (centerRectCroppedWidth > HLCenterRectEpsilon) {
      SKTexture *croppedCornerTileTexture = [SKTexture textureWithRect:CGRectMake(_centerRect.origin.x, _centerRect.origin.y, centerRectCroppedWidth, centerRectCroppedHeight) inTexture:_texture];
      SKSpriteNode *croppedCornerTileNode = [SKSpriteNode spriteNodeWithTexture:croppedCornerTileTexture];
      croppedCornerTileNode.anchorPoint = CGPointMake(0.0f, 0.0f);
      croppedCornerTileNode.position = CGPointMake(fillLeftX + fillWidthUncroppedTileCount * tileWidth, tileY);
      [self addChild:croppedCornerTileNode];
    }
  }
}

- (void)HL_updateTileNodePropertiesWithColor:(SKColor *)color
                            colorBlendFactor:(CGFloat)colorBlendFactor
                                   blendMode:(SKBlendMode)blendMode
{
  for (SKSpriteNode *child in self.children) {
    child.color = color;
    child.colorBlendFactor = colorBlendFactor;
    child.blendMode = blendMode;
  }
}

@end
