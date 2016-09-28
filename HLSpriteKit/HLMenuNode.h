//
//  HLMenuNode.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 5/1/14.
//  Copyright (c) 2014 Hilo Games. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import <TargetConditionals.h>

#import "HLComponentNode.h"
#import "HLGestureTarget.h"

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
 `HLMenuNode` has an `HLMenu`, and it creates and displays buttons for each
 item in the `HLMenu`, stacked vertically.  Menus are hierarchical in nature, and the
 node provides functionality for navigating between menus and submenus.

 ## Common User Interaction Configurations

 As a gesture target:

 - Set this node as its own gesture target (via `[SKNode+HLGestureTarget
   hlSetGestureTarget]`) to get a callbacks via the `HLMenuNodeDelegate` interface.

 As a `UIResponder`:

 - Set this node's `userInteractionEnabled` property to true to get callbacks via the
  `HLMenuNodeDelegate` interface.

 As an `NSResponder`:

 - Set this node's `userInteractionEnabled` property to true to get callbacks via the
  `HLMenuNodeDelegate` interface.
*/
#if HLGESTURETARGET_AVAILABLE
@interface HLMenuNode : HLComponentNode <NSCoding, HLGestureTarget>
#else
@interface HLMenuNode : HLComponentNode <NSCoding>
#endif

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
 The hierarchical menu navigated by the menu node (readonly).

 For the sake of simplicity, menu node does not worry about updating its display when
 the caller makes changes to the individual menu items.  Instead, it will only refresh
 the display after a call to `setTopMenu:animation:`, `redisplayMenuAnimation:`, or from
 manual or programmatic navigation of the menu.  The readonly attribute helps to suggest
 this pattern.  (The menu is retained, though, not copied, and so the caller is still
 able to change submenus and items within the menu.  Again, though, those changes will
 not be displayed until the HLMenuNode is explicitly redisplayed or navigated.)

 @bug It is considered convenient for the menu node to keep a strong reference to its
      menu, assuming that the caller typically wants a single fairly-static menu
      hierarchy.  An alternate design, perhaps where only "current" menu is tracked,
      and submenus or parent menus are returned dynamically from delegate calls, should
      be considered if useful.
*/
@property (nonatomic, readonly) HLMenu *topMenu;

/**
 The submenu (of the `menu`) currently displayed by the menu node (readonly).

 See notes at `menu`: changes to the currently displayed menu will not result in changes
 to the display; the readonly attribute helps to suggest this.
*/
@property (nonatomic, readonly) HLMenu *displayedMenu;

/**
 Sets the hierarchical menu that the menu node will navigate.
*/
- (void)setTopMenu:(HLMenu *)topMenu animation:(HLMenuNodeAnimation)animation;

/**
 Recreate display of current menu.

 The HLMenuNode tracks a current HLMenu, but changes to that menu are not reflected in the
 display until an explicit call to `setTopMenu`, a navigation method, or a call to this method.
*/
- (void)redisplayMenuAnimation:(HLMenuNodeAnimation)animation;

/// @name Managing Geometry

/**
 The vertical distance between the edges of adjacent buttons in the menu node.

 Changes to this property won't take effect on the currently displayed menu until it
 is explicitly redisplayed (for example by navigation or `redisplayMenuAnimation:`).
*/
@property (nonatomic, assign) CGFloat itemSeparatorSize;

/**
 The size of the bounds of the currently displayed menu.

 Derived from the button geometry, `itemSeperatorSize`, and the content of the current menu.
 Overall size cannot be set directly.
*/
@property (nonatomic, readonly) CGSize size;

/**
 The anchor point of the currently displayed menu.

 Changes to this property won't take effect on the currently displayed menu until it
 is explicitly redisplayed (for example by navigation or `redisplayMenuAnimation:`).

 Default value is `(0.5, 0.5)`.
*/
@property (nonatomic, assign) CGPoint anchorPoint;

/// @name Configuring Menu Item Buttons

/**
 Default prototype button for items in the menu.

 Buttons are typed using "duck typing": They must be descended from `SKNode` and must
 additionally respond to the following selectors: `(CGSize)size`, and `setAnchorPoint:(CGPoint)`.
 In addition, if it has a `setText:(NSString *)` selector, it will be automatically set
 with the corresponding `HLMenuItem` text.  A good class to use is `HLLabelButtonNode`.
 Selectors will be checked at runtime.

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

 Changes to this property won't take effect on the currently displayed menu until it
 is explicitly redisplayed (for example by navigation or `redisplayMenuAnimation:`).
*/
@property (nonatomic, strong) SKNode *itemButtonPrototype;

