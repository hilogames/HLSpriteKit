//
//  HLEmitterStore.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 5/20/14.
//  Copyright (c) 2014 Hilo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SpriteKit/SpriteKit.h>

/**
 * Stores SKEmitterNode objects for easy re-use.
 */

@interface HLEmitterStore : NSObject

+ (HLEmitterStore *)sharedStore;

/**
 * Returns a copy of the stored emitter for the passed key, or nil if not found.
 */
- (SKEmitterNode *)emitterCopyForKey:(NSString *)key;

/**
 * Sets the passed emitter in the store with the passed key.
 */
- (void)setEmitter:(SKEmitterNode *)emitterNode forKey:(NSString *)key;

/**
 * Loads the resource of the given name (with assumed resource type "sks") from
 * the bundle as an emitter node and sets it in the store for the passed key.
 * Returns the emitter node (by reference) for optional configuration by the
 * caller.  Throws an exception if the emitter cannot be loaded.
 */
- (SKEmitterNode *)setEmitterWithResource:(NSString *)name forKey:(NSString *)key;

@end
