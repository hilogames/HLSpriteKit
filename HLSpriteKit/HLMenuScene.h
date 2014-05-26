//
//  HLMenuScene.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 5/1/14.
//  Copyright (c) 2014 Hilo. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

/**
 * HLMenuScene has an HLMenu, and it creates and displays label buttons for
 * each item in the HLMenu, stacked vertically.  Menus are hierarchical in
 * nature, and the scene provides functionality for navigating between menus
 * and submenus.
 */

@class HLLabelButtonNode;
@class HLMenuItem;
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

- (void)navigateToMenu:(HLMenu *)menu animation:(HLMenuSceneAnimation)animation;

@end

@protocol HLMenuSceneDelegate <NSObject>

@optional

- (BOOL)menuScene:(HLMenuScene *)menuScene shouldTapMenuItem:(HLMenuItem *)menuItem;

@required

- (void)menuScene:(HLMenuScene *)menuScene didTapMenuItem:(HLMenuItem *)menuItem;

@end

/**
 * An HLMenuItem is a single item in an HLMenu.
 */

@interface HLMenuItem : NSObject <NSCoding>

@property (nonatomic, weak) HLMenu *parent;

@property (nonatomic, copy) NSString *text;

@property (nonatomic, strong) HLLabelButtonNode *buttonPrototype;

@property (nonatomic, copy) NSString *soundFile;

+ (HLMenuItem *)menuItemWithText:(NSString *)text;

- (id)initWithText:(NSString *)text;

- (NSString *)path;

@end

/**
 * An HLMenu is a kind of menu item which can itself contain menu items.
 */

@interface HLMenu : HLMenuItem <NSCoding>

+ (HLMenu *)menuWithText:(NSString *)text items:(NSArray *)items;

- (id)initWithText:(NSString *)text items:(NSArray *)items;

- (void)addItem:(HLMenuItem *)item;

- (NSUInteger)itemCount;

- (HLMenuItem *)itemAtIndex:(NSUInteger)index;

- (HLMenuItem *)itemForPathComponents:(NSArray *)pathComponents;

@end

/**
 * An HLMenuBackItem is a kind of menu item which, when tapped,
 * navigates the menu scene to the parent of its parent menu.
 */

@interface HLMenuBackItem : HLMenuItem <NSCoding>

@end
