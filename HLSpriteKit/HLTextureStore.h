//
//  HLTextureStore.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 12/12/13.
//  Copyright (c) 2013 Hilo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SpriteKit/SpriteKit.h>

/**
 * Stores textures and (sometimes) corresponding images by key for easy re-use.
 *
 * noob: This texture store supports both UIImages and SKTextures, so that the graphics
 * can be used either as a texture (for SpriteKit purposes) or as a UIImage (for CoreGraphics
 * purposes).  Maybe this is stupid.
 */

@interface HLTextureStore : NSObject

+ (HLTextureStore *)sharedStore;

- (SKTexture *)textureForKey:(NSString *)key;

- (UIImage *)imageForKey:(NSString *)key;

/**
 * Sets an already-loaded texture and image in the store.  Throws an exception if the
 * texture cannot be created.
 */
- (void)setTextureWithImage:(UIImage *)image forKey:(NSString *)key filteringMode:(SKTextureFilteringMode)filteringMode;

/**
 * Loads a texture (but not the image) by name, and sets it in the store.  This version
 * supports the use of texture atlases (because it calls SKTexture's textureWithImageNamed
 * method), but it does not attempt to find or create a corresponding UIImage.  Throws an
 * exception if the texture cannot be created.
 */
- (void)setTextureWithImageNamed:(NSString *)imageName forKey:(NSString *)key filteringMode:(SKTextureFilteringMode)filteringMode;

/**
 * Loads a texture and image by name, and sets them in the store.  The texture name and
 * image name may be specified the same, in which case both will use a bundle image; if
 * the texture should be loaded from a texture atlas, however, the names should be different.
 * (Documentation indicates that textures check first in the bundle, and second in texture
 * atlases.)  Throws an exception if the texture or image cannot be created.
 */
- (void)setTextureWithImageNamed:(NSString *)textureImageName andUIImageWithImageNamed:(NSString *)imageImageName forKey:(NSString *)key filteringMode:(SKTextureFilteringMode)filteringMode;

@end
