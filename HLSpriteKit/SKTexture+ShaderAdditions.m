//
//  SKTexture+ShaderAdditions.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 6/13/19.
//  Copyright © 2019 Hilo Games. All rights reserved.
//

#import "SKTexture+ShaderAdditions.h"

@implementation SKTexture (ShaderAdditions)

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 90000

- (vector_float2)sourceTextureSize
{
  // note: It seems that even if this texture came from an atlas, it might not have the
  // _originalTexture property set.  But it does seem to have the _rootAtlas property
  // set, which allows for some lookup craziness.
  SKTexture *thisTexture = [[self valueForKey:@"_rootAtlas"] textureNamed:[self valueForKey:@"_subTextureName"]];
  SKTexture *sourceTexture = [thisTexture valueForKey:@"_originalTexture"];
  assert(sourceTexture);
  return simd_make_float2((float)sourceTexture.size.width, (float)sourceTexture.size.height);

  // note: This approach doesn't work because self.size is the nominal texture size, not
  // necessarily the size of the textureRect clipped from the source texture (which has
  // transparency trimmed off).  Also, it does not account for _isFlipped.
  //  if (![[self valueForKey:@"_isRotated"] boolValue]) {
  //    return simd_make_float2((float)(self.size.width / self.textureRect.size.width),
  //                            (float)(self.size.height / self.textureRect.size.height));
  //  } else {
  //    return simd_make_float2((float)(self.size.height / self.textureRect.size.width),
  //                            (float)(self.size.width / self.textureRect.size.height));
  //  }
}

- (vector_float2)sourceTextureApproximatelyConvertPoint:(CGPoint)texturePoint
{
  // note: See notes in header.  We can't guarantee that the `textureRect` into the source
  // texture represents the full size of the texture (from the caller's point of view).
  // But it's probably reasonably close.

  if ([[self valueForKey:@"_isRotated"] boolValue]) {
    // note: Textures are rotated in their source texture one quarter turn clockwise.  The
    // .textureRect stays within the coordinate system of the source texture, but the
    // caller's idea of the texture will have x and y rotated.
    CGFloat temp = texturePoint.x;
    texturePoint.x = texturePoint.y;
    texturePoint.y = (CGFloat)(1.0 - temp);
  }
  // note: The _isFlipped usage is unknown.  But let's guess.
  if ([[self valueForKey:@"_isFlipped"] boolValue]) {
    texturePoint.x = (CGFloat)(1.0 - texturePoint.x);
    texturePoint.y = (CGFloat)(1.0 - texturePoint.y);
  }
  return simd_make_float2((float)(self.textureRect.origin.x + texturePoint.x * self.textureRect.size.width),
                          (float)(self.textureRect.origin.y + texturePoint.y * self.textureRect.size.height));
}

#endif

@end
