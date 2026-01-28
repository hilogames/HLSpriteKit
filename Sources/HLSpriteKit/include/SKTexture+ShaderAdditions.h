//
//  SKTexture+ShaderAdditions.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 6/13/19.
//  Copyright © 2019 Hilo Games. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface SKTexture (ShaderAdditions)

// note: Need iOS9 for vector types.  This conditional compilation, though, is
// problematic.  It's common to include these definitions in a main target that has its
// deployment target set higher than iOS9, but then fail to link (at runtime) because this
// module compiles with a deployment target set lower than iOS9.  To fix the linking
// error, set the HLSpriteKit deployment target to 9.0 or higher.
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 90000

/**
 Calculates and returns the size of the source texture for this texture, in points.

 This method is useful for OpenGL shaders using v_tex_coord on textures that are
 sub-rectangles of a source texture (especially atlas sprite sheets).
*/
- (vector_float2)sourceTextureSize;

/**
 Using `textureRect`, converts a point from (this) texture unit coordinate space to the
 unit coordinate space of the source texture.

 But we don't actually have all the information we need to do that, when the texture is a
 subtexture from an atlas sprite sheet.  We can only just get somewhat close.  The caller
 is providing a `texturePoint` in terms of her full-size texture -- if she provides `(0.5,
 0.5)`, for instance, she expects the point in the source texture that corresponds to the
 center of her texture.  But the `textureRect` into the sprite sheet doesn't necessarily
 include the full size of her sprite: it's the trimmed portion that got packed into the
 sheet, without any transparent pixels on the edges.  So the `(0.5, 0.5)` into the
 full-size texture may or may not be the same as `(0.5, 0.5)` into the trimmed portion of
 the texture.

 This method is useful for OpenGL shaders using v_tex_coord on textures that are
 sub-rectangles of a source texture (especially atlas sprite sheets).
*/
- (vector_float2)sourceTextureApproximatelyConvertPoint:(CGPoint)texturePoint;

#endif

@end

