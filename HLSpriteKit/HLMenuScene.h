//
//  HLMenuScene.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 5/1/14.
//  Copyright (c) 2014 Hilo. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@class HLLabelButtonNode;
@class HLMenu;
@protocol HLMenuSceneDelegate;

@interface HLMenuScene : SKScene <NSCoding, UIGestureRecognizerDelegate>

@property (nonatomic, weak) id<HLMenuSceneDelegate> delegate;

@property (nonatomic, strong) NSString *backgroundImageName;

@property (nonatomic, strong) HLMenu *menu;

@property (nonatomic, assign) CGFloat itemSpacing;

@property (nonatomic, strong) HLLabelButtonNode *buttonPrototype;

@end

@interface HLMenuItem : NSObject <NSCoding>

@property (nonatomic, copy) NSString *text;

@property (nonatomic, strong) HLLabelButtonNode *buttonPrototype;

- (id)initWithText:(NSString *)text;

@end

@interface HLMenu : HLMenuItem <NSCoding>

- (void)addItem:(HLMenuItem *)item;

- (NSUInteger)itemCount;

- (HLMenuItem *)itemAtIndex:(NSUInteger)index;

@end

@protocol HLMenuSceneDelegate <NSObject>

- (void)menuScene:(HLMenuScene *)menuScene didTapMenuItem:(HLMenuItem *)menuItem;

@end
