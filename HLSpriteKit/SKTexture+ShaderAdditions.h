//
//  SKTexture+ShaderAdditions.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 6/13/19.
//  Copyright © 2019 Hilo Games. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface SKTexture (ShaderAdditions)

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 90000

/**
 Calculates and returns the size of the source texture for this texture.

 When this texture is a sub-rectangle of a source texture, its `textureRect` defines
 the sub-rectangle in unit coordinate space.  The size returned by this method is a
 simple division of the `textureRect` by the texture `size`, but with one twist: A
 sub-texture of an atlas texture might be rotated (a quarter turn clockwise), and so
 the size dimensions might need to be swapped.

 This method is useful for OpenGL shaders using v_tex_coord on textures that are
 sub-rectangles of a source texture (especially atlas sprite sheets).
*/
- (vector_float2)sourceTextureSize;

/**
 Using `textureRect`, converts a point from (this) texture unit coordinate space to the
 unit coordinate space of the source texture.

 This method is useful for OpenGL shaders using v_tex_oord on textures that are
 sub-rectangles of a source texture (especially atlas sprite sheets).
*/
- (vector_float2)sourceTextureConvertPoint:(CGPoint)texturePoint;

#endif

@end

