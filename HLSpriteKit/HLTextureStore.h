//
//  HLTextureStore.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 12/12/13.
//  Copyright (c) 2013 Hilo Games. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SpriteKit/SpriteKit.h>

/**
 Stores textures and (sometimes) corresponding images by key for easy re-use.

 @bug This texture store supports both `UIImages` and `SKTextures`, so that the graphics
      can be used either as a texture (for `SpriteKit` purposes) or as a `UIImage` (for
      `CoreGraphics` purposes).  Maybe this is stupid.
*/
@interface HLTextureStore : NSObject

/// @name Creating an Texture Store

/**
 Returns the shared texture store for the process.
*/
+ (HLTextureStore *)sharedStore;

/**
 Initializes a texture store.
*/
- (instancetype)init NS_DESIGNATED_INITIALIZER;

/// @name Getting and Setting Textures (and Images)

/**
 Returns the texture from the store for the passed key, or `nil` if not found.
*/
- (SKTexture *)textureForKey:(NSString *)key;

/**
 Returns the image from the store for the passed key, or `nil` if not found.
*/
- (UIImage *)imageForKey:(NSString *)key;

/**
 Sets a texture and image in the store using an already-loaded image.

 Throws an exception if the texture cannot be created.  Returns the texture by reference
 for (optional) configuration.
*/
- (SKTexture *)setTextureWithImage:(UIImage *)image forKey:(NSString *)key filteringMode:(SKTextureFilteringMode)filteringMode;

/**
 Loads a texture (but not the image) by name, and sets it in the store.

 This version supports the use of texture atlases (because it calls `[SKTexture
 textureWithImageNamed]`), but it does not attempt to find or create a corresponding
 `UIImage`.  Throws an exception if the texture cannot be created.  Returns the texture by
 reference for (optional) configuration.
*/
- (SKTexture *)setTextureWithImageNamed:(NSString *)imageName forKey:(NSString *)key filteringMode:(SKTextureFilteringMode)filteringMode;

/**
 Loads a texture and image by name, and sets them in the store.

 The texture name and image name may be specified the same, in which case both will use a
 bundle image; if the texture should be loaded from a texture atlas, however, the names
 should be different.  (Documentation indicates that textures check first in the bundle,
 and second in texture atlases.)  Throws an exception if the texture or image cannot be
 created.  Returns the texture by reference for (optional) configuration.
*/
- (SKTexture *)setTextureWithImageNamed:(NSString *)textureImageName andUIImageWithImageNamed:(NSString *)imageImageName forKey:(NSString *)key filteringMode:(SKTextureFilteringMode)filteringMode;

@end
