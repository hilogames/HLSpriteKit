//
//  HLMenuNode.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 5/1/14.
//  Copyright (c) 2014 Hilo. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

#import "HLComponentNode.h"
#import "HLGestureTarget.h"

/**
 * HLMenuNode has an HLMenu, and it creates and displays label buttons for
 * each item in the HLMenu, stacked vertically.  Menus are hierarchical in
 * nature, and the scene provides functionality for navigating between menus
 * and submenus.
 */

@class HLLabelButtonNode;
@class HLMenuItem;
@class HLMenu;
@protocol HLMenuNodeDelegate;

typedef enum HLMenuNodeAnimation {
  HLMenuNodeAnimationNone,
  HLMenuNodeAnimationSlideLeft,
  HLMenuNodeAnimationSlideRight
} HLMenuNodeAnimation;

@interface HLMenuNode : HLComponentNode <NSCoding, HLGestureTarget>

/**
 * Common gesture handling configurations:
 *
 *   - Set this node as its own gesture target (via SKNode+HLGestureTarget's
 *     hlSetGestureTarget) to get a callbacks via the HLMenuNodeDelegate interface.
 */

@property (nonatomic, weak) id <HLMenuNodeDelegate> delegate;

/**
 * The hierarchical menu displayed by the menu node.
 *
 * note: For the sake of simplicity, menu node does not worry about updating its
 * display when the caller makes changes to the individual menu items.  Instead,
 * it will only refresh the display after a call to setMenu:animation:.  The readonly
 * attribute helps to suggest this pattern.  More stringent would be to copy the
 * menu into the menu node, but that is deemed unnecessary.
 *
 * note: It is considered convenient for the menu node to keep a strong reference
 * to its menu, assuming that the caller typically wants a single fairly-static
 * menu hierarchy.  An alternate design, perhaps where only "current" menu is tracked,
 * should be considered if useful.
 */
@property (nonatomic, readonly, strong) HLMenu *menu;

@property (nonatomic, assign) CGFloat itemSpacing;

/**
 * Basic prototype button that will be copied for each item in the menu hierarchy,
 * unless more-specific prototypes are provided.  In particular, a prototype for
 * an item is found in the following order, from most-specific to least-specific:
 *
 *  . The HLMenuItem's buttonPrototype property, if set;
 *
 *  . otherwise, the HLMenuNode's menuItemButtonPrototype for HLMenuItems,
 *    if set, and the HLMenuNode's backItemButtonPrototype for HLMenuBackItems,
 *    if set;
 *
 *  . otherwise, the HLMenuNode's itemButtonPrototype.
 *
 * All buttons in the menu hierarchy must have a button prototype, or an exception
 * is raised at runtime.  Setting this property (itemButtonPrototype) is the easiest
 * way to ensure prototypes for all items.
 */
@property (nonatomic, strong) HLLabelButtonNode *itemButtonPrototype;

@property (nonatomic, strong) HLLabelButtonNode *menuItemButtonPrototype;

@property (nonatomic, strong) HLLabelButtonNode *backItemButtonPrototype;

@property (nonatomic, assign) HLMenuNodeAnimation itemAnimation;

@property (nonatomic, assign) NSTimeInterval itemAnimationDuration;

@property (nonatomic, copy) NSString *itemSoundFile;

- (void)setMenu:(HLMenu *)menu animation:(HLMenuNodeAnimation)animation;

- (void)navigateToTopMenuAnimation:(HLMenuNodeAnimation)animation;

- (void)navigateToSubmenuWithPathComponents:(NSArray *)pathComponents animation:(HLMenuNodeAnimation)animation;

@end

@protocol HLMenuNodeDelegate <NSObject>

@optional

- (BOOL)menuNode:(HLMenuNode *)menuNode shouldTapMenuItem:(HLMenuItem *)menuItem itemIndex:(NSUInteger)itemIndex;

@required

- (void)menuNode:(HLMenuNode *)menuNode didTapMenuItem:(HLMenuItem *)menuItem itemIndex:(NSUInteger)itemIndex;

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

- (instancetype)initWithText:(NSString *)text NS_DESIGNATED_INITIALIZER;

// TODO: This is declared for the sake of the NS_DESIGNATED_INITIALIZER; I expected
// a superclass to do this for me.  Give it some time and then try to remove this
// declaration.
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;

- (NSArray *)pathComponents;

@end

/**
 * An HLMenu is a kind of menu item which can itself contain menu items.
 */

@interface HLMenu : HLMenuItem <NSCoding>

+ (HLMenu *)menuWithText:(NSString *)text items:(NSArray *)items;

- (instancetype)initWithText:(NSString *)text items:(NSArray *)items NS_DESIGNATED_INITIALIZER;

// TODO: This is declared for the sake of the NS_DESIGNATED_INITIALIZER; I expected
// a superclass to do this for me.  Give it some time and then try to remove this
// declaration.
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;

- (void)addItem:(HLMenuItem *)item;

- (NSUInteger)itemCount;

- (HLMenuItem *)itemAtIndex:(NSUInteger)index;

- (HLMenuItem *)itemForPathComponents:(NSArray *)pathComponents;

- (void)removeAllItems;

@end

/**
 * An HLMenuBackItem is a kind of menu item which, when tapped,
 * navigates the menu scene to the parent of its parent menu.
 */

@interface HLMenuBackItem : HLMenuItem <NSCoding>

@end