/**
 Default prototype button for submenu items in the menu.

 See `itemButtonPrototype` for notes about prototype buttons.

 Changes to this property won't take effect on the currently displayed menu until it
 is explicitly redisplayed (for example by navigation or `redisplayMenuAnimation:`).
*/
@property (nonatomic, strong) SKNode *menuItemButtonPrototype;

/**
 Default prototype button for back items in the menu.

 See `itemButtonPrototype` for notes about prototype buttons.

 Changes to this property won't take effect on the currently displayed menu until it
 is explicitly redisplayed (for example by navigation or `redisplayMenuAnimation:`).
*/
@property (nonatomic, strong) SKNode *backItemButtonPrototype;

/**
 The animation used for navigation between menus.

 This animation applies when navigation is triggered by taps or clicks on submenu and back
 buttons.
*/
@property (nonatomic, assign) HLMenuNodeAnimation itemAnimation;

/**
 The duration of the animation used for navigation between menus.

 This animation duration applies when navigation is triggered by taps or clicks on submenu
 and back buttons.
*/
@property (nonatomic, assign) NSTimeInterval itemAnimationDuration;

/**
 Default sound file for playing when an item is tapped or clicked, or `nil` for none.

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
*/
@protocol HLMenuNodeDelegate <NSObject>

/// @name Configuring Buttons for Menu Node

/**
 Called immediately after a button is created for a menu item, but before the button is
 added to the node hierarchy and displayed.

 This callback is optional, but provides an opportunity for the delegate to customize
 the appearance of a button right before display.
*/
@optional
- (void)menuNode:(HLMenuNode *)menuNode willDisplayButton:(SKNode *)buttonNode forMenuItem:(HLMenuItem *)menuItem itemIndex:(NSUInteger)itemIndex;

/// @name Handling User Interaction

#if TARGET_OS_IPHONE

/**
 Called when the user taps on a menu item, but before the menu node has taken any
 navigation actions that would normally result from the tap.

 A return value of `YES` indicates the menu node should continue to navigation.

 The sound file associated with the item will play **before** this delegate method is
 called.

 Relevant to `HLGestureTarget` and `UIResponder` user interaction.
 See "Common User Interaction Configurations".
*/
@optional
- (BOOL)menuNode:(HLMenuNode *)menuNode shouldTapMenuItem:(HLMenuItem *)menuItem itemIndex:(NSUInteger)itemIndex;

/**
 Called when the user has tapped on a menu item and the menu node has taken any
 navigation actions that would normally result from the tap.

 Relevant to `HLGestureTarget` and `UIResponder` user interaction.
 See "Common User Interaction Configurations".
*/
@required
- (void)menuNode:(HLMenuNode *)menuNode didTapMenuItem:(HLMenuItem *)menuItem itemIndex:(NSUInteger)itemIndex;

/**
 Called when the user has long-pressed on a menu item.

 Relevant to `HLGestureTarget` and `UIResponder` user interaction.
 See "Common User Interaction Configurations".
*/
@optional
- (void)menuNode:(HLMenuNode *)menuNode didLongPressMenuItem:(HLMenuItem *)menuItem itemIndex:(NSUInteger)itemIndex;

#else

/**
 Called when the user clicks on a menu item, but before the menu node has taken any
 navigation actions that would normally result from the click.

 A return value of `YES` indicates the menu node should continue to navigation.

 The sound file associated with the item will play **before** this delegate method is
 called.

 Relevant to `NSResponder` user interaction.
 See "Common User Interaction Configurations".
*/
@optional
- (BOOL)menuNode:(HLMenuNode *)menuNode shouldClickMenuItem:(HLMenuItem *)menuItem itemIndex:(NSUInteger)itemIndex;

/**
 Called when the user has clicked on a menu item and the menu node has taken any
 navigation actions that would normally result from the click.

 Relevant to `NSResponder` user interaction.
 See "Common User Interaction Configurations".
*/
@required
- (void)menuNode:(HLMenuNode *)menuNode didClickMenuItem:(HLMenuItem *)menuItem itemIndex:(NSUInteger)itemIndex;

/**
 Called when the user has long-clicked on a menu item.

 Relevant to `NSResponder` user interaction.
 See "Common User Interaction Configurations".
 */
@optional
- (void)menuNode:(HLMenuNode *)menuNode didLongClickMenuItem:(HLMenuItem *)menuItem itemIndex:(NSUInteger)itemIndex;

#endif

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
- (instancetype)initWithText:(NSString *)text;

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
@property (nonatomic, strong) SKNode *buttonPrototype;

/**
 The sound file that will be played when this button is tapped or clicked, if not `nil`.

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
 An HLMenuBackItem is a kind of menu item which, when tapped or clicked, navigates the
 menu node to its parent menu.
*/
@interface HLMenuBackItem : HLMenuItem <NSCoding>

@end
