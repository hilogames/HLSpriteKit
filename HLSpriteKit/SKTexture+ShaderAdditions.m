//
//  SKTexture+ShaderAdditions.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 6/13/19.
//  Copyright © 2019 Hilo Games. All rights reserved.
//

#import "SKTexture+ShaderAdditions.h"

@interface SKTexture ()
@property (nonatomic, assign) BOOL isRotated;
@end

@implementation SKTexture (ShaderAdditions)

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 90000

- (vector_float2)sourceTextureSize
{
  if (!self.isRotated) {
    return simd_make_float2((float)(self.size.width / self.textureRect.size.width),
                            (float)(self.size.height / self.textureRect.size.height));
  } else {
    return simd_make_float2((float)(self.size.height / self.textureRect.size.width),
                            (float)(self.size.width / self.textureRect.size.height));
  }
}

- (vector_float2)sourceTextureConvertPoint:(CGPoint)texturePoint
{
  if (!self.isRotated) {
    return simd_make_float2((float)(self.textureRect.origin.x + texturePoint.x * self.textureRect.size.width),
                            (float)(self.textureRect.origin.y + texturePoint.y * self.textureRect.size.height));
  } else {
    // note: Textures are rotated in their source texture one quarter turn clockwise.
    // The .textureRect stays within the coordinate system of the source texture, but
    // the subtexture .size will have x and y rotated.
    return simd_make_float2((float)(self.textureRect.origin.x + texturePoint.y * self.textureRect.size.width),
                            (float)(self.textureRect.origin.y + (1.0 - texturePoint.x) * self.textureRect.size.height));
  }
}

#endif

@end
