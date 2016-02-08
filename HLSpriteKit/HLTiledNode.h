//
//  HLTiledNode.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 10/8/14.
//  Copyright (c) 2014 Hilo Games. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

/**
 `HLTiledNode` behaves like an `SKSpriteNode` that tiles its texture to a specified size.
*/
@interface HLTiledNode : SKNode <NSCoding, NSCopying>

/// @name Creating a Tiled Node

/**
 Returns an initialized tiled node.
*/
+ (instancetype)tiledNodeWithImageNamed:(NSString *)name size:(CGSize)size;

/**
 Returns an initialized tiled node.
*/
+ (instancetype)tiledNodeWithTexture:(SKTexture *)texture size:(CGSize)size;

/**
 Returns an initialized tiled node.
*/
+ (instancetype)tiledNodeWithTexture:(SKTexture *)texture color:(SKColor *)color size:(CGSize)size;

/**
 Initializes a new tiled node with a named image to be tiled.

 @param name The name of the image to be tiled.

 @param size The size of the overall tiled node.
*/
- (instancetype)initWithImageNamed:(NSString *)name size:(CGSize)size;

/**
 Initializes a new tiled node with a texture to be tiled.

 @param texture The texture to be tiled.

 @param size The size of the overall tiled node.
*/
- (instancetype)initWithTexture:(SKTexture *)texture size:(CGSize)size;

/**
 Initializes a new tiled node.

 The parameters are chosen to match the designated initializer for `SKSpriteNode`, and, as
 in that method, `texture` may be passed `nil`.  However, for an `HLTiledNode`, passing a
 `nil` texture would not make much sense.

 @param texture The texture that will be tiled.

 @param color The color for the individual tiles.

 @param size The size of the overall tiled node.
*/
- (instancetype)initWithTexture:(SKTexture *)texture color:(SKColor *)color size:(CGSize)size;

/// @name Configuring a Tiled Node

/**
 The size of the overall tiled node.
*/
@property (nonatomic, assign) CGSize size;

/**
 The anchor point of the tiled node.
*/
@property (nonatomic, assign) CGPoint anchorPoint;

/**
 The texture used for the tiles of the tiled node.
*/
@property (nonatomic, strong) SKTexture *texture;

/**
 The color blend factor used for the tiles of the tiled node.
*/
@property (nonatomic, assign) CGFloat colorBlendFactor;

/**
 The color of the tiles of the tiled node.
*/
@property (nonatomic, strong) SKColor *color;

/**
 The blend mode of the tiles of the tiled node.
*/
@property (nonatomic, assign) SKBlendMode blendMode;

@end
