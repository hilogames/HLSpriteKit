//
//  HLMessageNode.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 6/2/14.
//  Copyright (c) 2014 Hilo. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

#import "HLComponentNode.h"
#import "SKLabelNode+HLLabelNodeAdditions.h"

@interface HLMessageNode : HLComponentNode <NSCopying>

@property (nonatomic, assign) CGSize size;

@property (nonatomic, assign) HLLabelNodeVerticalAlignmentMode verticalAlignmentMode;

@property (nonatomic, assign) NSTimeInterval messageAnimationDuration;

@property (nonatomic, assign) NSTimeInterval messageLingerDuration;

@property (nonatomic, copy) NSString *messageSoundFile;

@property (nonatomic, copy) NSString *fontName;

@property (nonatomic, assign) CGFloat fontSize;

@property (nonatomic, strong) SKColor *fontColor;

- (instancetype)initWithColor:(SKColor *)color size:(CGSize)size NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithImageNamed:(NSString *)name NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithTexture:(SKTexture *)texture NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithTexture:(SKTexture *)texture color:(UIColor *)color size:(CGSize)size NS_DESIGNATED_INITIALIZER;

- (void)showMessage:(NSString *)message parent:(SKNode *)parent;

- (void)hideMessage;

@end
