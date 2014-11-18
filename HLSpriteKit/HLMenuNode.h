//
//  HLMenuNode.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 5/1/14.
//  Copyright (c) 2014 Hilo Games. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

#import "HLComponentNode.h"
#import "HLGestureTarget.h"

@class HLLabelButtonNode;
@class HLMenuItem;
@class HLMenu;
@protocol HLMenuNodeDelegate;

/**
 The type of animation to be used when animating navigation between menus in an
 `HLMenuNode`.
 */
typedef NS_ENUM(NSInteger, HLMenuNodeAnimation) {
  /**
   No animation when navigating between menus.
   */
  HLMenuNodeAnimationNone,
  /**
   When navigating to a submenu, the parent menu slides off to the left, and the submenu
   slides in from the right side of the scene.  When navigating to a parent menu,
   everything slides the other direction.
   */
  HLMenuNodeAnimationSlideLeft,
  /**
   When navigating to a submenu, the parent menu slides off to the right, and the
   submenu slides in from the left side of the scene.  When navigating to a parent menu,
   everything slides the other direction.
   */
  HLMenuNodeAnimationSlideRight,
};

/**
 `HLMenuNode` has an `HLMenu`, and it creates and displays `HLLabelButtonNode`s for each
 item in the `HLMenu`, stacked vertically.  Menus are hierarchical in nature, and the
 node provides functionality for navigating between menus and submenus.

 ## Common Gesture Handling Configurations

 - Set this node as its own gesture target (via `[SKNode+HLGestureTarget
   hlSetGestureTarget]`) to get a callbacks via the `HLMenuNodeDelegate` interface.
 */
@interface HLMenuNode : HLComponentNode <NSCoding, HLGestureTarget>

/// @name Creating a Menu Node

/**
 Initializes a new menu node.
 */
- (instancetype)init;

/// @name Setting the Delegate

/**
 The delegate that will respond to menu interaction.

 See `HLMenuNodeDelegate`.
 */
@property (nonatomic, weak) id <HLMenuNodeDelegate> delegate;

/// @name Getting and Setting Menu Content

/**
 The hierarchical menu displayed by the menu node (readonly).

 For the sake of simplicity, menu node does not worry about updating its display when
 the caller makes changes to the individual menu items.  Instead, it will only refresh
 the display after a call to `setMenu:animation:`.  The readonly attribute helps to
 suggest this pattern.  More stringent would be to copy the menu into the menu node, but
 that is deemed unnecessary.

 @bug It is considered convenient for the menu node to keep a strong reference to its
      menu, assuming that the caller typically wants a single fairly-static menu
      hierarchy.  An alternate design, perhaps where only "current" menu is tracked,
      should be considered if useful.
 */
@property (nonatomic, readonly, strong) HLMenu *menu;

/**
 Sets the hierarchical menu that the menu node will navigate.
 */
- (void)setMenu:(HLMenu *)menu animation:(HLMenuNodeAnimation)animation;

/// @name Configuring Menu Item Buttons

/**
 The distance between the vertical position of each button in the menu node.

 This is the distance between the *positions* of the buttons, and not the distance between
 button bounds (which would be affected by button sizes).
 */
@property (nonatomic, assign) CGFloat itemSpacing;

/**
 Default prototype button for items in the menu.

 This prototype is used if no other more-specific prototype is specified.  In particular,
 a prototype for an item is found in the following order, from most-specific to
 least-specific:

 - The `[HLMenuItem buttonPrototype]` property, if set;

 - otherwise, the `[HLMenuNode menuItemButtonPrototype]` for `HLMenu`s, if set, and the
   `[HLMenuNode backItemButtonPrototype]` for `HLMenuBackItem`s, if set;

 - otherwise, this `[HLMenuNode itemButtonPrototype]`.

 All buttons in the menu hierarchy must have a button prototype, or an exception is
 raised at runtime.  Setting this property (`itemButtonPrototype`) is the easiest way to
 ensure prototypes for all items.
 */
@property (nonatomic, strong) HLLabelButtonNode *itemButtonPrototype;

/**
 Default prototype button for submenu items in the menu.

 See `itemButtonPrototype` for notes about prototype buttons.
 */
@property (nonatomic, strong) HLLabelButtonNode *menuItemButtonPrototype;

/**
 Default prototype button for back items in the menu.

 See `itemButtonPrototype` for notes about prototype buttons.
 */
@property (nonatomic, strong) HLLabelButtonNode *backItemButtonPrototype;

/**
 The animation used for navigation between menus.

 This animation applies when navigation is triggered by taps on submenu and back buttons.
 */
@property (nonatomic, assign) HLMenuNodeAnimation itemAnimation;

/**
 The duration of the animation used for navigation between menus.

 This animation duration applies when navigation is triggered by taps on submenu and back
 buttons.
 */
@property (nonatomic, assign) NSTimeInterval itemAnimationDuration;

/**
 Default sound file for playing when an item is tapped, or `nil` for none.

 This sound file is used if no other more-specific sound file is specified.  In
 particular, a sound file for an item is found in the following order, from most-specific
 to least-specific:

 - The `[HLMenuItem soundFile]` property, if set;

 - otherwise, this `[HLMenuNode itemSoundFile]`.

 Sound files are not required.
 */
@property (nonatomic, copy) NSString *itemSoundFile;

/// @name Navigating Between Menus

/**
 Navigate to the top menu.
 */
- (void)navigateToTopMenuAnimation:(HLMenuNodeAnimation)animation;

/**
 Navigate to a submenu in the menu hierarchy.

 See `[HLMenuItem path]` for details on specifying path.
 */
