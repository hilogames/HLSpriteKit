//
//  HLMessageNode.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 6/2/14.
//  Copyright (c) 2014 Hilo. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

#import "SKLabelNode+HLLabelNodeAdditions.h"

@interface HLMessageNode : SKNode

@property (nonatomic, assign) CGSize size;

@property (nonatomic, assign) HLLabelNodeVerticalAlignmentMode verticalAlignmentMode;

@property (nonatomic, assign) NSTimeInterval messageAnimationDuration;

@property (nonatomic, assign) NSTimeInterval messageLingerDuration;

@property (nonatomic, copy) NSString *fontName;

@property (nonatomic, assign) CGFloat fontSize;

@property (nonatomic, strong) SKColor *fontColor;

- (id)initWithColor:(UIColor *)color size:(CGSize)size;

- (id)initWithImageNamed:(NSString *)name;

- (id)initWithTexture:(SKTexture *)texture;

- (id)initWithTexture:(SKTexture *)texture color:(UIColor *)color size:(CGSize)size;

- (void)showMessage:(NSString *)message parent:(SKNode *)parent;

- (void)hideMessage;

@end
