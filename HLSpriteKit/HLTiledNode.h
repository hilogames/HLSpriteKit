//
//  HLTiledNode.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 10/8/14.
//  Copyright (c) 2014 Hilo Games. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

#import "HLComponentNode.h"

@interface HLTiledNode : HLComponentNode <NSCoding, NSCopying>

+ (instancetype)tiledNodeWithImageNamed:(NSString *)name size:(CGSize)size;

+ (instancetype)tiledNodeWithTexture:(SKTexture *)texture size:(CGSize)size;

+ (instancetype)tiledNodeWithTexture:(SKTexture *)texture color:(SKColor *)color size:(CGSize)size;

@property (nonatomic, assign) CGSize size;

@property (nonatomic, assign) CGPoint anchorPoint;

@property (nonatomic, strong) SKTexture *texture;

@property (nonatomic, assign) CGFloat colorBlendFactor;

@property (nonatomic, strong) SKColor *color;

@property (nonatomic, assign) SKBlendMode blendMode;

- (instancetype)initWithImageNamed:(NSString *)name size:(CGSize)size;

- (instancetype)initWithTexture:(SKTexture *)texture size:(CGSize)size;

// TODO: This will be NS_DESIGNATED_INITIALIZER (once compiler accepts initWithCoder).
- (instancetype)initWithTexture:(SKTexture *)texture color:(SKColor *)color size:(CGSize)size;

@end