- (void)navigateToSubmenuWithPath:(NSArray *)path animation:(HLMenuNodeAnimation)animation;

@end

/**
 A delegate for `HLMenuNode`.

 The delegate is (currently) concerned mostly with handling user interaction.  It's
 worth noting that the `HLMenuNode` only receives gestures if it is configured as its
 own gesture target (using `[SKNode+HLGestureTarget hlSetGestureTarget]`).
 */
@protocol HLMenuNodeDelegate <NSObject>

/// @name Handling User Interaction

/**
 Called when the user taps on a menu item, but before the menu node has taken any
 navigation actions that would normally result from the tap.

 A return value of `YES` indicates the menu node should continue to navigation.

 The sound file associated with the item will play **before** this delegate method is
 called.
 */
@optional
- (BOOL)menuNode:(HLMenuNode *)menuNode shouldTapMenuItem:(HLMenuItem *)menuItem itemIndex:(NSUInteger)itemIndex;

/**
 Called when the user has tapped on a menu item and the menu node has taken any
 navigation actions that would normally result from the tap.
 */
@required
- (void)menuNode:(HLMenuNode *)menuNode didTapMenuItem:(HLMenuItem *)menuItem itemIndex:(NSUInteger)itemIndex;

/**
 Called when the user has long-pressed on a menu item.
 */
@optional
- (void)menuNode:(HLMenuNode *)menuNode didLongPressMenuItem:(HLMenuItem *)menuItem itemIndex:(NSUInteger)itemIndex;

@end

/**
 An HLMenuItem is a single item in an HLMenu.
 */
@interface HLMenuItem : NSObject <NSCoding>

/// @name Creating a Menu Item

/**
 Returns an initialized menu item.
 */
+ (HLMenuItem *)menuItemWithText:(NSString *)text;

/**
 Initializes a new menu item.
 */
- (instancetype)initWithText:(NSString *)text NS_DESIGNATED_INITIALIZER;

// TODO: This is declared for the sake of the NS_DESIGNATED_INITIALIZER; I expected
// a superclass to do this for me.  Give it some time and then try to remove this
// declaration.
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;

/// @name Configuring Appearance

/**
 The menu item's text.

 The menu node will display this text in the button it creates for the menu item;
 additionally, this is the text used to identify the button in its menu, and so should be
 unique among other items in its parent menu if it needs to be identified uniquely.
 */
@property (nonatomic, copy) NSString *text;

/**
 The prototype button used for the item in the menu node, if not `nil`.

 See notes in `[HLMenuNode itemButtonPrototype]`.
 */
@property (nonatomic, strong) HLLabelButtonNode *buttonPrototype;

/**
 The sound file that will be played when this button is tapped, if not `nil`.

 See notes in `[HLMenuNode itemSoundFile]`.
 */
@property (nonatomic, copy) NSString *soundFile;

/// @name Querying the Menu Hierarchy

/**
 The `HLMenu` that added this item (see `[HLMenu addItem:]`).

 @warning Do not set this property directly. It is maintained as a two-way relationship
          by the parent `HLMenu`.
 */
@property (nonatomic, weak) HLMenu *parent;

/**
 An array of strings specifying the location of this menu item in its menu hierarchy.

 Each array entry is the `text` of a corresponding `HLMenuItem`.

 By convention, the root menu of the hierarchy is excluded from the path; the first entry
 in the path refers to an item *added to* the root menu.  The last entry in the path is
 the `text` of this `HLMenuItem`.
 */
- (NSArray *)path;

@end

/**
 An `HLMenu` is a kind of menu item which itself can contain menu items.
 */
@interface HLMenu : HLMenuItem <NSCoding>

/// @name Creating a Menu

/**
 Convenience method for creating a new menu.

 See `initWithText:items:`.
 */
+ (HLMenu *)menuWithText:(NSString *)text items:(NSArray *)items;

/**
 Initializes a menu with an optional array of items.

 If there are no items, the super initializer `[HLMenuItem initWithText:]` is equivalent.
 */
- (instancetype)initWithText:(NSString *)text items:(NSArray *)items NS_DESIGNATED_INITIALIZER;

// TODO: This is declared for the sake of the NS_DESIGNATED_INITIALIZER; I expected
// a superclass to do this for me.  Give it some time and then try to remove this
// declaration.
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;

/// @name Manage Items in the Menu

/**
 Adds an item to the menu.

 @warning Do not try to change the menu hierarchy by setting an item's `parent`
          property. The relationship is two-way, and should be established by this method.
 */
- (void)addItem:(HLMenuItem *)item;

/**
 Returns the number of items added to the menu.
 */
- (NSUInteger)itemCount;

/**
 Returns the item in the menu that corresponds to the passed index.

 The index is zero-based.  Raises an `NSRangeException` if the index is out of bounds.
 */
- (HLMenuItem *)itemAtIndex:(NSUInteger)index;

/**
 Returns the item in the menu's hierarchy that corresponds to the passed path.

 Returns `nil` if no corresponding item is found.

 Each entry in the path is the `text` of a menu item.  By convention, the receiver menu
 should not be included in the path; the first entry in the path refers to an item *added*
 to this menu.
 */
- (HLMenuItem *)itemForPath:(NSArray *)path;

/**
 Removes all items from the menu.
 */
- (void)removeAllItems;

@end

/**
 An HLMenuBackItem is a kind of menu item which, when tapped, navigates the menu node to
 its parent menu.
 */
@interface HLMenuBackItem : HLMenuItem <NSCoding>

@end
