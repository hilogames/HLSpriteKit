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

typedef enum HLMenuSceneAnimation {
  HLMenuSceneAnimationNone,
  HLMenuSceneAnimationSlideLeft,
  HLMenuSceneAnimationSlideRight
} HLMenuSceneAnimation;

@interface HLMenuScene : SKScene <NSCoding, UIGestureRecognizerDelegate>

@property (nonatomic, weak) id<HLMenuSceneDelegate> delegate;

@property (nonatomic, strong) NSString *backgroundImageName;

@property (nonatomic, strong) HLMenu *menu;

@property (nonatomic, assign) CGFloat itemSpacing;

@property (nonatomic, strong) HLLabelButtonNode *itemButtonPrototype;

@property (nonatomic, assign) HLMenuSceneAnimation itemAnimation;

@property (nonatomic, copy) NSString *itemSoundFile;

@end

@interface HLMenuItem : NSObject <NSCoding>

@property (nonatomic, weak) HLMenuItem *parent;

@property (nonatomic, copy) NSString *text;

@property (nonatomic, strong) HLLabelButtonNode *buttonPrototype;

@property (nonatomic, copy) NSString *soundFile;

+ (HLMenuItem *)menuItemWithText:(NSString *)text;

- (id)initWithText:(NSString *)text;

- (NSString *)path;

@end

@interface HLMenu : HLMenuItem <NSCoding>

+ (HLMenu *)menuWithText:(NSString *)text items:(NSArray *)items;

- (id)initWithText:(NSString *)text items:(NSArray *)items;

- (void)addItem:(HLMenuItem *)item;

- (NSUInteger)itemCount;

- (HLMenuItem *)itemAtIndex:(NSUInteger)index;

@end

@protocol HLMenuSceneDelegate <NSObject>

@optional

- (BOOL)menuScene:(HLMenuScene *)menuScene shouldTapMenuItem:(HLMenuItem *)menuItem;

@required

- (void)menuScene:(HLMenuScene *)menuScene didTapMenuItem:(HLMenuItem *)menuItem;

@end
