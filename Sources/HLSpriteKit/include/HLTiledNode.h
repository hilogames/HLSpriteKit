//
//  HLTiledNode.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 10/8/14.
//  Copyright (c) 2014 Hilo Games. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

/**
 The size mode for the tiled node: the way that the tiled node attempts to fit or fill
 its configured size.
*/
typedef NS_ENUM(NSInteger, HLTiledNodeSizeMode) {
  /**
   The node will tile the texture to fit the configured size exactly, cropping as
   necessary.
  */
  HLTiledNodeSizeModeCrop,
  /**
   The node will use a whole number of tiles in both dimensions, as small as possible but
   at least the minimum size.
  */
  HLTiledNodeSizeModeWholeMinimum,
  /**
   The node will use a whole number of tiles in both dimensions, as large as possible but
   at most the maximum size.
  */
  HLTiledNodeSizeModeWholeMaximum,
};

/**
 `HLTiledNode` behaves like an `SKSpriteNode` that tiles its texture to a specified size.

 The tiled node automatically adds a single node child (which is a hierarchy of sprite
 nodes textured as tiles).  This can cause surprising results for an owner accustomed to
 controlling all children of a node.
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
 Returns an initialized tiled node.

 This method avoids repeated layouts caused by setting properties individually.
*/
+ (instancetype)tiledNodeWithTexture:(SKTexture *)texture
                                size:(CGSize)size
                            sizeMode:(HLTiledNodeSizeMode)sizeMode
                         anchorPoint:(CGPoint)anchorPoint
                          centerRect:(CGRect)centerRect;

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

/**
 Initializes a new tiled node with all layout-affecting parameters.

 This method avoids repeated layouts caused by setting properties individually.

 @param texture The texture to be tiled.

 @param size The size of the overall tiled node.

 @param sizeMode The size mode; see `HLTiledNodeSizeMode` for details.

 @param anchorPoint The anchor point of the tiled node.

 @param centerRect A property that defines how the texture is tiled in the tiled node;
                   see `centerRect` for details.
*/
- (instancetype)initWithTexture:(SKTexture *)texture
                           size:(CGSize)size
                       sizeMode:(HLTiledNodeSizeMode)sizeMode
                    anchorPoint:(CGPoint)anchorPoint
                     centerRect:(CGRect)centerRect;

/// @name Configuring a Tiled Node

/**
 The size of the overall tiled node.
*/
@property (nonatomic, assign) CGSize size;

/**
 The size mode of the tiled node.

 See `HLTiledNodeSizeMode` for details.

 Default value is `HLTiledNodeSizeModeCrop`.
*/
@property (nonatomic, assign) HLTiledNodeSizeMode sizeMode;

/**
 The anchor point of the tiled node.
*/
@property (nonatomic, assign) CGPoint anchorPoint;

/**
 The texture used for the tiles of the tiled node.
*/
@property (nonatomic, strong) SKTexture *texture;

/**
 A property that defines how the texture is tiled in the tiled node.

 The rectangle is in the unit coordinate space.  The default value is `(0,0)-(1.0,1.0)`,
 which indicates that the entire texture is tiled to fill the tiled node.  If a different
 rectangle is specified, the rectangle's coordinates are used to break the texture into a
 3 x 3 grid.  The four corners of this grid are positioned at the corresponding corners of
 the tiled node.  The four edges of this grid are tiled along the edges of the tiled node,
 and the center of the grid is tiled in the middle of the tiled node.
*/
@property (nonatomic, assign) CGRect centerRect;

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
