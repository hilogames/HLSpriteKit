//
//  HLMessageNode.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 6/2/14.
//  Copyright (c) 2014 Hilo. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

#import "SKLabelNode+HLLabelNodeAdditions.h"

@interface HLMessageNode : SKSpriteNode

@property (nonatomic, assign) HLLabelNodeVerticalAlignmentMode verticalAlignmentMode;

@property (nonatomic, assign) NSTimeInterval messageAnimationDuration;

@property (nonatomic, assign) NSTimeInterval messageLingerDuration;

@property (nonatomic, copy) NSString *fontName;

@property (nonatomic, assign) CGFloat fontSize;

@property (nonatomic, strong) SKColor *fontColor;

- (void)showMessage:(NSString *)message parent:(SKNode *)parent;

@end
