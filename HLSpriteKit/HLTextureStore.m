//
//  HLTextureStore.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 12/12/13.
//  Copyright (c) 2013 Hilo. All rights reserved.
//

#import "HLTextureStore.h"

@implementation HLTextureStore
{
  NSDictionary *_textures;
  NSDictionary *_images;
}

+ (HLTextureStore *)sharedStore
{
  static HLTextureStore *sharedStore = nil;
  if (!sharedStore) {
    sharedStore = [[HLTextureStore alloc] init];
  }
  return sharedStore;
}

- (id)init
{
  self = [super init];
  if (self) {
    _textures = [[NSMutableDictionary alloc] init];
    _images = [[NSMutableDictionary alloc] init];
  }
  return self;
}

- (SKTexture *)textureForKey:(NSString *)key
{
  return [_textures objectForKey:key];
}

- (UIImage *)imageForKey:(NSString *)key
{
  UIImage *image = [_images objectForKey:key];
  if (!image) {
    [NSException raise:@"HLTextureStoreImageNotFound"
                format:@"Could not find image with key '%@'.  (If the image is part of a texture atlas, it must also be included as a resource in the application bundle with the suffix '-nonatlas'.)", key];
  }
  return [_images objectForKey:key];
}

- (void)setTextureWithImage:(UIImage *)image forKey:(NSString *)key filteringMode:(SKTextureFilteringMode)filteringMode
{
  SKTexture *texture = [SKTexture textureWithImage:image];
  if (!texture) {
    [NSException raise:@"HLTextureStoreTextureFailed" format:@"Could not create texture with passed image for key '%@'.", key];
  }
  texture.filteringMode = filteringMode;
  [_textures setValue:texture forKey:key];
  [_images setValue:image forKey:key];
}

- (void)setTextureWithImageNamed:(NSString *)imageName forKey:(NSString *)key filteringMode:(SKTextureFilteringMode)filteringMode
{
  SKTexture *texture = [SKTexture textureWithImageNamed:imageName];
  if (!texture) {
    [NSException raise:@"HLTextureStoreTextureNotFound" format:@"Could not find texture with image name '%@' for key '%@'.", imageName, key];
  }
  texture.filteringMode = filteringMode;
  [_textures setValue:texture forKey:key];
  [_images setValue:nil forKey:key];
}

- (void)setTextureWithImageNamed:(NSString *)textureImageName andUIImageWithImageNamed:(NSString *)imageImageName forKey:(NSString *)key filteringMode:(SKTextureFilteringMode)filteringMode
{
  // note: If the texture and image name are the same, the documentation indicates that the texture
  // will be created using the bundle image rather than any available texture atlases.
  SKTexture *texture = [SKTexture textureWithImageNamed:textureImageName];
  if (!texture) {
    [NSException raise:@"HLTextureStoreTextureNotFound" format:@"Could not find texture with image name '%@' for key '%@'.", textureImageName, key];
  }
  UIImage *image = [UIImage imageNamed:imageImageName];
  if (!image) {
    [NSException raise:@"HLTextureStoreImageNotFound" format:@"Could not find image with image name '%@' for key '%@'.", imageImageName, key];
  }
  texture.filteringMode = filteringMode;
  [_textures setValue:texture forKey:key];
  [_images setValue:image forKey:key];
}

@end

