//
//  HLEmitterStore.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 5/20/14.
//  Copyright (c) 2014 Hilo Games. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SpriteKit/SpriteKit.h>

/**
 An `HLEmitterStore` stores `SKEmitterNode` objects for easy reuse and instantiation.
*/

@interface HLEmitterStore : NSObject

/// @name Creating an Emitter Store

/**
 Returns the shared emitter store for the process.
*/
+ (HLEmitterStore *)sharedStore;

/**
 Initializes an emitter store.
*/
- (instancetype)init NS_DESIGNATED_INITIALIZER;

/// @name Getting and Setting Emitter Nodes

/**
 Returns a copy of the stored emitter for the passed key, or `nil` if not found.
*/
- (SKEmitterNode *)emitterCopyForKey:(NSString *)key;

/**
 Returns the stored emitter for the passed key, or `nil` if not found.

 @warning Modifying the returned emitter will affect all future copies from this store.
 Typically an emitter node is copied before it is used.  See `emitterCopyForKey:`
*/
- (SKEmitterNode *)emitterForKey:(NSString *)key;

/**
 Sets the passed emitter in the store with the passed key.
*/
- (void)setEmitter:(SKEmitterNode *)emitterNode forKey:(NSString *)key;

/**
 Loads the resource of the given name and sets it in the store with the passed key.

 The resource is loaded (with assumed resource type `sks`) from the bundle as an emitter
 node.  Returns the emitter node (by reference) for optional configuration by the caller.
 Throws an exception if the emitter cannot be loaded.
*/
- (SKEmitterNode *)setEmitterWithResource:(NSString *)name forKey:(NSString *)key;

/**
 Removes all emitters from the store.
*/
- (void)removeAll;

@end
